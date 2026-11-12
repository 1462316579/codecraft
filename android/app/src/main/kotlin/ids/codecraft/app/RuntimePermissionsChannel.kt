package ids.codecraft.app

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * 首次启动的运行时权限申请,交给系统自己的授权弹窗完成。
 *
 * 各版本要的权限不同:
 * - Android 13+:媒体读取(照片/视频/音频)+ 通知;
 * - Android 10~12:存储读写 + 通知(12 之前通知无需申请);
 * - Android 9 及以下:存储读写。
 * 系统会把这些合并成原生授权框,用户点「始终允许」后即可读写外部目录。
 *
 * 全文件访问(MANAGE_EXTERNAL_STORAGE)没有运行时弹窗,只能跳系统设置页,
 * 故不在此通道内(见 ExternalStorageChannel)。
 */
class RuntimePermissionsChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "ids.codecraft.app/permissions"

        /** 启动权限申请的请求码(`MainActivity.onRequestPermissionsResult` 据此回传)。 */
        const val REQUEST_STARTUP = 0x4A20

        /** 本机需要申请、且尚未授予的运行时权限。 */
        fun pendingPermissions(activity: Activity): List<String> {
            val wanted = mutableListOf<String>()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                wanted += Manifest.permission.READ_MEDIA_IMAGES
                wanted += Manifest.permission.READ_MEDIA_VIDEO
                wanted += Manifest.permission.READ_MEDIA_AUDIO
                wanted += Manifest.permission.POST_NOTIFICATIONS
            } else {
                wanted += Manifest.permission.READ_EXTERNAL_STORAGE
                if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.Q) {
                    wanted += Manifest.permission.WRITE_EXTERNAL_STORAGE
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    wanted += Manifest.permission.POST_NOTIFICATIONS
                }
            }
            return wanted.filter {
                ContextCompat.checkSelfPermission(activity, it) != PackageManager.PERMISSION_GRANTED
            }
        }
    }

    private var pendingResult: MethodChannel.Result? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // 弹系统授权框;返回用户是否全部允许。
            "requestStartup" -> requestStartup(result)
            // 是否还有未授予的启动权限(不弹框,用于判断是否需要申请)。
            "hasPending" -> result.success(pendingPermissions(activity).isNotEmpty())
            else -> result.notImplemented()
        }
    }

    private fun requestStartup(result: MethodChannel.Result) {
        val pending = pendingPermissions(activity)
        if (pending.isEmpty()) {
            result.success(true)
            return
        }
        if (pendingResult != null) {
            result.error("BUSY", "已有权限申请在进行", null)
            return
        }
        pendingResult = result
        activity.requestPermissions(pending.toTypedArray(), REQUEST_STARTUP)
    }

    /** 权限结果回传;返回 true 表示本次结果由本通道消费。 */
    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != REQUEST_STARTUP) return false
        val result = pendingResult ?: return true
        pendingResult = null
        result.success(grantResults.isNotEmpty() &&
            grantResults.all { it == PackageManager.PERMISSION_GRANTED })
        return true
    }
}
