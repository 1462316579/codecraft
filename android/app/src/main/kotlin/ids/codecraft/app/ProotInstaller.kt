package ids.codecraft.app

import android.content.Context
import android.util.Log
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile

/**
 * PRoot 运行环境安装器。
 *
 * 旧实现是把整份 Termux bootstrap（约 97MB）塞进 APK，再用 bash 直接起终端；
 * 由于 Termux 二进制把 RUNPATH 编译成了 com.termux 的绝对路径，换包名后必然秒退。
 * 现在改为「只带 PRoot 运行时」（proot + loader + 两个依赖库，约 320KB），
 * 终端在 PRoot 容器里跑 rootfs，不再依赖任何 Termux 用户空间。
 *
 * 安装流程：
 * 1. 把 assets/proot 拷到 filesDir/proot-staging-*；
 * 2. 改写 ELF 的 RUNPATH（bin → $ORIGIN/../lib，lib → $ORIGIN），
 *    让 proot 在这个包名下也能找到 libtalloc / libandroid-shmem；
 * 3. 给 bin/proot 与 libexec/proot 下的 loader 加可执行位；
 * 4. rename 成 filesDir/proot，写版本标记。
 *
 * 注意：proot 的 loader 路径是编译期硬编码的
 * /data/data/com.termux/files/usr/libexec/proot/loader，比本应用的路径短，
 * 无法就地改写，所以启动时必须通过 PROOT_LOADER / PROOT_LOADER_32 环境变量覆盖。
 */
object ProotInstaller {
    private const val TAG = "ProotInstaller"
    private const val VERSION = "2026.11.15-r1"
    private const val ASSET_DIR = "proot"
    private const val MARKER = ".installed"

    @Volatile
    var installing = false
        private set

    /** 当前安装阶段文案（供 Dart 侧展示）。 */
    @Volatile
    var stage: String = ""
        private set

    /** 最近一次失败原因；成功或未开始时为 null。 */
    @Volatile
    var lastError: String? = null
        private set

    private val lock = Any()

    /** 运行环境目录：filesDir/proot。 */
    fun runtimeDir(context: Context): File = File(context.filesDir, "proot")

    fun isInstalled(context: Context): Boolean {
        val dir = runtimeDir(context)
        val marker = File(dir, MARKER)
        if (!marker.exists() || marker.readText().trim() != VERSION) return false
        val proot = File(dir, "bin/proot")
        val loader = File(dir, "libexec/proot/loader")
        return proot.exists() && proot.canExecute() && loader.exists()
    }

    /** 状态快照（Dart 侧轮询/展示）。 */
    fun status(context: Context): Map<String, Any?> = mapOf(
        "installed" to isInstalled(context),
        "installing" to installing,
        "stage" to stage,
        "error" to lastError,
        "path" to runtimeDir(context).absolutePath,
    )

    /** 异步安装（已安装则立即回调 true）。 */
    fun ensureInstalledAsync(context: Context, onComplete: (Boolean) -> Unit) {
        Thread {
            if (isInstalled(context)) {
                stage = "完成"
                lastError = null
                onComplete(true)
                return@Thread
            }
            synchronized(lock) {
                if (installing) {
                    onComplete(false)
                    return@Thread
                }
                installing = true
            }
            lastError = null
            val ok = try {
                install(context)
            } catch (e: Exception) {
                Log.e(TAG, "PRoot 运行环境安装失败", e)
                lastError = "${e.javaClass.simpleName}: ${e.message ?: ""}"
                stage = "安装失败"
                false
            } finally {
                installing = false
            }
            if (ok) stage = "完成"
            onComplete(ok)
        }.start()
    }

    private fun install(context: Context): Boolean {
        val target = runtimeDir(context)
        val parent = target.parentFile ?: context.filesDir
        val staging = File(parent, "proot-staging-${System.currentTimeMillis()}")
        if (staging.exists()) deleteRecursive(staging)
        staging.mkdirs()

        try {
            stage = "拷贝 PRoot 运行环境"
            Log.i(TAG, "从 assets/$ASSET_DIR 拷贝到 $staging")
            copyAssets(context, ASSET_DIR, staging)

            stage = "适配动态库路径"
            patchElfRunpaths(staging)

            stage = "设置权限"
            setExecutable(staging, "bin/proot")
            setExecutable(staging, "libexec/proot/loader")
            setExecutable(staging, "libexec/proot/loader32")

            if (target.exists()) deleteRecursive(target)
            if (!staging.renameTo(target)) {
                throw RuntimeException("重命名 $staging 到 $target 失败")
            }
            File(target, "tmp").mkdirs()
            File(target, MARKER).writeText(VERSION)
            Log.i(TAG, "PRoot 运行环境安装完成: $target")
            return true
        } finally {
            if (staging.exists()) deleteRecursive(staging)
        }
    }

