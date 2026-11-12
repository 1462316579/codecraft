package ids.codecraft.app

import android.app.Activity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors
import java.util.zip.ZipFile

/**
 * 把 APK 当压缩包解开,供逆向项目的文件面板浏览。
 *
 * 解压放在单线程池里做:APK 动辄上百 MB,占着主线程会把界面卡住。
 */
class ApkFilesChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "ids.codecraft.app/apk_files"
    }

    private val executor = Executors.newSingleThreadExecutor()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "extract" -> extract(
                call.argument<List<String>>("apkPaths") ?: call.argument<String>("apkPath")?.let { listOf(it) },
                call.argument<String>("destDir"),
                result,
            )
            else -> result.notImplemented()
        }
    }

    private fun extract(apkPaths: List<String>?, destDir: String?, result: MethodChannel.Result) {
        if (apkPaths.isNullOrEmpty() || destDir.isNullOrEmpty()) {
            result.error("BAD_ARGS", "缺少 apkPaths 或 destDir", null)
            return
        }
        executor.execute {
            // 先解分卷、最后解 base:同名条目(AndroidManifest.xml 等)以 base 为准。
            val ordered = apkPaths.drop(1) + apkPaths.first()
            val count = runCatching { ordered.sumOf { unzip(File(it), File(destDir)) } }
            activity.runOnUiThread {
                count.fold(
                    onSuccess = { result.success(it) },
                    onFailure = { result.error("EXTRACT_FAILED", it.message ?: "解压失败", null) },
                )
            }
        }
    }

    /** 解压全部条目,返回写出的文件数;条目名做了穿越校验。 */
    private fun unzip(apk: File, destDir: File): Int {
        if (!destDir.exists() && !destDir.mkdirs()) {
            throw IllegalStateException("无法创建目标目录")
        }
        val root = destDir.canonicalFile
        var count = 0
        ZipFile(apk).use { zip ->
            for (entry in zip.entries()) {
                val name = entry.name
                if (name.contains("..")) continue
                val target = File(root, name)
                if (!target.canonicalPath.startsWith(root.canonicalPath + File.separator)) continue
                if (entry.isDirectory) {
                    target.mkdirs()
                    continue
                }
                target.parentFile?.mkdirs()
                zip.getInputStream(entry).use { input ->
                    target.outputStream().use { output -> input.copyTo(output) }
                }
                count++
            }
        }
        return count
    }
}
