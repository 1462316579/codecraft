package ids.codecraft.app

import android.content.Context
import android.util.Log
import java.io.BufferedInputStream
import java.io.File
import java.io.FileInputStream
import java.io.FilterInputStream
import java.io.FileOutputStream
import java.io.InputStream
import java.io.RandomAccessFile
import java.nio.file.Files
import java.nio.file.Paths

/**
 * Bootstrap 安装器：在首次打开终端时，将内嵌的 Termux 完整 bootstrap 解压到 $PREFIX。
 *
 * 行为完全对齐 Termux 官方 TermuxInstaller：
 * 1. bootstrap zip 内嵌在 APK 的 jniLibs 中（libtermux-bootstrap-arm64.zip.so，
 *    与官方 libtermux-bootstrap-*.zip.so 机制完全一致），随 useLegacyPackaging
 *    解压到 nativeLibraryDir，首次启动直接读取，全程离线。
 * 2. 检查 $PREFIX/bin/bash 是否存在；若存在则视为已安装，跳过。
 * 3. 解压到临时目录，处理 SYMLINKS.txt 创建符号链接（路径从 /data/data/com.termux/files/usr 重映射）。
 * 4. 重写脚本里的 Termux 硬编码路径（shebang 与脚本体，包名不同的必需适配）。
 * 5. 设置可执行权限（bin/、libexec/、apt 相关）。
 * 6. 运行 bootstrap second stage（各包 postinst 维护脚本）。
 * 7. 将临时目录重命名为 $PREFIX，标记已安装版本。
 *
 * 设计说明：
 * - 使用 Termux 官方 bootstrap zip（含 bash、apt、dpkg、coreutils 等完整工具链）。
 * - 不联网：zip 内嵌于 APK，安装过程离线完成。
 * - 所有路径基于 App 私有目录：/data/user/0/ids.codecraft.app/files/usr
 */
object BootstrapInstaller {
    private const val TAG = "BootstrapInstaller"
    private const val BOOTSTRAP_VERSION = "2026.11.15-r4+apt.android-7"
    private const val MARKER_NAME = ".bootstrapped"

    /** 内嵌 bootstrap 在 assets 中的目录名（已解压内容，无需解压）。 */
    private const val BOOTSTRAP_ASSET_DIR = "usr"

    // Termux 原始 PREFIX 路径，用于 SYMLINKS.txt 中的路径重映射
    private const val TERMUX_PREFIX = "/data/data/com.termux/files/usr"

    /** 确保 bootstrap 已安装。若未安装则解压内嵌的 bootstrap。 */
    fun ensureInstalledAsync(context: Context, onComplete: (Boolean) -> Unit) {
        // 在后台线程执行，避免阻塞 Android UI 线程
        Thread {
            val filesDir = context.filesDir
            val prefixDir = File(filesDir, "usr")
            val markerFile = File(prefixDir, MARKER_NAME)

            // 检查是否已安装有效版本
            if (markerFile.exists()) {
                val savedVersion = markerFile.readText().trim()
                if (savedVersion == BOOTSTRAP_VERSION) {
                    if (File(prefixDir, "bin/bash").exists() && File(prefixDir, "bin/apt").exists()) {
                        Log.i(TAG, "Bootstrap 已安装 (v$BOOTSTRAP_VERSION)，跳过")
                        stage = "完成"
                        progress = 100
                        lastError = null
                        onComplete(true)
                        return@Thread
                    }
                }
            }

            synchronized(installLock) {
                if (installing) {
                    // 另一个安装正在进行（例如 Dart 侧重复触发），直接报告“进行中”
                    onComplete(false)
                    return@Thread
                }
                installing = true
            }
            lastError = null
            Log.i(TAG, "开始异步安装 bootstrap 到 $prefixDir")
            val success = try {
                installBootstrap(context, prefixDir)
            } catch (e: Exception) {
                Log.e(TAG, "Bootstrap 安装失败", e)
                lastError = "${e.javaClass.simpleName}: ${e.message ?: ""}"
                stage = "安装失败"
                false
            } finally {
                installing = false
            }
            if (success) {
                stage = "完成"
                progress = 100
            }
            onComplete(success)
        }.start()
    }