    /** 给容器 rootfs 里的文件补执行位（解压后调用，一次批量传入）。 */
    fun chmodExecutable(paths: List<String>): Int {
        var ok = 0
        for (path in paths) {
            try {
                if (File(path).setExecutable(true, false)) ok++
            } catch (e: Exception) {
                Log.w(TAG, "设置可执行位失败: $path", e)
            }
        }
        return ok
    }

    private fun setExecutable(root: File, relativePath: String) {
        val file = File(root, relativePath)
        if (file.exists() && file.setExecutable(true, false)) {
            Log.i(TAG, "已设置可执行位: $relativePath")
        } else {
            Log.w(TAG, "设置可执行位失败: $relativePath")
        }
    }

    /** 递归拷贝 assets 目录（空数组 = 空目录）。 */
    private fun copyAssets(context: Context, assetDir: String, destDir: File) {
        val assets = context.assets
        val stack = ArrayDeque<Pair<String, File>>()
        stack.add(assetDir to destDir)
        var copied = 0

        while (stack.isNotEmpty()) {
            val (assetPath, target) = stack.removeLast()
            val children = try {
                assets.list(assetPath) ?: emptyArray()
            } catch (_: Exception) {
                emptyArray()
            }
            if (children.isNotEmpty()) {
                target.mkdirs()
                for (child in children) {
                    stack.add("$assetPath/$child" to File(target, child))
                }
                continue
            }
            try {
                assets.open(assetPath).use { input ->
                    target.parentFile?.mkdirs()
                    FileOutputStream(target).use { output -> input.copyTo(output, 65536) }
                }
                copied++
            } catch (_: java.io.FileNotFoundException) {
                target.mkdirs()
            } catch (e: Exception) {
                Log.w(TAG, "拷贝失败: $assetPath", e)
            }
        }
        Log.i(TAG, "拷贝完成: $copied 个文件")
    }

    /**
     * 改写 PRoot 二进制的 RUNPATH。
     *
     * Termux 包把库路径编译成 /data/data/com.termux/files/usr/lib（46 字节），
     * 换成相对 $ORIGIN 后更短，可以直接就地覆盖，不影响 ELF 结构。
     */
    private fun patchElfRunpaths(root: File) {
        val binDir = File(root, "bin")
        for (file in binDir.listFiles() ?: emptyArray()) {
            if (!file.isFile) continue
            try {
                when (ElfRunpath.patch(file, "\$ORIGIN/../lib")) {
                    ElfRunpath.Result.PATCHED -> Log.i(TAG, "已改写 RUNPATH: ${file.name}")
                    ElfRunpath.Result.FAILED -> Log.w(TAG, "RUNPATH 改写失败: ${file.name}")
                    else -> {}
                }
            } catch (e: Exception) {
                Log.w(TAG, "RUNPATH 改写异常: ${file.name}", e)
            }
        }
        val libDir = File(root, "lib")
        for (file in libDir.listFiles() ?: emptyArray()) {
            if (!file.isFile) continue
            try {
                when (ElfRunpath.patch(file, "\$ORIGIN")) {
                    ElfRunpath.Result.PATCHED -> Log.i(TAG, "已改写 RUNPATH: ${file.name}")
                    ElfRunpath.Result.FAILED -> Log.w(TAG, "RUNPATH 改写失败: ${file.name}")
                    else -> {}
                }
            } catch (e: Exception) {
                Log.w(TAG, "RUNPATH 改写异常: ${file.name}", e)
            }
        }
    }

    private fun deleteRecursive(file: File) {
        if (!file.exists()) return
        if (file.isDirectory) {
            file.listFiles()?.forEach { deleteRecursive(it) }
        }
        if (!file.delete()) Log.w(TAG, "删除失败: ${file.absolutePath}")
    }
}

/**
 * 就地改写 ELF64(小端) 的 DT_RUNPATH / DT_RPATH。
 *
 * 只做等长或缩短的替换：新串写进原字符串位置，剩余字节补 NUL。
 * 改的是 .dynstr 里那一段，不会移动任何偏移，所以对 ELF 结构是安全的。
 */
private object ElfRunpath {
    enum class Result { NOT_ELF, NO_RUNPATH, PATCHED, FAILED }

