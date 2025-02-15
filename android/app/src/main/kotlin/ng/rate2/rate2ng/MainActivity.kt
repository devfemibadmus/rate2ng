package ng.rate2.rate2ng

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    private val CHANNEL = "ng.rate2.rate2ng"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "launchUpdate") {
                val success = launchUpdate()
                result.success(success)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun launchUpdate(): Boolean {
        val webIntent = Intent(Intent.ACTION_VIEW)
        webIntent.data = Uri.parse("https://play.google.com/store/apps/details?id=ng.rate2.rate2ng")
        startActivity(webIntent)
        return true
    }
}