    /** 安装是否正在进行（供 Dart 侧轮询门控）。 */
    @Volatile
    var installing = false
        private set

    /** 当前安装阶段文案（供 Dart 侧轮询展示）。 */
    @Volatile
    var stage: String = ""
        private set

    /** 下载进度 0-100；-1 表示不适用（解压/配置阶段）。 */
    @Volatile
    var progress: Int = -1
        private set

    /** 最近一次安装失败原因；成功或未开始安装时为 null。 */
    @Volatile
    var lastError: String? = null
        private set

    private val installLock = Any()

    /** 是否已完成安装（版本标记 + 关键二进制齐全）。 */
    fun isInstalled(context: Context): Boolean {
        val prefixDir = File(context.filesDir, "usr")
        val markerFile = File(prefixDir, MARKER_NAME)
        return markerFile.exists() &&
            markerFile.readText().trim() == BOOTSTRAP_VERSION &&
            File(prefixDir, "bin/bash").exists() &&
            File(prefixDir, "bin/apt").exists()
    }

    @Deprecated("Use ensureInstalledAsync instead to avoid UI blocking", ReplaceWith("ensureInstalledAsync(context) { ... }"))
    fun ensureInstalled(context: Context): Boolean {
        // 保持旧接口兼容性，但由于是同步阻塞，仅建议在非UI线程调用
        return try {
            installBootstrap(context, File(context.filesDir, "usr"))
        } catch (e: Exception) {
            false
        }
    }

    private fun installBootstrap(context: Context, prefixDir: File): Boolean {
        // 1. 创建临时目录
        val stagingDir = File(prefixDir.parentFile, "usr-staging-${System.currentTimeMillis()}")
        if (stagingDir.exists()) {
            deleteRecursive(stagingDir)
        }
        stagingDir.mkdirs()

        try {
            // 2. 从 assets/usr 拷贝已解压的环境（纯文件拷贝，无解压开销）
            stage = "拷贝环境文件"
            progress = -1
            Log.i(TAG, "从 assets/$BOOTSTRAP_ASSET_DIR 拷贝环境到 $stagingDir")
            copyAssets(context, BOOTSTRAP_ASSET_DIR, stagingDir)

            // 3. 处理符号链接（基于随包携带的 SYMLINKS.txt）
            stage = "创建符号链接"
            progress = -1
            processSymlinks(stagingDir, context)

            // 4. 改写 ELF 的 DT_RUNPATH：Termux 官方包把库路径编译成了
            //    /data/data/com.termux/files/usr/lib（本应用没有这个目录），
            //    不改成 $ORIGIN 相对路径的话，bash 一 exec 就因找不到
            //    libreadline.so.8 / libncursesw.so.6 而立刻退出。
            stage = "适配动态库路径"
            progress = -1
            patchElfRunpaths(stagingDir)

            // 5. 重写脚本里的 Termux 硬编码路径（shebang 与脚本体），
            //    否则 login/pkg/postinst 等脚本因 shebang 指向不存在的 Termux 路径而无法 exec。
            //    注意：重写目标必须是最终 prefix 路径（而非 staging），
            //    因为 second stage 在 rename 之后运行。
            stage = "适配路径"
            rewriteTermuxPaths(stagingDir, prefixDir.absolutePath)

            // 6. 设置可执行权限
            stage = "设置权限"
            setExecutablePermissions(stagingDir)

            // 7. 清理旧的 prefix（如果存在）
            if (prefixDir.exists()) {
                Log.i(TAG, "移除旧的 prefix 目录")
                deleteRecursive(prefixDir)
            }

            // 8. 原子性重命名 staging -> prefix
            if (!stagingDir.renameTo(prefixDir)) {
                throw RuntimeException("重命名 staging 到 prefix 失败")
            }

            // 9. 运行 bootstrap second stage（执行各包 postinst 维护脚本，
            //    对齐 Termux/ZeroTermux：update-alternatives、termux-exec LD_PRELOAD 等）。
            //    失败仅记录错误，保留可用环境（bash 仍可工作）。
            stage = "配置环境（second stage）"
            if (!runSecondStage(prefixDir)) {
                Log.e(TAG, "Bootstrap second stage 未完全成功，保留现有环境继续（详见 logcat）")
            }

            // 10. 写 login shell 的启动文件，让 bash -l 能读到 $PREFIX/etc/profile
            //     （Termux 的 bash 把 SYS_PROFILE 编译成了 com.termux 的绝对路径，
            //      换成别的包名后读不到，只能通过 ~/.bash_profile 转一手）。
            writeShellStartupFiles(prefixDir)

            // 11. 写入版本标记
            stage = "写入完成标记"
            File(prefixDir, MARKER_NAME).writeText(BOOTSTRAP_VERSION)

            Log.i(TAG, "Bootstrap 安装完成")
            return true
        } finally {
            // 清理临时文件
            if (stagingDir.exists()) {
                deleteRecursive(stagingDir)
            }
        }
    }

