package ids.codecraft.app

import android.util.Log
import java.io.InputStream
import java.io.OutputStream
import java.net.InetSocketAddress
import java.net.Socket
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

/**
 * 一条被接管的应用 TCP 连接。
 *
 * 做法是「本地终止 + 重新发起」：在 tun 上和应用完成三次握手、自己维护双向序列号，
 * 同时另开一个到本地代理的 Socket 承载真实数据。这样应用看到的是一个正常 TCP 连接，
 * 而代理只看到一条普通的 HTTP/HTTPS 连接。
 *
 * 序列号必须严格跟踪：应用会按自己的预期校验，回包的 seq/ack 一旦错位，
 * 系统 TCP 栈会静默丢弃，表现为「连上了但收不到数据」。
 */
class VpnTcpSession(
    private val service: ProxyVpnService,
    private val tun: OutputStream,
    srcIp: Int,
    srcPort: Int,
    dstIp: Int,
    dstPort: Int,
    private val clientHelloSeq: Int,
) {
    private val tag = "VpnTcpSession"

    private val clientIp = srcIp
    private val clientPort = srcPort
    private val targetIp = dstIp
    private val targetPort = dstPort

    /** 我们作为「服务端」发出去的下一个序列号。 */
    private val sendSeq = AtomicInteger(INITIAL_SERVER_SEQ)

    /** 我们期望从应用收到的下一个序列号。 */
    private val recvSeq = AtomicInteger(clientHelloSeq + 1)

    private val closed = AtomicBoolean(false)

    private var socket: Socket? = null
    private var output: OutputStream? = null

    /** 是否已经判定这条流该交给本地代理处理（HTTP 或 TLS）。 */
    private var routed = false

    /** 收到的首个业务数据还没判定完时先留着，判定后原样发给上游。 */
    private var pendingFirstChunk: ByteArray? = null
    private var handshakeDone = false

    private var lastActive = System.currentTimeMillis()

    fun isStale(now: Long) = now - lastActive > IDLE_TIMEOUT_MS

    fun touch() {
        lastActive = System.currentTimeMillis()
    }

    /** 处理 SYN：先回 SYN-ACK，上游等首包再决定连到哪。 */
    fun onSyn() {
        sendPacket(VpnPackets.ACK or VpnPackets.SYN, ByteArray(0))
        handshakeDone = true
    }

    /** 应用回 ACK 且带数据（或首包直接带数据）时调用。 */
    fun onClientPayload(payload: ByteArray, length: Int) {
        if (closed.get()) return
        touch()
        // 序列号推进：应用发来的数据按长度递增（忽略重传去重，抓包场景足够）。
        recvSeq.set(recvSeq.get() + length)

        if (!routed) {
            pendingFirstChunk = payload.copyOf(length)
            // 回 ACK，避免应用等确认而停发。
            sendPacket(VpnPackets.ACK, ByteArray(0), ackDelta = length)
            routeUpstream(payload, length)
            return
        }

        try {
            output?.write(payload, 0, length)
            output?.flush()
        } catch (e: Exception) {
            Log.w(tag, "写上游失败: ${e.message}")
            close()
            return
        }
        sendPacket(VpnPackets.ACK, ByteArray(0), ackDelta = 0)
    }

    private fun routeUpstream(payload: ByteArray, length: Int) {
        val host = VpnPackets.ipToString(targetIp)
        try {
            val s = Socket()
            s.tcpNoDelay = true
            s.connect(InetSocketAddress("127.0.0.1", service.proxyPort), CONNECT_TIMEOUT_MS)
            socket = s
            output = s.getOutputStream()
            routed = true

            if (VpnPackets.looksLikeHttpRequest(payload, length)) {
                // 明文 HTTP：代理要 absolute-form 请求行。
                val hostHeader = VpnPackets.hostHeaderOf(payload, length)
                val rewritten = VpnPackets.rewriteToProxyForm(
                    payload = payload,
                    length = length,
                    hostHeader = hostHeader,
                    host = host,
                    port = targetPort,
                )
                output?.write(rewritten)
                output?.flush()
            } else {
                // TLS 或其他：交给代理按 CONNECT + 透传处理。
                val connect = "CONNECT $host:$targetPort HTTP/1.1\r\n" +
                    "Host: $host:$targetPort\r\n\r\n"
                output?.write(connect.toByteArray(Charsets.US_ASCII))
                output?.flush()
                // 透传首包（TLS ClientHello 等）。
                output?.write(payload, 0, length)
                output?.flush()
            }
            pendingFirstChunk = null

            // 起读取线程，把上游数据封包回应用。
            Thread({ pumpUpstream(s.inputStream) }, "vpn-up-$clientPort").start()
        } catch (e: Exception) {
            Log.w(tag, "连接代理失败: ${e.message}")
            // 回 RST 让应用立刻失败重试，而不是一直等待。
            interrupt()
        }
    }

    private fun pumpUpstream(input: InputStream) {
        val buffer = ByteArray(MAX_CHUNK)
        try {
            while (!closed.get()) {
                val n = input.read(buffer)
                if (n <= 0) break
                sendPacket(VpnPackets.ACK or VpnPackets.PSH, buffer.copyOf(n))
            }
        } catch (e: Exception) {
            Log.d(tag, "上游读取结束: ${e.message}")
        }
        if (!closed.get()) sendFin()
    }

    /** 发出 FIN 并关闭。 */
    private fun sendFin() {
        sendPacket(VpnPackets.ACK or VpnPackets.FIN, ByteArray(0))
        close()
    }

    /** 回 RST，让应用立即断开。 */
    fun interrupt() {
        if (closed.getAndSet(true)) return
        sendPacket(VpnPackets.RST or VpnPackets.ACK, ByteArray(0))
        releaseSocket()
    }

    fun close() {
        if (closed.getAndSet(true)) return
        releaseSocket()
    }

    private fun releaseSocket() {
        try {
            socket?.close()
        } catch (_: Exception) {
        }
        socket = null
        output = null
    }

    /**
     * 构造并写出一个回给应用的包。
     *
     * @param ackDelta 相对当前 recvSeq 的额外确认量（用于「刚收到这么多字节」的即时确认）。
     */
    private fun sendPacket(flags: Int, payload: ByteArray, ackDelta: Int = 0) {
        if (!handshakeDone && flags and VpnPackets.SYN == 0) return
        val seq = sendSeq.get()
        val packet = VpnPackets.buildTcp(
            srcIp = targetIp,
            srcPort = targetPort,
            dstIp = clientIp,
            dstPort = clientPort,
            seq = seq,
            ack = recvSeq.get() + ackDelta,
            flags = flags,
            payload = payload,
        )
        try {
            // 同一条 tun 被多线程写：必须串行化，否则包会互相截断。
            service.writeToTun(packet)
        } catch (e: Exception) {
            Log.w(tag, "写 tun 失败: ${e.message}")
            return
        }
        // SYN 与 FIN 各占一个序列号，数据按长度推进。
        var advance = payload.size
        if (flags and VpnPackets.SYN != 0) advance += 1
        if (flags and VpnPackets.FIN != 0) advance += 1
        sendSeq.set(seq + advance)
    }

    private companion object {
        const val INITIAL_SERVER_SEQ = 0x100000
        const val MAX_CHUNK = 8192
        const val CONNECT_TIMEOUT_MS = 8000
        const val IDLE_TIMEOUT_MS = 5 * 60 * 1000L
    }
}
