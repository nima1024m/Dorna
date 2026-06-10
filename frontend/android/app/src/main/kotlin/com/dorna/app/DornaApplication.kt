package com.dorna.app

import androidx.multidex.MultiDexApplication
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class DornaApplication : MultiDexApplication() {

    companion object {
        const val ENGINE_ID = "dorna_engine"
    }

    lateinit var flutterEngine: FlutterEngine

    override fun onCreate() {
        super.onCreate()

        // Set up a Flutter engine for the app
        flutterEngine = FlutterEngine(this)

        // Start executing Dart code in the FlutterEngine
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )

        // Cache the FlutterEngine
        FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine)
    }
}