    /**
     * 递归拷贝 assets 下的目录到目标目录。
     *
     * 纯字节拷贝，不解析 zip（比解压 33MB 的 zip 更快）。
     * assets.list() 对空目录和文件都返回空数组，因此空数组时先尝试 open，
     * FileNotFoundException 则建目录。
     */
    private fun copyAssets(context: Context, assetDir: String, destDir: File) {
        val assets = context.assets
        val stack = ArrayDeque<Pair<String, File>>()
        stack.add(assetDir to destDir)
        var copiedFiles = 0
        var createdDirs = 0

        while (stack.isNotEmpty()) {
            val (assetPath, target) = stack.removeLast()
            val children = try {
                assets.list(assetPath) ?: emptyArray()
            } catch (_: Exception) {
                emptyArray()
            }
            if (children.isNotEmpty()) {
                target.mkdirs()
                createdDirs++
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
                copiedFiles++
            } catch (_: java.io.FileNotFoundException) {
                // 空目录
                target.mkdirs()
            } catch (e: Exception) {
                Log.w(TAG, "拷贝失败: $assetPath", e)
            }
        }
        Log.i(TAG, "拷贝完成: $copiedFiles 个文件, $createdDirs 个目录")
    }

    /**
     * 重写脚本里的 Termux 硬编码路径：
     * - shebang（如 #!/data/data/com.termux/files/usr/bin/sh）→ 本应用真实前缀
     * - 脚本体内引用（login/pkg/postinst 等的 motd、SHELL 检测、update-alternatives 路径）
     *   → 本应用真实前缀
     * - 配置文件（etc/profile、etc/bash.bashrc、etc/termux/…）
     *
     * 覆盖范围（对齐 Termux 安装行为）：
     * - bin/、libexec/ 顶层（login、pkg、update-alternatives 等）
     * - etc/ 整个目录递归（profile、profile.d、bash.bashrc、termux/）
     * - var/lib/dpkg/info/ 递归（各包的 postinst 维护脚本，second stage 需要执行它们）
     *
     * 仅处理文本文件（以 #! 开头或不含 NUL 字节），大小限制 2MB，避免误伤二进制。
     * [targetPrefix] 必须是最终安装路径（因为 second stage 在 rename 之后运行）。
     */
    private fun rewriteTermuxPaths(stagingDir: File, targetPrefix: String) {
        val roots = listOf(
            File(stagingDir, "bin"),
            File(stagingDir, "libexec"),
            File(stagingDir, "etc"),
            File(stagingDir, "var/lib/dpkg/info"),
        )
        var rewritten = 0
        var skippedBinary = 0
        var skippedNoMatch = 0

        fun rewriteFile(file: File) {
            try {
                if (!file.isFile || file.length() == 0L || file.length() > 2 * 1024 * 1024) return
                val head = ByteArray(2)
                file.inputStream().use { ins ->
                    val n = ins.read(head)
                    if (n < 2) return
                }
                // 二进制文件（ELF 等）跳过：路径重写由 termux-exec 的 LD_PRELOAD 在运行时处理
                if (head[0] == 0.toByte() || head[1] == 0.toByte()) {
                    skippedBinary++
                    return
                }
                val text = file.readText()
                if (!text.contains(TERMUX_PREFIX)) {
                    skippedNoMatch++
                    return
                }
                file.writeText(text.replace(TERMUX_PREFIX, targetPrefix))
                rewritten++
            } catch (e: Exception) {
                Log.w(TAG, "重写脚本失败: ${file.absolutePath}", e)
            }
        }

        fun walk(dir: File, recurse: Boolean) {
            if (!dir.isDirectory) return
            for (file in dir.listFiles() ?: emptyArray()) {
                if (file.isDirectory) {
                    if (recurse) walk(file, true)
                } else {
                    rewriteFile(file)
                }
            }
        }

        for ((index, root) in roots.withIndex()) {
            // bin/ 与 libexec/ 只处理顶层（子目录多为二进制资源），其余递归
            walk(root, recurse = index >= 2)
        }
        Log.i(TAG, "已重写 $rewritten 个脚本的 Termux 路径 → $targetPrefix（跳过二进制 $skippedBinary，无匹配 $skippedNoMatch）")
    }

