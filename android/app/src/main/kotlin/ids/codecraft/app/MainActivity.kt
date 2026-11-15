package ids.codecraft.app

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/** 平台通道:提供 App 私有目录位置与设备 ABI 等平台信息。 */
class MainActivity : FlutterActivity() {
    private val channelName = "ids.codecraft.app/native_paths"
    private var vpnPermissionResult: MethodChannel.Result? = null
    var vpnPermissionPendingResult: MethodChannel.Result? = null

    /** 外部共享存储(全文件访问权限 / 目录选择器);目录选择需要回调,故挂在 Activity 上。 */
    private var externalStorage: ExternalStorageChannel? = null

    /** 首次启动的运行时权限(媒体/存储 + 通知),弹系统授权框。 */
    private var permissions: RuntimePermissionsChannel? = null

    /** 「软件权限」页:电池优化 / 自启动 / Shizuku。 */
    private var softwarePermissions: SoftwarePermissionsChannel? = null

    /** 逆向项目:把 APK 解压出来给文件面板浏览。 */
    private var apkFiles: ApkFilesChannel? = null

    /** 抓包小窗:进入画中画并在窗口上挂启停/清空动作。 */
    private var capturePip: CapturePipChannel? = null
    companion object {
        const val REQUEST_VPN_PERMISSION = 0x5678
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        externalStorage = ExternalStorageChannel(this).also {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ExternalStorageChannel.CHANNEL)
                .setMethodCallHandler(it)
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, InstalledAppsChannel.CHANNEL)
            .setMethodCallHandler(InstalledAppsChannel(this))
        apkFiles = ApkFilesChannel(this).also {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ApkFilesChannel.CHANNEL)
                .setMethodCallHandler(it)
        }
        permissions = RuntimePermissionsChannel(this).also {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RuntimePermissionsChannel.CHANNEL)
                .setMethodCallHandler(it)
        }
        softwarePermissions = SoftwarePermissionsChannel(this).also {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SoftwarePermissionsChannel.CHANNEL)
                .setMethodCallHandler(it)
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CaptureChannel.CHANNEL)
            .setMethodCallHandler(CaptureChannel(this))
        capturePip = CapturePipChannel(
            this,
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CapturePipChannel.CHANNEL),
        ).also {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CapturePipChannel.CHANNEL)
                .setMethodCallHandler(it)
        }
        // 代码编辑器 PlatformView(sora-editor):Dart 侧用 PlatformViewLink 引用 viewType "codecraft/editor"。
        flutterEngine.platformViewsController.registry
            .registerViewFactory("codecraft/editor", EditorViewFactory(flutterEngine.dartExecutor.binaryMessenger))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "nativeLibraryDir" -> result.success(applicationInfo.nativeLibraryDir)
                "filesDir" -> result.success(filesDir.absolutePath)
                "deviceAbi" -> result.success(android.os.Build.SUPPORTED_ABIS.firstOrNull() ?: "")
                "timeZoneId" -> result.success(java.util.TimeZone.getDefault().id)
                "apkSizes" -> {
                    val info = applicationInfo
                    val paths = (listOf(info.sourceDir) + (info.splitSourceDirs?.toList() ?: emptyList()))
                        .filterNotNull()
                        .distinct()
                    result.success(paths.map { java.io.File(it).length() })
                }
                "ensureDir" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        val dir = java.io.File(path)
                        val ok = if (dir.exists()) dir.isDirectory else dir.mkdirs()
                        result.success(ok)
                    } else {
                        result.error("INVALID", "path required", null)
                    }
                }
                // Termux bootstrap：状态查询与安装触发（安装流程见 BootstrapInstaller）。
                "bootstrapStatus" -> result.success(
                    mapOf(
                        "installed" to BootstrapInstaller.isInstalled(this),
                        "installing" to BootstrapInstaller.installing,
                        "stage" to BootstrapInstaller.stage,
                        "progress" to BootstrapInstaller.progress,
                        "error" to BootstrapInstaller.lastError,
                    )
                )
                "ensureBootstrap" -> BootstrapInstaller.ensureInstalledAsync(this) { ok ->
                    runOnUiThread { result.success(ok) }
                }
                "writeFile" -> {
                    val path = call.argument<String>("path")
                    val content = call.argument<String>("content")
                    if (path != null && content != null) {
                        try {
                            val f = java.io.File(path)
                            f.parentFile?.mkdirs()
                            f.writeText(content)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("WRITE_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID", "path and content required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        requested: Array<out String>,
        grantResults: IntArray
    ) {
        if (permissions?.onRequestPermissionsResult(requestCode, grantResults) == true) return
        super.onRequestPermissionsResult(requestCode, requested, grantResults)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        if (externalStorage?.onActivityResult(requestCode, resultCode, data) == true) return
        if (requestCode == REQUEST_VPN_PERMISSION) {
            val granted = resultCode == RESULT_OK
            vpnPermissionPendingResult?.success(if (granted) "granted" else "denied")
            vpnPermissionPendingResult = null
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CaptureChannel.CHANNEL).invokeMethod("vpnPermissionResult", granted)
            }
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: android.content.res.Configuration?,
    ) {
        capturePip?.onPictureInPictureModeChanged(isInPictureInPictureMode)
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
    }
}