    fun patch(file: File, newRunpath: String): Result {
        RandomAccessFile(file, "rw").use { raf ->
            if (raf.length() < 64) return Result.NOT_ELF

            val ident = ByteArray(16)
            raf.seek(0)
            raf.readFully(ident)
            if (ident[0] != 0x7f.toByte() || ident[1] != 'E'.code.toByte() ||
                ident[2] != 'L'.code.toByte() || ident[3] != 'F'.code.toByte()
            ) {
                return Result.NOT_ELF
            }
            // 只处理 ELF64 + 小端（本工程的 proot 只有 arm64）
            if (ident[4].toInt() != 2 || ident[5].toInt() != 1) return Result.NOT_ELF

            val phoff = raf.leLong(0x20)
            val phentsize = raf.leShort(0x36)
            val phnum = raf.leShort(0x38)
            if (phoff <= 0 || phentsize < 56 || phnum <= 0) return Result.NOT_ELF

            var dynOffset = -1L
            var dynSize = 0L
            val loads = ArrayList<LongArray>() // [p_offset, p_vaddr, p_filesz]

            for (i in 0 until phnum) {
                val base = phoff + i.toLong() * phentsize
                when (raf.leInt(base)) {
                    1 -> loads.add(
                        longArrayOf(
                            raf.leLong(base + 8),
                            raf.leLong(base + 16),
                            raf.leLong(base + 32),
                        ),
                    )
                    2 -> {
                        dynOffset = raf.leLong(base + 8)
                        dynSize = raf.leLong(base + 32)
                    }
                }
            }
            if (dynOffset < 0 || dynSize <= 0) return Result.NO_RUNPATH

            var strtabVaddr = -1L
            var strtabSize = 0L
            var runpathOffset = -1L
            var i = 0
            val dynEntries = (dynSize / 16).toInt()
            while (i < dynEntries) {
                val base = dynOffset + i * 16L
                val tag = raf.leLong(base)
                val value = raf.leLong(base + 8)
                if (tag == 0L) break
                when (tag) {
                    5L -> strtabVaddr = value
                    10L -> strtabSize = value
                    15L, 29L -> if (runpathOffset < 0) runpathOffset = value
                }
                i++
            }
            if (strtabVaddr < 0 || strtabSize <= 0 || runpathOffset < 0) return Result.NO_RUNPATH

            var strtabFile = -1L
            for (seg in loads) {
                if (strtabVaddr >= seg[1] && strtabVaddr < seg[1] + seg[2]) {
                    strtabFile = seg[0] + (strtabVaddr - seg[1])
                    break
                }
            }
            if (strtabFile < 0) return Result.FAILED

            val at = strtabFile + runpathOffset
            raf.seek(at)
            val oldBytes = ArrayList<Byte>()
            val maxString = strtabSize.coerceAtMost(4096L).toInt()
            while (oldBytes.size < maxString) {
                val b = raf.read()
                if (b < 0 || b == 0) break
                oldBytes.add(b.toByte())
            }
            val oldLength = oldBytes.size
            if (oldLength == 0) return Result.NO_RUNPATH
            val oldText = String(oldBytes.toByteArray(), Charsets.ISO_8859_1)
            // 已经是 $ORIGIN 形式（或已适配过）就不再处理
            if (oldText.startsWith("\$")) return Result.NO_RUNPATH

            val bytes = newRunpath.toByteArray(Charsets.US_ASCII)
            if (bytes.size > oldLength) return Result.FAILED

            raf.seek(at)
            raf.write(bytes)
            // 补 NUL，保留原来的结尾 NUL
            raf.write(ByteArray(oldLength - bytes.size + 1))
            return Result.PATCHED
        }
    }

    private fun RandomAccessFile.leShort(offset: Long): Int {
        seek(offset)
        val b = ByteArray(2)
        readFully(b)
        return (b[0].toInt() and 0xFF) or ((b[1].toInt() and 0xFF) shl 8)
    }

    private fun RandomAccessFile.leInt(offset: Long): Int {
        seek(offset)
        val b = ByteArray(4)
        readFully(b)
        return (b[0].toInt() and 0xFF) or
            ((b[1].toInt() and 0xFF) shl 8) or
            ((b[2].toInt() and 0xFF) shl 16) or
            ((b[3].toInt() and 0xFF) shl 24)
    }

    private fun RandomAccessFile.leLong(offset: Long): Long {
        seek(offset)
        val b = ByteArray(8)
        readFully(b)
        var v = 0L
        for (k in 7 downTo 0) v = (v shl 8) or (b[k].toLong() and 0xFF)
        return v
    }
}
