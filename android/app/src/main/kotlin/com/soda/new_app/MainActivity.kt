package com.soda.new_app

import android.content.Intent
import android.content.Intent.getIntent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    var sharedText : String? = null
    val CHANNEL = "app.channel.shared.data"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val intent : Intent = getIntent()
        val action : String = intent.getAction()!!
        val type : String? = intent.getType()
        if(Intent.ACTION_SEND.equals(action) && type != null){
            if("text/plain".equals(type)){
                handleSendText(intent)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine : FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
        .setMethodCallHandler{
                call, result ->
            if (call.method.contentEquals("getSharedText")) {
                result.success(sharedText)
                sharedText = null
            }
        }
    }

    fun handleSendText( intent : Intent) {
        sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
    }
}
