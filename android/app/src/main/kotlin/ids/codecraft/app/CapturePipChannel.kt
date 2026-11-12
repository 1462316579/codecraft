package ids.codecraft.app

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.drawable.Icon
import android.os.Build
import android.util.Rational
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * 抓包小窗（画中画）。
 *
 * Android 只允许 Activity 自己进入画中画，窗口内容是当前 Activity 的实时界面，
 * 所以 Dart 侧在小窗模式下改成紧凑列表。窗口上的两个 RemoteAction
 * （启停代理 / 清空记录）通过广播回到这里，再转给 Dart 执行。
 */
class CapturePipChannel(
    private val activity: MainActivity,
    private val channel: MethodChannel,
) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "ids.codecraft.app/capturePip"
        private const val ACTION_TOGGLE = "ids.codecraft.app.capturePip.TOGGLE"
        private const val ACTION_CLEAR = "ids.codecraft.app.capturePip.CLEAR"
    }

    private var running = false
    private var receiverRegistered = false

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = when (intent?.action) {
                ACTION_TOGGLE -> "toggle"
                ACTION_CLEAR -> "clear"
                else -> return
            }
            channel.invokeMethod("action", action)
            if (action == "toggle") {
                running = !running
                applyParams()
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "enter" -> {
                running = call.argument<Boolean>("running") ?: false
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                    result.success(false)
                    return
                }
                registerReceiver()
                val params = applyParams()!!
                result.success(activity.enterPictureInPictureMode(params))
            }
            "updateActions" -> {
                running = call.argument<Boolean>("running") ?: running
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && activity.isInPictureInPictureMode) {
                    applyParams()
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean) {
        channel.invokeMethod("modeChanged", isInPictureInPictureMode)
    }

    private fun registerReceiver() {
        if (receiverRegistered) return
        receiverRegistered = true
        val filter = IntentFilter().apply {
            addAction(ACTION_TOGGLE)
            addAction(ACTION_CLEAR)
        }
        ContextCompat.registerReceiver(activity, receiver, filter, ContextCompat.RECEIVER_NOT_EXPORTED)
    }

    private fun applyParams(): PictureInPictureParams? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return null
        val params = PictureInPictureParams.Builder()
            .setAspectRatio(Rational(9, 16))
            .setActions(listOf(toggleAction(), clearAction()))
            .apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) setSeamlessResizeEnabled(false)
            }
            .build()
        activity.setPictureInPictureParams(params)
        return params
    }

    private fun toggleAction(): RemoteAction {
        val icon = if (running) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
        val label = if (running) "Pause" else "Start"
        return RemoteAction(
            Icon.createWithResource(activity, icon),
            label,
            label,
            pendingIntent(ACTION_TOGGLE, 0),
        )
    }

    private fun clearAction(): RemoteAction = RemoteAction(
        Icon.createWithResource(activity, android.R.drawable.ic_menu_delete),
        "Clear",
        "Clear",
        pendingIntent(ACTION_CLEAR, 1),
    )

    private fun pendingIntent(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(action).setPackage(activity.packageName)
        val flags = PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        return PendingIntent.getBroadcast(activity, requestCode, intent, flags)
    }
}
