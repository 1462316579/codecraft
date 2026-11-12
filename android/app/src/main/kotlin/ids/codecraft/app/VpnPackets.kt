package ids.codecraft.app

import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * tun 设备读写的原始 IP 包工具：解析 IPv4/TCP/UDP 头、构造回包、算校验和。
 *
 * 这里的实现必须严格遵守 RFC 791/793：客户端 TCP 栈会校验序列号与校验和，
 * 任何一项算错都会被当作无效包丢弃，表现就是「VPN 起来了但一个请求都抓不到」。
 */
object VpnPackets {
    const val PROTO_TCP = 6
    const val PROTO_UDP = 17

    const val FIN = 0x01
    const val SYN = 0x02
    const val RST = 0x04
    const val PSH = 0x08
    const val ACK = 0x10

    /** 解析出的 IPv4 + TCP 视图（只读，指向原始 buffer 的偏移量）。 */
    class TcpView(
        val srcIp: Int,
        val dstIp: Int,
        val srcPort: Int,
        val dstPort: Int,
        val seq: Int,
        val ack: Int,
        val flags: Int,
        val headerLen: Int,
        val payloadOffset: Int,
        val payloadLength: Int,
    ) {
        val isSyn get() = flags and SYN != 0
        val isAck get() = flags and ACK != 0
        val isFin get() = flags and FIN != 0
        val isRst get() = flags and RST != 0
    }

    class UdpView(
        val srcIp: Int,
        val dstIp: Int,
        val srcPort: Int,
        val dstPort: Int,
        val payloadOffset: Int,
        val payloadLength: Int,
    )

    /** 解析 IPv4 头，返回 (协议号, 头长, 总长)；不是合法 IPv4 时返回 null。 */
    fun ipInfo(buf: ByteArray, length: Int): Triple<Int, Int, Int>? {
        if (length < 20) return null
        val versionIhl = buf[0].toInt() and 0xFF
        if (versionIhl shr 4 != 4) return null
        val ihl = (versionIhl and 0x0F) * 4
        if (length < ihl) return null
        val totalLen = ((buf[2].toInt() and 0xFF) shl 8) or (buf[3].toInt() and 0xFF)
        val protocol = buf[9].toInt() and 0xFF
        return Triple(protocol, ihl, if (totalLen in 20..length) totalLen else length)
    }

    fun parseTcp(buf: ByteArray, ihl: Int, totalLen: Int): TcpView? {
        if (totalLen < ihl + 20) return null
        val b = ByteBuffer.wrap(buf).order(ByteOrder.BIG_ENDIAN)
        val srcIp = b.getInt(12)
        val dstIp = b.getInt(16)
        val srcPort = b.getShort(ihl).toInt() and 0xFFFF
        val dstPort = b.getShort(ihl + 2).toInt() and 0xFFFF
        val seq = b.getInt(ihl + 4)
        val ack = b.getInt(ihl + 8)
        val dataOffsetFlags = b.getShort(ihl + 12).toInt() and 0xFFFF
        val tcpHeaderLen = (dataOffsetFlags shr 12) * 4
        if (tcpHeaderLen < 20 || totalLen < ihl + tcpHeaderLen) return null
        return TcpView(
            srcIp = srcIp,
            dstIp = dstIp,
            srcPort = srcPort,
            dstPort = dstPort,
            seq = seq,
            ack = ack,
            flags = dataOffsetFlags and 0xFF,
            headerLen = tcpHeaderLen,
            payloadOffset = ihl + tcpHeaderLen,
            payloadLength = totalLen - ihl - tcpHeaderLen,
        )
    }

    fun parseUdp(buf: ByteArray, ihl: Int, totalLen: Int): UdpView? {
        if (totalLen < ihl + 8) return null
        val b = ByteBuffer.wrap(buf).order(ByteOrder.BIG_ENDIAN)
        val srcIp = b.getInt(12)
        val dstIp = b.getInt(16)
        val srcPort = b.getShort(ihl).toInt() and 0xFFFF
        val dstPort = b.getShort(ihl + 2).toInt() and 0xFFFF
        val udpLen = b.getShort(ihl + 4).toInt() and 0xFFFF
        val end = minOf(totalLen, ihl + udpLen)
        return UdpView(
            srcIp = srcIp,
            dstIp = dstIp,
            srcPort = srcPort,
            dstPort = dstPort,
            payloadOffset = ihl + 8,
            payloadLength = (end - ihl - 8).coerceAtLeast(0),
        )
    }

