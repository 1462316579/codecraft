package ids.codecraft.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket
import java.util.concurrent.ConcurrentHashMap

/**
 * 全流量抓包 VPN。
 *
 * 与「系统代理」模式的区别：这里在 tun 上接管 `0.0.0.0/0`，所有 App 的连接都会进来，
 * 不依赖目标应用是否理会系统代理设置——视频类、游戏类那些直连 CDN 的流量同样能抓到。
 *
 * 分工：
 * - TCP：交给 [VpnTcpSession] 在本地终止，再转发到 127.0.0.1:proxyPort 的 Dart 代理；
 * - UDP：DNS 等直接透传（用 protect 让回包绕过 tun），不参与 MITM。
 */
class ProxyVpnService : VpnService() {

    companion object {
        const val ACTION_START = "ids.codecraft.app.action.START_VPN"
        const val ACTION_STOP = "ids.codecraft.app.action.STOP_VPN"
        const val EXTRA_PROXY_PORT = "extra_proxy_port"

        private const val VPN_ADDRESS = "10.0.0.2"
        private const val VPN_PREFIX_LENGTH = 32
        private const val MTU = 1500
        private const val NOTIFICATION_ID = 0x5678
        private const val CHANNEL_ID = "capture_vpn_channel"
        private const val TAG = "ProxyVpnService"

        @Volatile
        var isRunning = false
            private set

        /** 启动失败原因（授权被回收、establish 失败等），供 Dart 侧提示用户。 */
        @Volatile
        var lastError: String? = null
            private set

        fun prepare(context: Context): Intent? = VpnService.prepare(context)

        fun start(context: Context, proxyPort: Int) {
            val i = Intent(context, ProxyVpnService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_PROXY_PORT, proxyPort)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(i)
            } else {
                context.startService(i)
            }
        }

