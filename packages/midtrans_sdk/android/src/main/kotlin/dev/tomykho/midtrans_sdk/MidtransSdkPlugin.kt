package dev.tomykho.midtrans_sdk

import android.app.Activity
import android.app.Application
import android.os.Bundle
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import com.midtrans.sdk.uikit.api.model.CustomColorTheme
import com.midtrans.sdk.uikit.api.model.TransactionResult
import com.midtrans.sdk.uikit.external.UiKitApi
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

/**
 * MidtransSdkPlugin
 */
class MidtransSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /** The MethodChannel that will the communication between Flutter and native Android
     *
     * This local reference serves to register the plugin with the Flutter Engine and unregister it
     * when the Flutter Engine is detached from the Activity */
    private lateinit var channel: MethodChannel
    private lateinit var activity: FlutterFragmentActivity
    private lateinit var launcher: ActivityResultLauncher<Intent>
    private var currentActivity: Activity? = null
    private var lastNonFlutterActivity: Activity? = null
    private var flutterActivityClassName: String? = null
    private var lifecycleCallbacks: Application.ActivityLifecycleCallbacks? = null

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "midtrans_sdk")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> init(call, result)
            "startPaymentUiFlow" -> startPaymentUiFlow(call, result)
            "closePaymentUiFlow" -> closePaymentUiFlow(result)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        if (this::activity.isInitialized) {
            lifecycleCallbacks?.let { activity.application.unregisterActivityLifecycleCallbacks(it) }
        }
        lifecycleCallbacks = null
        currentActivity = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity as FlutterFragmentActivity
        currentActivity = activity
        flutterActivityClassName = activity.javaClass.name
        if (lifecycleCallbacks == null) {
            lifecycleCallbacks = object : Application.ActivityLifecycleCallbacks {
                override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
                    currentActivity = activity
                    if (!isFlutterActivity(activity)) {
                        lastNonFlutterActivity = activity
                        Log.d("MidtransSDK", "activityCreated ${activity.javaClass.name}")
                    }
                }
                override fun onActivityStarted(activity: Activity) {
                    currentActivity = activity
                    if (!isFlutterActivity(activity)) {
                        lastNonFlutterActivity = activity
                        Log.d("MidtransSDK", "activityStarted ${activity.javaClass.name}")
                    }
                }
                override fun onActivityResumed(activity: Activity) {
                    currentActivity = activity
                    if (!isFlutterActivity(activity)) {
                        lastNonFlutterActivity = activity
                        Log.d("MidtransSDK", "activityResumed ${activity.javaClass.name}")
                    }
                }
                override fun onActivityPaused(activity: Activity) {}
                override fun onActivityStopped(activity: Activity) {}
                override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
                override fun onActivityDestroyed(activity: Activity) {
                    if (currentActivity === activity) {
                        currentActivity = null
                    }
                    if (lastNonFlutterActivity === activity) {
                        lastNonFlutterActivity = null
                    }
                }
            }
            activity.application.registerActivityLifecycleCallbacks(lifecycleCallbacks!!)
        }
        launcher = activity.registerForActivityResult(
            ActivityResultContracts.StartActivityForResult()
        ) { actResult ->
            if (actResult?.resultCode == Activity.RESULT_OK) {
                val data = actResult.data ?: return@registerForActivityResult
                val key = "UiKitConstants.key_transaction_result";
                val txn: TransactionResult? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    data.getParcelableExtra(key, TransactionResult::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    data.getParcelableExtra(key)
                }

                txn?.let {
                    val args = hashMapOf<String, Any?>(
                        "message" to it.message,
                        "status" to it.status,
                        "transactionId" to it.transactionId,
                        "paymentType" to it.paymentType
                    )
                    channel.invokeMethod("onTransactionFinished", args)
                }
            }
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        channel.setMethodCallHandler(null)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity as FlutterFragmentActivity
    }

    override fun onDetachedFromActivity() {
        channel.setMethodCallHandler(null)
        currentActivity = null
        lastNonFlutterActivity = null
    }

    private fun init(call: MethodCall, result: MethodChannel.Result) {
        val clientKey: String? = call.argument("clientKey")
        val merchantBaseUrl: String? = call.argument("merchantBaseUrl")
        val language: String? = call.argument("language")
        val enableLog: Boolean? = call.argument("enableLog")
        val colorTheme: Map<String, String>? = call.argument("colorTheme")

        if (clientKey != null && merchantBaseUrl != null) {
            val builder = UiKitApi.Builder()
                .withMerchantClientKey(clientKey)
                .withContext(activity)
                .withMerchantUrl(merchantBaseUrl)
                .enableLog(enableLog ?: true)

            if (!language.isNullOrBlank()) {
                val locales = LocaleListCompat.forLanguageTags(language)
                AppCompatDelegate.setApplicationLocales(locales)
            }

            colorTheme?.let { ct ->
                val colorPrimaryHex = ct["colorPrimaryHex"]
                val colorPrimaryDarkHex = ct["colorPrimaryDarkHex"]
                val colorSecondaryHex = ct["colorSecondaryHex"]
                builder.withColorTheme(
                    CustomColorTheme(
                        colorPrimaryHex,
                        colorPrimaryDarkHex,
                        colorSecondaryHex
                    )
                )
            }

            builder.build()
        }

        result.success(null)
    }

    private fun startPaymentUiFlow(call: MethodCall, result: MethodChannel.Result) {
        val token: String? = call.argument("token")
        UiKitApi.getDefaultInstance().startPaymentUiFlow(
            activity,
            launcher,
            token,
            null
        )
    }

    private fun closePaymentUiFlow(result: MethodChannel.Result) {
        val target = lastNonFlutterActivity ?: currentActivity
        val targetName = target?.javaClass?.name ?: "null"
        Log.d("MidtransSDK", "closePaymentUiFlow target=$targetName flutter=$flutterActivityClassName")
        if (target != null && !isFlutterActivity(target)) {
            target.runOnUiThread { target.finish() }
            result.success(null)
            return
        }
        if (target != null && isMidtransUiActivity(target)) {
            target.runOnUiThread { target.finish() }
            result.success(null)
            return
        }
        result.success(null)
    }

    private fun isMidtransUiActivity(activity: Activity): Boolean {
        val name = activity.javaClass.name.lowercase()
        return name.contains("midtrans") ||
            name.contains("uikit") ||
            name.contains("loadingpayment")
    }

    private fun isFlutterActivity(activity: Activity): Boolean {
        val flutterName = flutterActivityClassName
        if (flutterName == null) return false
        return activity.javaClass.name == flutterName
    }
}
