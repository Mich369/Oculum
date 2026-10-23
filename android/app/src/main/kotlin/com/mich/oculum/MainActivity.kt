package com.mich.oculum

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.zip.ZipFile

class MainActivity : FlutterActivity() {
    private var pendingApk: File? = null
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, "com.mich.oculum/update").setMethodCallHandler { call, result ->
            if (call.method != "installApk") { result.notImplemented(); return@setMethodCallHandler }
            try {
                val archive = File(call.argument<String>("archive") ?: error("Missing archive")).canonicalFile
                require(archive.path.startsWith(cacheDir.canonicalPath + File.separator)) { "Archive outside cache" }
                val output = File(cacheDir, "oculum-update.apk")
                ZipFile(archive).use { zip ->
                    val candidates = zip.entries().asSequence().filter { !it.isDirectory && it.name.endsWith(".apk") }.toList()
                    require(candidates.size == 1) { "Expected one APK" }
                    zip.getInputStream(candidates.single()).use { input -> output.outputStream().use { input.copyTo(it) } }
                }
                @Suppress("DEPRECATION")
                val info = packageManager.getPackageArchiveInfo(output.path, android.content.pm.PackageManager.GET_SIGNATURES)
                @Suppress("DEPRECATION")
                val installed = packageManager.getPackageInfo(packageName, android.content.pm.PackageManager.GET_SIGNATURES)
                require(info?.packageName == packageName) { "Package does not match Oculum" }
                @Suppress("DEPRECATION")
                val candidateSignatures = info?.signatures?.map { it.toCharsString() }?.toSet()
                @Suppress("DEPRECATION")
                val installedSignatures = installed.signatures?.map { it.toCharsString() }?.toSet()
                require(!candidateSignatures.isNullOrEmpty() && candidateSignatures == installedSignatures) {
                    "Firma differente: aggiornamento annullato per conservare app e salvataggi."
                }
                val candidateVersion = if (Build.VERSION.SDK_INT >= 28) info!!.longVersionCode else info!!.versionCode.toLong()
                val installedVersion = if (Build.VERSION.SDK_INT >= 28) installed.longVersionCode else installed.versionCode.toLong()
                require(candidateVersion >= installedVersion) { "Il pacchetto Android e piu vecchio della versione installata." }
                pendingApk = output
                if (Build.VERSION.SDK_INT >= 26 && !packageManager.canRequestPackageInstalls()) {
                    startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName")))
                } else { launchInstaller() }
                result.success(null)
            } catch (error: Exception) { result.error("UPDATE", error.message, null) }
        }
    }
    override fun onResume() {
        super.onResume()
        if (pendingApk != null && (Build.VERSION.SDK_INT < 26 || packageManager.canRequestPackageInstalls())) launchInstaller()
    }
    private fun launchInstaller() {
        val apk = pendingApk ?: return
        pendingApk = null
        val uri = FileProvider.getUriForFile(this, "$packageName.updates", apk)
        startActivity(Intent(Intent.ACTION_VIEW).setDataAndType(uri, "application/vnd.android.package-archive").addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
    }
}
