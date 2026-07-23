package com.teamMaster.ServiUp

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MAPS_CONFIG_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != GET_API_KEY_METHOD) {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val applicationInfo = packageManager.getApplicationInfo(
                packageName,
                PackageManager.GET_META_DATA,
            )
            result.success(applicationInfo.metaData?.getString(MAPS_API_KEY_METADATA))
        }
    }

    private companion object {
        const val MAPS_CONFIG_CHANNEL = "serviup/maps_config"
        const val GET_API_KEY_METHOD = "getApiKey"
        const val MAPS_API_KEY_METADATA = "com.google.android.geo.API_KEY"
    }
}
