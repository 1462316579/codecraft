package ids.codecraft.app

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.AdaptiveIconDrawable
import android.graphics.drawable.Drawable
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

/**
 * 已安装应用信息:列表(名称/包名/版本)与图标。
 *
 * 「应用逆向」类项目从这里选目标应用;只读公开的应用元数据,不做任何其它操作。
 * 图标按需单条取(列表一次回传几百个 PNG 太重),Dart 侧缓存。
 */
class InstalledAppsChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "ids.codecraft.app/installed_apps"

        /** 图标统一缩到这个边长再编码,足够列表显示,避免原始分辨率的大位图。 */
        private const val ICON_SIZE = 192
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "listApps" -> result.success(listApps())
            "appIcon" -> result.success(appIcon(call.argument<String>("packageName")))
            else -> result.notImplemented()
        }
    }

    private fun listApps(): List<Map<String, Any?>> {
        val pm = context.packageManager
        val installed = runCatching { pm.getInstalledApplications(PackageManager.GET_META_DATA) }
            .getOrDefault(emptyList())
        // 排除自己:Codecraft 不会成为自己的逆向目标。
        return installed
            .filter { it.packageName != context.packageName }
            .map { app ->
                val info = runCatching { pm.getPackageInfo(app.packageName, 0) }.getOrNull()
                mapOf(
                    "packageName" to app.packageName,
                    "label" to runCatching { pm.getApplicationLabel(app).toString() }
                        .getOrDefault(app.packageName),
                    "versionName" to (info?.versionName ?: ""),
                    "versionCode" to (info?.longVersionCode ?: 0L),
                    "isSystem" to ((app.flags and ApplicationInfo.FLAG_SYSTEM) != 0),
                    // 逆向项目按这些路径读 APK 内的文件:首个是 base.apk,
                    // 其后是 ABI/语言等分卷(AAB 分发的应用,原生库常只存在于分卷里)。
                    "apkPath" to app.sourceDir,
                    "apkPaths" to (listOf(app.sourceDir) + (app.splitSourceDirs?.toList() ?: emptyList())),
                )
            }
            .sortedBy { (it["label"] as String).lowercase() }
    }

    private fun appIcon(packageName: String?): ByteArray? {
        if (packageName.isNullOrEmpty()) return null
        val drawable = runCatching { context.packageManager.getApplicationIcon(packageName) }
            .getOrNull() ?: return null
        return drawableToPng(drawable)
    }

    private fun drawableToPng(drawable: Drawable): ByteArray {
        val size = ICON_SIZE
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        // 自适应图标(API 26+):背景与前景两层要各自铺满画布,按默认内边距画会缩小。
        if (drawable is AdaptiveIconDrawable) {
            drawable.background.setBounds(0, 0, size, size)
            drawable.background.draw(canvas)
            drawable.foreground.setBounds(0, 0, size, size)
            drawable.foreground.draw(canvas)
        } else {
            drawable.setBounds(0, 0, size, size)
            drawable.draw(canvas)
        }
        val out = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 90, out)
        bitmap.recycle()
        return out.toByteArray()
    }
}