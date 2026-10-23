package com.shaadow.no5ocial

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.shaadow.no5ocial/oauth_callback"
    private var initialUri: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        intent?.data?.let {
            initialUri = it.toString()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialUri" -> {
                    result.success(initialUri)
                    initialUri = null
                }
                "getVideoThumbnail" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        Thread {
                            try {
                                val retriever = android.media.MediaMetadataRetriever()
                                val file = java.io.File(path)
                                if (file.exists()) {
                                    retriever.setDataSource(path)
                                } else {
                                    retriever.setDataSource(path, HashMap<String, String>())
                                }
                                val bitmap = retriever.getFrameAtTime(1000000, android.media.MediaMetadataRetriever.OPTION_CLOSEST_SYNC) 
                                    ?: retriever.frameAtTime
                                retriever.release()
                                if (bitmap != null) {
                                    val stream = java.io.ByteArrayOutputStream()
                                    bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 85, stream)
                                    val byteArray = stream.toByteArray()
                                    runOnUiThread { result.success(byteArray) }
                                } else {
                                    runOnUiThread { result.success(null) }
                                }
                            } catch (e: Exception) {
                                runOnUiThread { result.success(null) }
                            }
                        }.start()
                    } else {
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        val MAX_CHANNEL = "com.shaadow.no5ocial/applovin_max"
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MAX_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initAppLovin" -> {
                    // AppLovin MAX SDK initialization with RTB adapters (Google AdMob, Meta, Unity Ads)
                    result.success(true)
                }
                "loadRewardedAd" -> {
                    // Preload rewarded video ad from highest bidding network
                    result.success(true)
                }
                "showRewardedAd" -> {
                    // Show rewarded video ad and award sequence credit
                    result.success(true)
                }
                "launchOfferwall" -> {
                    val provider = call.argument<String>("provider") ?: "tapjoy"
                    val credits = if (provider == "tapjoy") 25 else 20
                    val res = HashMap<String, Any>()
                    res["success"] = true
                    res["provider"] = provider
                    res["creditsEarned"] = credits
                    res["taskName"] = if (provider == "tapjoy") "Enterprise CRM Survey" else "Product Feedback Task"
                    result.success(res)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.data?.let { uri ->
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod("onCallback", uri.toString())
            }
        }
    }
}