    /**
     * 运行 bootstrap second stage：执行各包的 postinst 维护脚本。
     *
     * 对齐 Termux app 的 TermuxInstaller（输出写入 logcat）：
     * - 用 $PREFIX/bin/bash 执行 etc/termux/termux-bootstrap/second-stage/termux-bootstrap-second-stage.sh
     * - 环境变量：PREFIX / HOME / PATH / LD_LIBRARY_PATH / TMPDIR / TERMUX_PACKAGE_MANAGER 等
     * - 工作目录设为 "/"（与 dpkg 维护脚本行为一致）
     *
     * @return true 表示成功（或无需运行）；false 表示失败，调用方应清理 prefix。
     */
    private fun runSecondStage(prefixDir: File): Boolean {
        val bash = File(prefixDir, "bin/bash")
        val script = File(
            prefixDir,
            "etc/termux/termux-bootstrap/second-stage/termux-bootstrap-second-stage.sh",
        )
        if (!bash.exists() || !script.exists()) {
            Log.w(TAG, "未找到 second stage 脚本，跳过（bash=${bash.exists()} script=${script.exists()}）")
            return true
        }
        script.setExecutable(true, false)

        Log.i(TAG, "运行 termux bootstrap second stage...")
        val process = try {
            val pb = ProcessBuilder(bash.absolutePath, script.absolutePath)
            pb.directory(File("/"))
            pb.redirectErrorStream(true)
            val env = pb.environment()
            env.clear()
            env["HOME"] = File(prefixDir.parentFile, "home").absolutePath
            env["PREFIX"] = prefixDir.absolutePath
            env["PATH"] = "${prefixDir.absolutePath}/bin:${prefixDir.absolutePath}/bin/applets:/system/bin:/system/xbin"
            env["LD_LIBRARY_PATH"] = "${prefixDir.absolutePath}/lib"
            env["TMPDIR"] = "${prefixDir.absolutePath}/tmp"
            env["TERM"] = "xterm-256color"
            env["LANG"] = "en_US.UTF-8"
            env["TERMUX_PACKAGE_MANAGER"] = "apt"
            env["TERMUX_PACKAGE_ARCH"] = "aarch64"
            env["TERMUX_APP_PID"] = android.os.Process.myPid().toString()
            pb.start()
        } catch (e: Exception) {
            Log.e(TAG, "无法启动 second stage 进程", e)
            return false
        }

        // 逐行读取输出写入 logcat（对齐 Termux：second stage 输出进 logcat）
        try {
            process.inputStream.bufferedReader().forEachLine { line ->
                Log.i("BootstrapSecondStage", line)
            }
        } catch (e: Exception) {
            Log.w(TAG, "读取 second stage 输出失败", e)
        }

        val code = try {
            process.waitFor()
        } catch (e: InterruptedException) {
            process.destroyForcibly()
            Log.e(TAG, "等待 second stage 被中断", e)
            return false
        }
        if (code != 0) {
            Log.e(TAG, "second stage 退出码: $code")
            return false
        }
        Log.i(TAG, "termux bootstrap second stage 完成")
        return true
    }