    fun buildTcp(
        srcIp: Int,
        srcPort: Int,
        dstIp: Int,
        dstPort: Int,
        seq: Int,
        ack: Int,
        flags: Int,
        payload: ByteArray,
        payloadLength: Int = payload.size,
    ): ByteArray {
        val ipHeaderLen = 20
        val tcpHeaderLen = 20
        val totalLen = ipHeaderLen + tcpHeaderLen + payloadLength
        val out = ByteArray(totalLen)
        val b = ByteBuffer.wrap(out).order(ByteOrder.BIG_ENDIAN)

        // IPv4 头
        b.put(0, (0x45).toByte())
        b.putShort(2, totalLen.toShort())
        b.putShort(4, 0)
        b.putShort(6, 0x4000) // DF
        b.put(8, 64)
        b.put(9, PROTO_TCP.toByte())
        b.putShort(10, 0)
        b.putInt(12, srcIp)
        b.putInt(16, dstIp)
        b.putShort(10, checksum(out, 0, ipHeaderLen).toShort())

        // TCP 头
        b.putShort(20, srcPort.toShort())
        b.putShort(22, dstPort.toShort())
        b.putInt(24, seq)
        b.putInt(28, ack)
        b.putShort(32, ((tcpHeaderLen / 4) shl 12 or flags).toShort())
        b.putShort(34, 65535.toShort()) // window
        b.putShort(36, 0)
        b.putShort(38, 0)
        if (payloadLength > 0) {
            System.arraycopy(payload, 0, out, ipHeaderLen + tcpHeaderLen, payloadLength)
        }
        // TCP 校验和：伪头 + TCP 头 + 负载
        val pseudoLen = 12 + tcpHeaderLen + payloadLength
        val pseudo = ByteArray(pseudoLen)
        val p = ByteBuffer.wrap(pseudo).order(ByteOrder.BIG_ENDIAN)
        p.putInt(0, srcIp)
        p.putInt(4, dstIp)
        p.put(8, 0)
        p.put(9, PROTO_TCP.toByte())
        p.putShort(10, (tcpHeaderLen + payloadLength).toShort())
        System.arraycopy(out, ipHeaderLen, pseudo, 12, tcpHeaderLen + payloadLength)
        b.putShort(36, checksum(pseudo, 0, pseudoLen).toShort())
        return out
    }

    fun buildUdp(
        srcIp: Int,
        srcPort: Int,
        dstIp: Int,
        dstPort: Int,
        payload: ByteArray,
        payloadLength: Int = payload.size,
    ): ByteArray {
        val ipHeaderLen = 20
        val udpHeaderLen = 8
        val totalLen = ipHeaderLen + udpHeaderLen + payloadLength
        val out = ByteArray(totalLen)
        val b = ByteBuffer.wrap(out).order(ByteOrder.BIG_ENDIAN)

        b.put(0, (0x45).toByte())
        b.putShort(2, totalLen.toShort())
        b.putShort(4, 0)
        b.putShort(6, 0)
        b.put(8, 64)
        b.put(9, PROTO_UDP.toByte())
        b.putShort(10, 0)
        b.putInt(12, srcIp)
        b.putInt(16, dstIp)
        b.putShort(10, checksum(out, 0, ipHeaderLen).toShort())

        b.putShort(20, srcPort.toShort())
        b.putShort(22, dstPort.toShort())
        b.putShort(24, (udpHeaderLen + payloadLength).toShort())
        b.putShort(26, 0)
        if (payloadLength > 0) {
            System.arraycopy(payload, 0, out, ipHeaderLen + udpHeaderLen, payloadLength)
        }
        // UDP 校验和可选；填 0 表示不校验，避免算错反而被丢弃。
        return out
    }

    /** 标准 Internet 校验和（RFC 1071）。 */
    private fun checksum(data: ByteArray, offset: Int, len: Int): Int {
        var sum = 0L
        var i = offset
        val end = offset + len
        while (i + 1 < end) {
            sum += ((data[i].toInt() and 0xFF) shl 8) or (data[i + 1].toInt() and 0xFF)
            i += 2
        }
        if (i < end) sum += (data[i].toInt() and 0xFF) shl 8
        while (sum shr 16 != 0L) sum = (sum and 0xFFFF) + (sum shr 16)
        return (sum.inv() and 0xFFFF).toInt()
    }

    fun ipToString(ip: Int): String =
        "${(ip shr 24) and 0xFF}.${(ip shr 16) and 0xFF}.${(ip shr 8) and 0xFF}.${ip and 0xFF}"

