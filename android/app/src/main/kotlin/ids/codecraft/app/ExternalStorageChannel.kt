package ids.codecraft.app

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 外部共享存储(如 `/storage/emulated/0/AI写作`)相关能力:
 * - 全文件访问权限(`MANAGE_EXTERNAL_STORAGE`,Android 11+)的查询与跳转申请;
 * - 系统目录选择器(SAF `ACTION_OPEN_DOCUMENT_TREE`)供用户选定任意目录;
 * - 主存储根路径(多用户/工作资料下不是固定 `/storage/emulated/0`)。
 *
 * 为什么需要两条路:全文件访问让 App 直接用普通路径读写(无需 SAF 逐次授权),
 * 但该权限较重且部分分发渠道不接受;目录选择器则不挑权限,代价是只能访问用户选中的子树。
 */
class ExternalStorageChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "ids.codecraft.app/external_storage"

        /** 目录选择器的请求码(`MainActivity.onActivityResult` 据此回传)。 */
        const val REQUEST_PICK_TREE = 0x4A1C
    }

    /** 选择器结果待回传的 result;同一时刻只允许一个选择流程。 */
    private var pendingResult: MethodChannel.Result? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "primaryRoot" -> result.success(primaryRoot())
            "hasAllFilesAccess" -> result.success(hasAllFilesAccess())
            // 跳系统设置页申请「所有文件访问权限」。返回 true 表示已跳转(不代表已授予),
            // 授权结果由 Dart 侧在回到前台后重新查询。
            "requestAllFilesAccess" -> {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
                    result.success(false)
                    return
                }
                if (hasAllFilesAccess()) {
                    result.success(true)
                    return
                }
                val intent = Intent(
                    Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                    Uri.parse("package:${activity.packageName}")
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                result.success(runCatching { activity.startActivity(intent) }.isSuccess)
            }
            // 系统目录选择器:返回选中的绝对路径(失败/取消返回 null)。
            "pickDirectory" -> {
                if (pendingResult != null) {
                    result.error("BUSY", "已有目录选择流程在进行", null)
                    return
                }
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                    addFlags(
                        Intent.FLAG_GRANT_READ_URI_PERMISSION or
                            Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                            Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
                    )
                }
                pendingResult = result
                val started = runCatching {
                    activity.startActivityForResult(intent, REQUEST_PICK_TREE)
                }.isSuccess
                if (!started) {
                    pendingResult = null
                    result.error("NO_PICKER", "系统没有可用的目录选择器", null)
                }
            }
            // 普通存储读写权限(Android 10 及以下需要;11+ 由全文件访问覆盖)。
            "hasLegacyStorage" -> result.success(hasLegacyStorage())
            "requestLegacyStorage" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    result.success(true)
                    return
                }
                activity.requestPermissions(
                    arrayOf(
                        Manifest.permission.READ_EXTERNAL_STORAGE,
                        Manifest.permission.WRITE_EXTERNAL_STORAGE,
                    ),
                    0x4A1D
                )
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    /** 主存储根:优先系统 API,取不到退回 `/storage/emulated/0`。 */
    private fun primaryRoot(): String =
        runCatching { Environment.getExternalStorageDirectory().absolutePath }
            .getOrDefault("/storage/emulated/0")

    private fun hasAllFilesAccess(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            runCatching { Environment.isExternalStorageManager() }.getOrDefault(false)
        } else {
            hasLegacyStorage()
        }

    private fun hasLegacyStorage(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) return hasAllFilesAccess()
        val context: Context = activity.applicationContext
        val read = context.checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE)
        val write = context.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE)
        return read == PackageManager.PERMISSION_GRANTED &&
            write == PackageManager.PERMISSION_GRANTED
    }

    /** 选择器回调:把 `content://` 树 URI 还原成绝对路径。 */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_PICK_TREE) return false
        val result = pendingResult
        pendingResult = null
        if (result == null) return true
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(null)
            return true
        }
        val uri = data.data!!
        // 持久化授权,重启后仍可访问该目录。
        runCatching {
            activity.contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
        }
        result.success(treeUriToPath(uri))
        return true
    }

    /**
     * 把 SAF 树 URI 还原成文件系统绝对路径。
     *
     * `primary:AI写作` → `<主存储根>/AI写作`;`XXXX-XXXX:dir/sub` 形式的 SD 卡卷 →
     * `/storage/XXXX-XXXX/dir/sub`。无法还原(如第三方 DocumentsProvider)时返回 null,
     * 由 Dart 侧提示用户改用「所有文件访问权限」。
     */
    private fun treeUriToPath(uri: Uri): String? {
        val docId = runCatching { android.provider.DocumentsContract.getTreeDocumentId(uri) }
            .getOrNull() ?: return null
        val parts = docId.split(':', limit = 2)
        val volume = parts.firstOrNull() ?: return null
        val relative = parts.getOrNull(1).orEmpty().trim('/')
        val root = when {
            volume.equals("primary", ignoreCase = true) -> primaryRoot()
            else -> "/storage/$volume"
        }
        val path = if (relative.isEmpty()) root else "$root/$relative"
        // 只有真实存在的目录才认为还原成功(第三方 provider 会给出无法映射的 id)。
        return if (File(path).isDirectory) path else null
    }
}