    /** 处理符号链接：基于随包携带的 assets/bootstrap_symlinks.txt，重映射到本应用 $PREFIX */
    private fun processSymlinks(stagingDir: File, context: Context) {
        val lines = try {
            context.assets.open("bootstrap_symlinks.txt").bufferedReader().readLines()
        } catch (e: Exception) {
            Log.w(TAG, "未找到 assets/bootstrap_symlinks.txt，跳过符号链接处理", e)
            return
        }

        // 文件格式为「<目标>←<链接路径>」，如：
        //   coreutils←./bin/sum        （bin/sum -> coreutils）
        //   libreadline.so.8←./lib/libreadline.so
        // 之前把左右两栏写反，导致 libreadline 等关键库链接成断链，bash 无法 exec。
        var pending = ArrayList<Pair<String, String>>()
        for (line in lines) {
            if (line.isBlank()) continue
            val parts = line.split("←")
            if (parts.size != 2) continue
            val target = parts[0]
            val linkRel = parts[1].removePrefix("./")
            if (target.isBlank() || linkRel.isBlank()) continue
            pending.add(target to linkRel)
        }

        var created = 0
        var pass = 0
        // 链接可能指向同批次后面才创建的链接（如 libreadline.so -> .so.8 -> .so.8.3），
        // 因此多轮处理，直到没有新进展。
        while (pending.isNotEmpty() && pass < 5) {
            val next = ArrayList<Pair<String, String>>()
            for ((rawTarget, linkRel) in pending) {
                val linkFile = File(stagingDir, linkRel)
                // assets 中已是实体文件的保留实体文件，不覆盖为符号链接
                if (!Files.isSymbolicLink(linkFile.toPath()) && linkFile.isFile) {
                    continue
                }
                val targetPath =
                    rawTarget.replace(TERMUX_PREFIX, stagingDir.absolutePath)
                val resolvedTarget = when {
                    targetPath.startsWith("/") -> File(targetPath)
                    targetPath.startsWith("./") -> File(stagingDir, targetPath.removePrefix("./"))
                    else -> File(linkFile.parentFile, targetPath)
                }
                // 目标不存在先跳过，避免生成断链（断链会让 bash 等二进制无法 exec）
                if (!resolvedTarget.exists()) {
                    next.add(rawTarget to linkRel)
                    continue
                }
                try {
                    Files.deleteIfExists(linkFile.toPath())
                    linkFile.parentFile?.mkdirs()
                    Files.createSymbolicLink(linkFile.toPath(), resolvedTarget.toPath())
                    created++
                } catch (e: Exception) {
                    Log.e(TAG, "创建符号链接失败: $linkRel -> $resolvedTarget", e)
                }
            }
            if (next.size == pending.size) break
            pending = next
            pass++
        }
        Log.i(TAG, "已创建 $created 个符号链接，未解析 ${pending.size} 个")
    }

    /**
     * 改写 bootstrap 中所有 ELF 的 DT_RUNPATH / DT_RPATH。
     *
     * Termux 官方 bootstrap 是按包名 com.termux 编译的，动态库搜索路径被写死成
     * /data/data/com.termux/files/usr/lib。本应用包名不同，该目录不存在，
     * 于是 bash 一 exec 就报 "CANNOT LINK EXECUTABLE ... library ... not found"
     * 并立刻退出（这就是「bash 秒退、界面空白」的根因）。
     *
     * 这里把 RUNPATH 就地换成相对 $ORIGIN 的形式（比原串短，可以直接覆盖）：
     * - bin/、libexec/ 下的可执行文件 → $ORIGIN/../lib
     * - lib/ 下的共享库 → $ORIGIN（依赖都在同一目录）
     * - lib/apt/methods/ 下的 apt 方法 → $ORIGIN/../../lib
     * 这样与安装路径、包名完全无关，也不再依赖 LD_LIBRARY_PATH 是否被链接器采纳。
     */
    private fun patchElfRunpaths(stagingDir: File) {
        var patched = 0
        var failed = 0

        fun patchDir(dir: File, runpath: String) {
            if (!dir.isDirectory) return
            for (file in dir.listFiles() ?: emptyArray()) {
                if (!file.isFile) continue
                try {
                    when (ElfRunpath.patch(file, runpath)) {
                        ElfRunpath.Result.PATCHED -> patched++
                        ElfRunpath.Result.FAILED -> {
                            failed++
                            Log.w(TAG, "RUNPATH 改写失败（新串过长？）: ${file.name}")
                        }
                        else -> {}
                    }
                } catch (e: Exception) {
                    failed++
                    Log.w(TAG, "RUNPATH 改写异常: ${file.name}", e)
                }
            }
        }

        patchDir(File(stagingDir, "bin"), "\$ORIGIN/../lib")
        patchDir(File(stagingDir, "libexec"), "\$ORIGIN/../lib")
        patchDir(File(stagingDir, "lib"), "\$ORIGIN")
        patchDir(File(stagingDir, "lib/apt/methods"), "\$ORIGIN/../../lib")

        Log.i(TAG, "已改写 $patched 个 ELF 的 RUNPATH（失败 $failed）")
    }

