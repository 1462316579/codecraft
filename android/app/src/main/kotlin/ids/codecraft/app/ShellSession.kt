package ids.codecraft.app

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import java.io.InputStream
import java.io.OutputStream
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger

/** 一条普通进程 shell 会话(无 PTY)，通过 ProcessBuilder 启动 /system/bin/sh -i。 */
class ShellSession(
    val id: Int,
    private val process: java.lang.Process,
    private var events: EventChannel.EventSink?,
) : Runnable {
    private val input: InputStream = process.inputStream
    private val output: OutputStream = process.outputStream
    private var closed = false
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun run() {
        val buffer = ByteArray(8192)
        try {
            while (!closed) {
                val read = input.read(buffer)
                if (read <= 0) break
                val chunk = buffer.copyOf(read)
                mainHandler.post {
                    if (!closed && events != null) events!!.success(mapOf("id" to id, "data" to chunk))
                }
            }
        } catch (_: Exception) {
            // 关闭时会打断 read,忽略。
        } finally {
            val code = process.waitFor()
            mainHandler.post {
                if (!closed && events != null) events!!.success(mapOf("id" to id, "exit" to code))
            }
            close()
        }
    }

    fun write(bytes: ByteArray) {
        if (closed) return
        try {
            output.write(bytes)
            output.flush()
        } catch (_: Exception) {
        }
    }

    fun close() {
        if (closed) return
        closed = true
        process.destroy()
        try { input.close() } catch (_: Exception) {}
        try { output.close() } catch (_: Exception) {}
        shellSessions.remove(id)
    }

    fun setEvents(sink: EventChannel.EventSink) {
        this.events = sink
    }

    companion object {
        private val seq = java.util.concurrent.atomic.AtomicInteger(0)
        private val shellSessions = ConcurrentHashMap<Int, ShellSession>()

        fun open(
            argv: Array<String>,
            envp: Array<String>,
            cwd: String?,
            events: EventChannel.EventSink?,
        ): Int? {
            val pb = java.lang.ProcessBuilder(*argv)
            if (cwd != null) {
                val dir = java.io.File(cwd)
                if (dir.exists() && dir.isDirectory) pb.directory(dir)
            }
            // envp entries are "KEY=VALUE" strings; replace default env to match ZeroTermux behavior
            val env = pb.environment()
            env.clear()
            for (entry in envp) {
                val idx = entry.indexOf('=')
                if (idx > 0) {
                    env[entry.substring(0, idx)] = entry.substring(idx + 1)
                }
            }
            pb.redirectErrorStream(true)
            try {
                val process = pb.start()
                val id = seq.incrementAndGet()
                val session = ShellSession(id, process, events)
                shellSessions[id] = session
                Thread(session, "codecraft-shell-$id").apply { isDaemon = true }.start()
                return id
            } catch (_: Exception) {
                return null
            }
        }

        fun setEventsForAll(sink: EventChannel.EventSink) {
            shellSessions.values.forEach { it.events = sink }
        }

        fun write(id: Int, bytes: ByteArray) = shellSessions[id]?.write(bytes)

        fun close(id: Int) = shellSessions[id]?.close()

        fun closeAll() = shellSessions.values.toList().forEach { it.close() }
    }
}