        fun stop(context: Context) {
            val i = Intent(context, ProxyVpnService::class.java).apply { action = ACTION_STOP }
            try {
                context.startService(i)
            } catch (_: IllegalStateException) {
                isRunning = false
            }
        }
    }

    private var vpnInterface: ParcelFileDescriptor? = null
    private var tunInput: FileInputStream? = null
    private var tunOutput: FileOutputStream? = null

    /** tun 的写入口：多个会话线程会并发写，必须串行化。 */
    private val tunWriteLock = Any()

    private var running = false

    /** 127.0.0.1 的网络字节序整数：识别「发往本地代理的回包」。 */
    private val loopbackAsInt = 0x7F000001

    /** srcIp:srcPort -> dstIp:dstPort 的会话表。 */
    private val sessions = ConcurrentHashMap<String, VpnTcpSession>()

    @Volatile
    var proxyPort = 8888
        private set

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopVpn()
            // stopVpn 在未运行时直接返回，这里兜底把 Service 本身停掉，
            // 否则一次「停止」调用会把服务实例留在后台。
            stopSelf()
            return START_NOT_STICKY
        }
        proxyPort = intent?.getIntExtra(EXTRA_PROXY_PORT, 8888) ?: 8888
        startVpn()
        // 进程被杀后不能自动重启：此时 Dart 代理已不存在，重启只会把流量黑洞掉。
        return START_NOT_STICKY
    }

    private fun startVpn() {
        if (running) return
        lastError = null

        // 授权可能在上次请求后才生效，也可能被系统回收；以 prepare() 为准。
        if (prepare(this) != null) {
            Log.w(TAG, "VPN not authorized, skip start")
            lastError = "VPN 授权失效，请重新授权"
            isRunning = false
            return
        }

        val builder = Builder()
            .setMtu(MTU)
            .setSession("CodeCraft Capture VPN")
            .addAddress(VPN_ADDRESS, VPN_PREFIX_LENGTH)
            // 关键：接管全部 IPv4 流量，才能真正抓到所有 App。
            .addRoute("0.0.0.0", 0)
            .setBlocking(true)

        // 关键：把本应用排除在 VPN 之外。
        // 代理的上游连接（Dart 侧 Socket.connect）来自本进程，若不排除就会被自己的
        // tun 再抓一次，形成「代理连代理」的死循环，所有请求都卡住。
        try {
            builder.addDisallowedApplication(packageName)
        } catch (_: Exception) {
        }

        // DNS 必须用当前网络真能到达的服务器。
        // 旧配置固定 8.8.8.8/1.1.1.1：境内大部分网络不可达，VPN 一启动全设备解析失败，
        // 表现为「开始抓包后什么都抓不到」，还会把用户网络弄断。
        val dnsServers = upstreamDnsServers()
        dnsServers.forEach { builder.addDnsServer(it) }
        Log.i(TAG, "VPN DNS servers: $dnsServers")

        // Android 10+ 同时把系统代理指到本地代理：有些应用只认系统代理，
            // 这样能减少不必要的用户态转发开销。
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                builder.setHttpProxy(
                    android.net.ProxyInfo.buildDirectProxy("127.0.0.1", proxyPort),
                )
            } catch (_: Exception) {
            }
        }

        vpnInterface = try {
            builder.establish()
        } catch (e: Exception) {
            Log.e(TAG, "VPN establish failed: ${e.message}")
            lastError = "创建 VPN 接口失败: ${e.message}"
            null
        }
        if (vpnInterface == null) {
            Log.e(TAG, "VPN establish failed")
            if (lastError == null) lastError = "创建 VPN 接口失败"
            isRunning = false
            stopSelf()
            return
        }

        tunInput = FileInputStream(vpnInterface!!.fileDescriptor)
        tunOutput = FileOutputStream(vpnInterface!!.fileDescriptor)

        running = true
        isRunning = true
        try {
            startForegroundCompat()
        } catch (e: Exception) {
            // Android 14+ 前台服务类型不匹配会抛异常；不处理会直接崩掉整个进程。
            Log.e(TAG, "startForeground failed: ${e.message}")
            lastError = "前台服务启动失败: ${e.message}"
            running = false
            isRunning = false
            stopSelf()
            return
        }
        Log.i(TAG, "VPN started, proxyPort=$proxyPort")

        Thread({ runVpnLoop() }, "vpn-packet-loop").start()
        Thread({ reapLoop() }, "vpn-reaper").start()
    }

    /**
     * 取底层网络（非本 VPN）的 DNS；拿不到时退回国内可达的公共 DNS。
     * 这里返回的是 IPv4 地址（tun 只接管 IPv4）。
     */
    private fun upstreamDnsServers(): List<String> {
        val result = mutableListOf<String>()
        try {
            val cm = getSystemService(ConnectivityManager::class.java)
            val network = cm?.activeNetwork
            val capabilities = network?.let { cm.getNetworkCapabilities(it) }
            val isCurrentVpn =
                capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true
            if (network != null && !isCurrentVpn) {
                cm.getLinkProperties(network)?.dnsServers?.forEach { address ->
                    val ip = address.hostAddress ?: return@forEach
                    if (ip.contains(':')) return@forEach
                    result.add(ip)
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "read DNS servers failed: ${e.message}")
        }
        if (result.isEmpty()) {
            result.add("223.5.5.5")
            result.add("119.29.29.29")
        }
        return result.distinct().take(2)
    }

    /** startForeground 的三参重载是 API 29 才有的，低版本必须走两参版本。 */
    private fun startForegroundCompat() {
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun stopVpn() {
        if (!running) return
        running = false
        isRunning = false

        sessions.values.forEach { it.close() }
        sessions.clear()

        try {
            tunInput?.close()
        } catch (_: Exception) {
        }
        try {
            tunOutput?.close()
        } catch (_: Exception) {
        }
        tunInput = null
        tunOutput = null

        try {
            vpnInterface?.close()
        } catch (_: Exception) {
        }
        vpnInterface = null

        stopForeground(true)
        stopSelf()
        Log.i(TAG, "VPN stopped")
    }

    /** 写一个原始 IP 包到 tun（线程安全）。 */
    fun writeToTun(packet: ByteArray) {
        val out = tunOutput ?: return
        synchronized(tunWriteLock) {
            try {
                out.write(packet)
                out.flush()
            } catch (_: Exception) {
            }
        }
    }

    private fun runVpnLoop() {
        val input = tunInput ?: return
        val buffer = ByteArray(MTU * 2)
        while (running) {
            val length = try {
                input.read(buffer)
            } catch (e: Exception) {
                if (running) Log.w(TAG, "tun 读取结束: ${e.message}")
                break
            }
            if (length <= 0) continue
            try {
                handlePacket(buffer, length)
            } catch (e: Exception) {
                Log.w(TAG, "处理数据包失败: ${e.message}")
            }
        }
        if (running) stopVpn()
    }

    private fun handlePacket(buf: ByteArray, length: Int) {
        val info = VpnPackets.ipInfo(buf, length) ?: return
        val (protocol, ihl, totalLen) = info
        when (protocol) {
            VpnPackets.PROTO_TCP -> handleTcp(buf, ihl, totalLen)
            VpnPackets.PROTO_UDP -> handleUdp(buf, ihl, totalLen)
        }
    }

    private fun handleTcp(buf: ByteArray, ihl: Int, totalLen: Int) {
        val tcp = VpnPackets.parseTcp(buf, ihl, totalLen) ?: return
        val key = sessionKey(tcp.srcIp, tcp.srcPort, tcp.dstIp, tcp.dstPort)

        // 反向包（我们自己发出去的）不应该再回来；忽略以免自激。
        if (tcp.srcIp == loopbackAsInt && tcp.srcPort == proxyPort) return

        if (tcp.isSyn && !tcp.isAck) {
            if (sessions.containsKey(key)) return
            // 去重：同一 SYN 重传时复用已有会话，不要重复握手。
            val session = VpnTcpSession(
                service = this,
                tun = tunOutput ?: return,
                srcIp = tcp.srcIp,
                srcPort = tcp.srcPort,
                dstIp = tcp.dstIp,
                dstPort = tcp.dstPort,
                clientHelloSeq = tcp.seq,
            )
            sessions[key] = session
            session.onSyn()
            if (!firstSessionLogged) {
                firstSessionLogged = true
                Log.i(TAG, "first TCP session: ${VpnPackets.ipToString(tcp.dstIp)}:${tcp.dstPort}")
            }
            return
        }

        val session = sessions[key] ?: return
        if (tcp.isRst || tcp.isFin) {
            session.close()
            sessions.remove(key)
            return
        }
        if (tcp.payloadLength > 0) {
            val payload = buf.copyOfRange(tcp.payloadOffset, tcp.payloadOffset + tcp.payloadLength)
            session.onClientPayload(payload, tcp.payloadLength)
        }
    }

    @Volatile
    private var firstSessionLogged = false

    /**
     * UDP：只透传 DNS（53）。
     *
     * 不自己做 DNS 应答，因为解析失败会让所有 App 都连不上网；
     * 用 protect() 保护的上游 socket 转发出去再写回 tun。
     *
     * 其余 UDP（QUIC、游戏直连等）直接丢弃：一条连接一次性的 socket 无法承载
     * 后续数据包，透传反而是「半通」状态；丢掉能让支持 QUIC 的 App 立刻回退到
     * TCP，才能在抓包里看到它的请求。
     */
    private fun handleUdp(buf: ByteArray, ihl: Int, totalLen: Int) {
        if (totalLen < ihl + 8) return
        val srcIp = readInt(buf, 12)
        val dstIp = readInt(buf, 16)
        val srcPort = ((buf[ihl].toInt() and 0xFF) shl 8) or (buf[ihl + 1].toInt() and 0xFF)
        val dstPort = ((buf[ihl + 2].toInt() and 0xFF) shl 8) or (buf[ihl + 3].toInt() and 0xFF)
        if (dstPort != 53) return
        val udpLen = ((buf[ihl + 4].toInt() and 0xFF) shl 8) or (buf[ihl + 5].toInt() and 0xFF)
        val payloadOffset = ihl + 8
        val payloadLen = minOf(totalLen, ihl + udpLen) - payloadOffset
        if (payloadLen <= 0) return
        val payload = buf.copyOfRange(payloadOffset, payloadOffset + payloadLen)

        Thread({
            var socket: DatagramSocket? = null
            try {
                socket = DatagramSocket()
                // protect 让这个 socket 的流量绕过 tun，否则 DNS 会自己打转。
                protect(socket)
                socket.soTimeout = 5000
                val target = InetSocketAddress(InetAddress.getByAddress(intToBytes(dstIp)), dstPort)
                socket.send(DatagramPacket(payload, payload.size, target))

                val respBuf = ByteArray(4096)
                val resp = DatagramPacket(respBuf, respBuf.size)
                socket.receive(resp)
                val responsePayload = respBuf.copyOf(resp.length)
                val packet = VpnPackets.buildUdp(
                    srcIp = dstIp,
                    srcPort = dstPort,
                    dstIp = srcIp,
                    dstPort = srcPort,
                    payload = responsePayload,
                )
                writeToTun(packet)
            } catch (_: Exception) {
                // DNS 透传失败就静默放弃：不影响其他连接。
            } finally {
                try {
                    socket?.close()
                } catch (_: Exception) {
                }
            }
        }, "vpn-udp").start()
    }

    private fun reapLoop() {
        while (running) {
            try {
                Thread.sleep(30_000)
            } catch (_: InterruptedException) {
                break
            }
            val now = System.currentTimeMillis()
            val stale = sessions.entries.filter { it.value.isStale(now) }
            for (entry in stale) {
                entry.value.close()
                sessions.remove(entry.key)
            }
        }
    }

    private fun sessionKey(srcIp: Int, srcPort: Int, dstIp: Int, dstPort: Int) =
        "$srcIp:$srcPort-$dstIp:$dstPort"

    private fun readInt(buf: ByteArray, offset: Int): Int =
        ((buf[offset].toInt() and 0xFF) shl 24) or
            ((buf[offset + 1].toInt() and 0xFF) shl 16) or
            ((buf[offset + 2].toInt() and 0xFF) shl 8) or
            (buf[offset + 3].toInt() and 0xFF)

    private fun intToBytes(ip: Int) = byteArrayOf(
        ((ip shr 24) and 0xFF).toByte(),
        ((ip shr 16) and 0xFF).toByte(),
        ((ip shr 8) and 0xFF).toByte(),
        (ip and 0xFF).toByte(),
    )

    private fun buildNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("CodeCraft Capture")
            .setContentText("正在抓包… 点击打开应用")
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "VPN Capture",
                NotificationManager.IMPORTANCE_LOW,
            )
            channel.description = "CodeCraft 抓包 VPN 服务"
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    override fun onRevoke() {
        // 用户在其他地方撤销了 VPN 授权，或别的 VPN 抢占了接口：必须干净退出，
        // 否则会话表与 tun 句柄会残留。
        stopVpn()
        super.onRevoke()
    }

    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }
}