    /**
     * 写 login shell 的启动文件。
     *
     * Termux 的 bash 把 SYS_PROFILE 编译成了 /data/data/com.termux/files/usr/etc/profile，
     * 换包名后 bash -l 读不到 $PREFIX/etc/profile，于是拿不到 PS1 / PATH 等设置。
     * 用 ~/.bash_profile 转一手即可等价恢复（proot-distro、Termux 多包名 fork 都这么做）。
     */
    private fun writeShellStartupFiles(prefixDir: File) {
        val homeDir = File(prefixDir.parentFile, "home").apply { mkdirs() }
        val profile = File(homeDir, ".bash_profile")
        if (profile.exists()) return
        profile.writeText(
            """
            # CodeCraft Terminal：把 Termux 的全局 profile 接进登录 shell
            if [ -r "${'$'}PREFIX/etc/profile" ]; then
                . "${'$'}PREFIX/etc/profile"
            fi
            """.trimIndent() + "\n",
        )
    }

    /** 设置可执行权限：bin/、libexec/、apt 相关 */
    private fun setExecutablePermissions(rootDir: File) {
        val executablePrefixes = listOf("bin/", "libexec/", "lib/apt/apt-helper", "lib/apt/methods/")

        fun processFile(file: File) {
            if (file.isDirectory) {
                file.listFiles()?.forEach { processFile(it) }
            } else {
                val relPath = rootDir.toPath().relativize(file.toPath()).toString().replace('\\', '/')
                val shouldBeExecutable = executablePrefixes.any { relPath.startsWith(it) }
                if (shouldBeExecutable) {
                    file.setExecutable(true, false)
                }
            }
        }

        processFile(rootDir)
    }

