package com.cifravault.cifravault

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Ponte entre os intents do Android e o Flutter.
 *
 * O canal `cifravault/intents` entrega:
 * - `getInitialUrl`: URL que abriu o app (limpa após a leitura);
 * - `onShare`: URLs recebidas enquanto o app está aberto (ACTION_VIEW ou
 *   ACTION_SEND com texto contendo um link).
 */
class MainActivity : FlutterActivity() {
    private val canalNome = "cifravault/intents"
    private var linkInicial: String? = null
    private var canal: MethodChannel? = null
    private var linkPendente: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        linkInicial = extrairUrl(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, canalNome)
        canal = methodChannel
        methodChannel.setMethodCallHandler { chamada, resultado ->
            when (chamada.method) {
                "getInitialUrl" -> {
                    resultado.success(linkInicial)
                    linkInicial = null
                }
                "hasAllFilesAccess" -> resultado.success(hasAllFilesAccess())
                "requestAllFilesAccess" -> {
                    requestAllFilesAccess()
                    resultado.success(true)
                }
                "openAppSettings" -> {
                    openAppSettings()
                    resultado.success(true)
                }
                else -> resultado.notImplemented()
            }
        }

        linkPendente?.let { link ->
            entregar(link)
            linkPendente = null
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val link = extrairUrl(intent) ?: return
        if (canal != null) {
            entregar(link)
        } else {
            linkPendente = link
        }
    }

    private fun entregar(link: String) {
        canal?.invokeMethod("onShare", link)
    }

    private fun extrairUrl(intent: Intent?): String? {
        if (intent == null) return null
        return when (intent.action) {
            Intent.ACTION_VIEW -> intent.dataString
            Intent.ACTION_SEND -> {
                val texto = intent.getStringExtra(Intent.EXTRA_TEXT) ?: return null
                extrairPrimeiroLink(texto)
            }
            else -> null
        }
    }

    private fun extrairPrimeiroLink(texto: String): String? {
        val regex = Regex("""https?://[^\s]+""")
        return regex.find(texto)?.value
    }

    private fun hasAllFilesAccess(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            true
        }
    }

    private fun requestAllFilesAccess() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                intent.data = Uri.parse("package:$packageName")
                startActivity(intent)
            } catch (_: Exception) {
                try {
                    val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                    startActivity(intent)
                } catch (_: Exception) {
                    openAppSettings()
                }
            }
        } else {
            openAppSettings()
        }
    }

    private fun openAppSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
        intent.data = Uri.parse("package:$packageName")
        startActivity(intent)
    }
}
