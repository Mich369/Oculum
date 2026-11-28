package com.mich.oculum

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean
import java.util.zip.ZipFile

class MainActivity : FlutterActivity() {
    private var pendingApk: File? = null
    private val preparingUpdate = AtomicBoolean(false)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState?.getBoolean("oculum.awaitingInstallPermission") == true) {
            pendingApk = verifiedUpdateFile().takeIf { it.isFile }
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putBoolean("oculum.awaitingInstallPermission", pendingApk != null)
    }

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, "com.mich.oculum/update").setMethodCallHandler { call, result ->
            if (call.method != "installApk") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val archivePath = call.argument<String>("archive")
            if (archivePath.isNullOrEmpty() || pendingApk != null || !preparingUpdate.compareAndSet(false, true)) {
                result.error("UPDATE", "Installazione già in preparazione o pacchetto mancante.", null)
                return@setMethodCallHandler
            }
            Thread({
                val prepared = runCatching { prepareApk(archivePath) }
                runOnUiThread {
                    preparingUpdate.set(false)
                    try {
                        val apk = prepared.getOrThrow()
                        if (needsInstallerPermission()) {
                            pendingApk = apk
                            startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName")))
                            result.success("installer_permission_required")
                        } else {
                            launchInstaller(apk)
                            result.success("installer_opened")
                        }
                    } catch (error: Exception) {
                        pendingApk = null
                        result.error("UPDATE", error.message, null)
                    }
                }
            }, "oculum-prepare-apk").start()
        }
    }

    @Suppress("DEPRECATION")
    private fun prepareApk(archivePath: String): File {
        val archive = File(archivePath).canonicalFile
        require(archive.path.startsWith(cacheDir.canonicalPath + File.separator)) { "Archive outside cache" }
        val directory = File(cacheDir, "oculum-updates").apply { mkdirs() }
        val output = verifiedUpdateFile()
        val temporary = File.createTempFile("candidate-", ".apk", directory)
        try {
            ZipFile(archive).use { zip ->
                val candidates = zip.entries().asSequence().filter { !it.isDirectory && it.name.endsWith(".apk") }.take(2).toList()
                require(candidates.size == 1) { "Expected one APK" }
                zip.getInputStream(candidates.single()).use { input -> temporary.outputStream().use { input.copyTo(it) } }
            }
            val signatureFlag = android.content.pm.PackageManager.GET_SIGNATURES
            val candidate = packageManager.getPackageArchiveInfo(temporary.path, signatureFlag)
                ?: error("Pacchetto Android illeggibile.")
            val installed = packageManager.getPackageInfo(packageName, signatureFlag)
            require(candidate.packageName == packageName) { "Package does not match Oculum" }
            val candidateSignatures = candidate.signatures?.map { it.toCharsString() }?.toSet()
            val installedSignatures = installed.signatures?.map { it.toCharsString() }?.toSet()
            require(!candidateSignatures.isNullOrEmpty() && candidateSignatures == installedSignatures) {
                "Firma differente: aggiornamento annullato per conservare app e salvataggi."
            }
            val candidateVersion = if (Build.VERSION.SDK_INT >= 28) candidate.longVersionCode else candidate.versionCode.toLong()
            val installedVersion = if (Build.VERSION.SDK_INT >= 28) installed.longVersionCode else installed.versionCode.toLong()
            require(candidateVersion >= installedVersion) { "Il pacchetto Android è più vecchio della versione installata." }
            require(temporary.renameTo(output)) { "Impossibile preparare l’APK verificato." }
            return output
        } finally {
            temporary.delete()
        }
    }

    private fun needsInstallerPermission() = Build.VERSION.SDK_INT >= 26 && !packageManager.canRequestPackageInstalls()

    private fun verifiedUpdateFile() = File(cacheDir, "oculum-updates/oculum-update.apk")

    override fun onResume() {
        super.onResume()
        val apk = pendingApk ?: return
        pendingApk = null
        if (!needsInstallerPermission()) {
            try {
                launchInstaller(apk)
            } catch (error: Exception) {
                Log.w("OculumUpdate", "Android installer unavailable after permission confirmation")
            }
        }
    }

    private fun launchInstaller(apk: File) {
        val uri = FileProvider.getUriForFile(this, "$packageName.updates", apk)
        startActivity(Intent(Intent.ACTION_VIEW).setDataAndType(uri, "application/vnd.android.package-archive").addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
    }
}