    /**
     * 从 TLS ClientHello 里取 SNI。
     *
     * 全流量接管后 HTTPS 表现为裸 TLS 字节流（没有 CONNECT 行），
     * 必须靠 SNI 才知道该为哪个域名签发证书。
     */
    fun sniFromClientHello(payload: ByteArray, length: Int): String? {
        try {
            if (length < 5 + 4 + 2 + 32) return null
            if (payload[0].toInt() and 0xFF != 0x16) return null // handshake
            if (payload[5].toInt() and 0xFF != 0x01) return null // client hello
            // 跳过：record(5) + handshake 头(4) + version(2) + random(32)
            var pos = 5 + 4 + 2 + 32
            if (pos >= length) return null
            val sessionIdLen = payload[pos].toInt() and 0xFF
            pos += 1 + sessionIdLen
            if (pos + 2 > length) return null
            val cipherLen = ((payload[pos].toInt() and 0xFF) shl 8) or (payload[pos + 1].toInt() and 0xFF)
            pos += 2 + cipherLen
            if (pos + 1 > length) return null
            val compLen = payload[pos].toInt() and 0xFF
            pos += 1 + compLen
            if (pos + 2 > length) return null
            val extTotalLen = ((payload[pos].toInt() and 0xFF) shl 8) or (payload[pos + 1].toInt() and 0xFF)
            pos += 2
            val extEnd = minOf(length, pos + extTotalLen)

            while (pos + 4 <= extEnd) {
                val type = ((payload[pos].toInt() and 0xFF) shl 8) or (payload[pos + 1].toInt() and 0xFF)
                val extLen = ((payload[pos + 2].toInt() and 0xFF) shl 8) or (payload[pos + 3].toInt() and 0xFF)
                pos += 4
                if (type == 0x0000) { // server_name
                    if (pos + 5 > extEnd) return null
                    val listLen = ((payload[pos].toInt() and 0xFF) shl 8) or (payload[pos + 1].toInt() and 0xFF)
                    var p = pos + 2
                    val listEnd = minOf(extEnd, p + listLen)
                    while (p + 3 <= listEnd) {
                        val nameType = payload[p].toInt() and 0xFF
                        val nameLen = ((payload[p + 1].toInt() and 0xFF) shl 8) or (payload[p + 2].toInt() and 0xFF)
                        p += 3
                        if (nameType == 0 && p + nameLen <= listEnd) {
                            return String(payload, p, nameLen, Charsets.US_ASCII)
                        }
                        p += nameLen
                    }
                    return null
                }
                pos += extLen
            }
        } catch (_: Exception) {
        }
        return null
    }

    private val HTTP_METHODS = listOf(
        "GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS", "TRACE", "CONNECT",
    )

    /** 首包是否像明文 HTTP 请求（大写方法名 + 空格）。 */
    fun looksLikeHttpRequest(payload: ByteArray, length: Int): Boolean {
        if (length < 4) return false
        for (method in HTTP_METHODS) {
            if (length < method.length + 1) continue
            var match = true
            for (i in method.indices) {
                val c = payload[i].toInt().toChar()
                if (c.uppercaseChar() != method[i]) {
                    match = false
                    break
                }
            }
            if (match && payload[method.length].toInt().toChar() == ' ') return true
        }
        return false
    }

    /**
     * 把 origin-form 请求行改写成 absolute-form。
     *
     * 客户端发的是 `GET /path HTTP/1.1`，而代理需要 `GET http://host/path HTTP/1.1`，
     * 否则代理无法知道目标主机。
     */
    fun rewriteToProxyForm(
        payload: ByteArray,
        length: Int,
        hostHeader: String?,
        host: String,
        port: Int,
    ): ByteArray {
        val text = String(payload, 0, length, Charsets.ISO_8859_1)
        val lineEnd = text.indexOf("\r\n")
        if (lineEnd <= 0) return payload.copyOf(length)
        val firstLine = text.substring(0, lineEnd)
        val parts = firstLine.split(' ')
        if (parts.size < 3) return payload.copyOf(length)
        val method = parts[0]
        val target = parts[1]
        val version = parts[2]
        if (target.startsWith("http://") || target.startsWith("https://")) {
            return payload.copyOf(length)
        }
        val hostPort = hostHeader ?: if (port == 80) host else "$host:$port"
        val rewritten = "$method http://$hostPort$target $version" + text.substring(lineEnd)
        return rewritten.toByteArray(Charsets.ISO_8859_1)
    }

    /** 从请求头里取 Host 值。 */
    fun hostHeaderOf(payload: ByteArray, length: Int): String? {
        val text = String(payload, 0, length, Charsets.ISO_8859_1)
        for (line in text.split("\r\n")) {
            if (line.length > 5 && line.substring(0, 5).equals("host:", ignoreCase = true)) {
                return line.substring(5).trim()
            }
        }
        return null
    }
}
