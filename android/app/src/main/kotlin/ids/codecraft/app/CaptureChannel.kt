package ids.codecraft.app

import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.security.KeyChain
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 抓包辅助：CA 证书安装引导与路径查询。
 * 实际代理/MITM 在 Dart 侧运行；Android 侧负责系统证书安装 Intent。
 */
class CaptureChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "ids.codecraft.app/capture"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "installCaCert" -> installCaCert(call.argument<String>("path"), result)
            "openSecuritySettings" -> openSecuritySettings(result)
            "requestVpnPermission" -> requestVpnPermission(result)
            "startVpn" -> startVpn(call.argument<Int>("proxyPort") ?: 8888, result)
            "stopVpn" -> stopVpn(result)
            "isVpnRunning" -> isVpnRunning(result)
            "vpnLastError" -> result.success(ProxyVpnService.lastError)
            else -> result.notImplemented()
        }
    }

    private fun requestVpnPermission(result: MethodChannel.Result) {
        val intent = VpnService.prepare(context)
        if (intent != null) {
            // 需要用户授权：保存 result，启动授权 Activity，等待 onActivityResult 回调
            if (context is MainActivity) {
                context.vpnPermissionPendingResult = result
                context.startActivityForResult(intent, MainActivity.REQUEST_VPN_PERMISSION)
            } else {
                result.success("denied")
            }
        } else {
            // 已授权
            result.success("granted")
        }
    }

    private fun startVpn(proxyPort: Int, result: MethodChannel.Result) {
        try {
            // startForegroundService 只是投递请求；由 Service 在 establish 和读取线程
            // 真正就绪后立即回调，避免启动流程固定空等 900ms。
            val requestId = ProxyVpnService.start(context, proxyPort) { started ->
                result.success(started)
            }
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                // 服务被系统拒绝启动时兜底结束等待；旧超时不会影响后一次启动。
                ProxyVpnService.timeoutStart(requestId)
            }, 5000)
        } catch (_: Exception) {
            ProxyVpnService.completeStart(false)
        }
    }

    private fun stopVpn(result: MethodChannel.Result) {
        ProxyVpnService.stop(context)
        result.success(true)
    }

    private fun isVpnRunning(result: MethodChannel.Result) {
        result.success(ProxyVpnService.isRunning)
    }

    private fun installCaCert(path: String?, result: MethodChannel.Result) {
        if (path.isNullOrEmpty()) {
            result.error("INVALID", "path is required", null)
            return
        }
        val file = File(path)
        if (!file.exists()) {
            result.error("NOT_FOUND", "CA cert not found: $path", null)
            return
        }
        try {
            val bytes = file.readBytes()
            val intent = KeyChain.createInstallIntent().apply {
                putExtra(KeyChain.EXTRA_CERTIFICATE, bytes)
                putExtra(KeyChain.EXTRA_NAME, "CodeCraft Capture CA")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("INSTALL_FAILED", e.message, null)
        }
    }

    private fun openSecuritySettings(result: MethodChannel.Result) {
        try {
            val intent = Intent(android.provider.Settings.ACTION_SECURITY_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("OPEN_FAILED", e.message, null)
        }
    }
}
