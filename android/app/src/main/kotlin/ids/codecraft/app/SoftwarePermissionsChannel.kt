package ids.codecraft.app

import android.app.Activity
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * 「软件权限」页里没有运行时弹窗的那几项:电池优化白名单、自启动、Shizuku。
 *
 * 存储类权限不在这里:运行时部分由 [RuntimePermissionsChannel] 弹出系统授权框,
 * 全文件访问由 [ExternalStorageChannel] 跳系统设置页(Android 不为它提供应用内弹窗)。
 */
class SoftwarePermissionsChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "ids.codecraft.app/software_permissions"

        private const val SHIZUKU_PACKAGE = "moe.shizuku.privileged.api"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> result.success(
                mapOf(
                    "battery" to isIgnoringBattery(),
                    "shizuku" to isShizukuInstalled(),
                )
            )
            // 系统自己的确认弹窗。
            "requestIgnoreBattery" -> result.success(requestIgnoreBattery())
            "openAutoStart" -> result.success(openAutoStart())
            "openShizuku" -> result.success(openShizuku())
            else -> result.notImplemented()
        }
    }

    private fun isIgnoringBattery(): Boolean {
        val manager = activity.getSystemService(PowerManager::class.java) ?: return false
        return manager.isIgnoringBatteryOptimizations(activity.packageName)
    }

    /** 请求加入电池优化白名单;结果不在回调里回传,由 Dart 侧回到前台后重新查询。 */
    private fun requestIgnoreBattery(): Boolean {
        if (isIgnoringBattery()) return true
        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            .setData(Uri.parse("package:${activity.packageName}"))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return runCatching { activity.startActivity(intent) }.isSuccess
    }

    /**
     * 跳厂商的自启动管理页;没有对应页面时退到应用详情页。
     *
     * 自启动是厂商自定义能力,Android 没有统一开关,也没有可申请的权限。
     */
    private fun openAutoStart(): Boolean {
        val candidates = listOf(
            ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"),
            ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"),
            ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity"),
            ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"),
            ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity"),
            ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity"),
            ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"),
            ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity"),
            ComponentName("com.meizu.safe", "com.meizu.safe.permission.SmartBGActivity"),
            ComponentName("com.samsung.android.lool", "com.samsung.android.sm.ui.battery.BatteryActivity"),
        )
        for (component in candidates) {
            val intent = Intent().setComponent(component).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (runCatching { activity.startActivity(intent) }.isSuccess) return true
        }
        val fallback = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.parse("package:${activity.packageName}")
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return runCatching { activity.startActivity(fallback) }.isSuccess
    }

    private fun isShizukuInstalled(): Boolean = runCatching {
        activity.packageManager.getPackageInfo(SHIZUKU_PACKAGE, 0)
        true
    }.getOrDefault(false)

    /** 已装则打开 Shizuku,未装则去应用市场(无市场时退回官网)。 */
    private fun openShizuku(): Boolean {
        val intent = if (isShizukuInstalled()) {
            activity.packageManager.getLaunchIntentForPackage(SHIZUKU_PACKAGE)
                ?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        } else {
            Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$SHIZUKU_PACKAGE"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        if (intent != null && runCatching { activity.startActivity(intent) }.isSuccess) return true
        val web = Intent(Intent.ACTION_VIEW, Uri.parse("https://shizuku.rikka.app/"))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return runCatching { activity.startActivity(web) }.isSuccess
    }
}