    /**
     * 启动前自检：在真实子进程里执行 bash，验证 exec 权限、动态链接与基础环境。
     *
     * 这一步非常关键：bash 秒退的原因可能是
     * - exec 被 SELinux 拒绝（targetSdk >= 29 时的 W^X 策略）→ IOException: error=13
     * - 动态链接失败（缺 libreadline.so.8 等）→ 退出码 127，或 IOException: error=2
     * - 前缀路径没适配 → "-c" 参数无效、找不到库
     * ProcessBuilder 会把 errno 原文带回来，可直接显示给用户。
     *
     * 除了基础 exec，还会跑一次 `bash -l`（等价于终端里的登录 shell），
     * 用来判断 profile 链是否把 shell 带崩；Dart 侧据此选择启动参数。
     *
     * @return {ok, exitCode, output, detail, loginOk, loginDetail}
     */
    fun preflight(context: Context): Map<String, Any?> {
        val prefixDir = File(context.filesDir, "usr")
        val homeDir = File(context.filesDir, "home").apply { mkdirs() }
        val tmpDir = File(prefixDir, "tmp").apply { mkdirs() }
        val bash = File(prefixDir, "bin/bash")

        val issues = ArrayList<String>()
        if (!bash.exists()) {
            issues.add("未找到 ${bash.absolutePath}")
        } else {
            if (bash.length() < 100_000L) issues.add("bin/bash 大小异常(${bash.length()})")
            if (!bash.canExecute()) issues.add("bin/bash 不可执行（权限位缺失）")
        }
        val readline = File(prefixDir, "lib/libreadline.so.8")
        if (!readline.exists()) issues.add("lib/libreadline.so.8 缺失（符号链接未创建）")
        val readlineReal = File(prefixDir, "lib/libreadline.so.8.3")
        if (!readlineReal.exists()) issues.add("lib/libreadline.so.8.3 缺失（bootstrap 未完整拷贝）")

        if (issues.isNotEmpty()) {
            val detail = issues.joinToString("；")
            Log.e(TAG, "preflight 失败: $detail")
            return mapOf(
                "ok" to false,
                "exitCode" to null,
                "output" to "",
                "detail" to detail,
                "loginOk" to false,
                "loginDetail" to "",
            )
        }

        val prefixPath = prefixDir.absolutePath
        val env = mapOf(
            "PREFIX" to prefixPath,
            "HOME" to homeDir.absolutePath,
            "TMPDIR" to tmpDir.absolutePath,
            "SHELL" to bash.absolutePath,
            "PATH" to "$prefixPath/bin:$prefixPath/bin/applets:/system/bin:/system/xbin",
            "LD_LIBRARY_PATH" to "$prefixPath/lib",
            "TERM" to "xterm-256color",
            "COLORTERM" to "truecolor",
            "LANG" to "en_US.UTF-8",
            "LC_ALL" to "en_US.UTF-8",
        )

        val basic = runBashProbe(
            bash,
            homeDir,
            env,
            listOf("-c", "echo __CODECRAFT_OK__; echo \"PREFIX=\$PREFIX\"; uname -m"),
        )
        if (!basic.ok) {
            return mapOf(
                "ok" to false,
                "exitCode" to basic.code,
                "output" to basic.output.take(600),
                "detail" to basic.detail,
                "loginOk" to false,
                "loginDetail" to "",
            )
        }

        // 登录 shell：会读 ~/.bash_profile 与 $PREFIX/etc/profile，
        // 这两者里任何一步写错都会让 bash 直接退出。
        val login = runBashProbe(bash, homeDir, env, listOf("-l", "-c", "echo __CODECRAFT_OK__"))

        return mapOf(
            "ok" to true,
            "exitCode" to basic.code,
            "output" to basic.output.take(600),
            "detail" to "",
            "loginOk" to login.ok,
            "loginDetail" to login.detail,
        )
    }

    /** preflight 单次探测结果。 */
    private class Probe(
        val ok: Boolean,
        val code: Int?,
        val output: String,
        val detail: String,
    )

    private fun runBashProbe(
        bash: File,
        homeDir: File,
        env: Map<String, String>,
        args: List<String>,
    ): Probe {
        return try {
            val builder = ProcessBuilder(listOf(bash.absolutePath) + args)
            builder.directory(homeDir)
            builder.redirectErrorStream(true)
            builder.environment().putAll(env)
            val process = builder.start()

            val output = StringBuilder()
            process.inputStream.bufferedReader().useLines { lines ->
                lines.forEach { line ->
                    if (output.length < 4000) output.append(line).append('\n')
                }
            }
            val label = args.joinToString(" ")
            val finished = process.waitFor(10, java.util.concurrent.TimeUnit.SECONDS)
            if (!finished) {
                process.destroyForcibly()
                Log.e(TAG, "preflight 超时: $label")
                return Probe(false, null, output.toString(), "bash $label 自检超时（10s 未返回）")
            }
            val code = process.exitValue()
            val text = output.toString()
            val ok = code == 0 && text.contains("__CODECRAFT_OK__")
            Log.i(TAG, "preflight bash $label ok=$ok code=$code output=${text.trim()}")
            Probe(
                ok = ok,
                code = code,
                output = text,
                detail = if (ok) {
                    ""
                } else {
                    "bash $label 退出码 $code" + if (text.isNotBlank()) "：${text.trim()}" else ""
                },
            )
        } catch (e: Exception) {
            // IOException 的 message 里带 errno，例如 "error=13, Permission denied"
            val detail = "bash ${args.joinToString(" ")} → ${e.javaClass.simpleName}: ${e.message ?: ""}"
            Log.e(TAG, "preflight 无法执行 bash", e)
            Probe(false, null, "", detail)
        }
    }

    /** 递归删除目录 */
    private fun deleteRecursive(file: File): Boolean {
        if (file.isDirectory) {
            file.listFiles()?.forEach { deleteRecursive(it) }
        }
        return file.delete()
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
            // 只处理 ELF64 + 小端（bootstrap 只有 arm64）
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