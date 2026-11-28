package com.mich.oculum

import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.system.Os
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.atomic.AtomicBoolean
import java.util.zip.ZipFile

private val updateAttemptName = Regex("oculum-update-[1-9][0-9]{0,18}-[a-zA-Z0-9_-]{1,64}")
private val verifiedIncrementalName = Regex("incremental-([1-9][0-9]{0,18})-[0-9a-f]{64}\\.apk")

internal fun isIncrementalApkCandidate(relative: String): Boolean {
    val parts = relative.split(File.separatorChar)
    return parts.size >= 2 && updateAttemptName.matches(parts.first()) &&
        parts.none { it.isEmpty() || it == "." || it == ".." } &&
        parts.last().endsWith(".apk", ignoreCase = true)
}

internal fun removeInstalledIncrementalApks(cache: File, installedVersion: Long) {
    if (installedVersion <= 0) return
    val directory = File(cache.canonicalFile, "oculum-updates")
    if (directory.canonicalFile != directory || !directory.isDirectory) return
    for (file in directory.listFiles().orEmpty()) {
        val match = verifiedIncrementalName.matchEntire(file.name) ?: continue
        val version = match.groupValues[1].toLongOrNull() ?: continue
        if (version <= installedVersion && file.canonicalFile == file && file.isFile) {
            file.delete()
        }
    }
}

class MainActivity : FlutterActivity() {
    private data class ExpectedApk(val sha256: String, val versionCode: Long)

    private data class PreparedUpdate(val file: File, val expected: ExpectedApk? = null)

    private var pendingApk: PreparedUpdate? = null

    private companion object {
        val preparingUpdate = AtomicBoolean(false)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState?.getBoolean("oculum.awaitingInstallPermission") == true) {
            val sha256 = savedInstanceState.getString("oculum.pendingApkSha256")
            val expected = expectedApk(sha256, savedInstanceState.getLong("oculum.pendingApkVersion"))
            pendingApk = when {
                sha256 == null -> verifiedUpdateFile().takeIf { it.isFile }?.let { PreparedUpdate(it) }
                expected != null -> runCatching {
                    incrementalUpdateFile(expected).takeIf { it.isFile }?.let { PreparedUpdate(it, expected) }
                }.getOrNull()
                else -> null
            }
        }
        pruneInstalledIncrementalApks()
    }

    @Suppress("DEPRECATION")
    private fun pruneInstalledIncrementalApks() {
        if (pendingApk != null || !preparingUpdate.compareAndSet(false, true)) return
        Thread({
            try {
                val version = versionCode(packageManager.getPackageInfo(packageName, 0))
                removeInstalledIncrementalApks(cacheDir, version)
            } catch (error: Exception) {
                Log.w("OculumUpdate", "Could not remove already-installed APK cache entries")
            } finally {
                preparingUpdate.set(false)
            }
        }, "oculum-prune-installed-apks").start()
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putBoolean("oculum.awaitingInstallPermission", pendingApk != null)
        pendingApk?.expected?.let {
            outState.putString("oculum.pendingApkSha256", it.sha256)
            outState.putLong("oculum.pendingApkVersion", it.versionCode)
        }
    }

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, "com.mich.oculum/update").setMethodCallHandler { call, result ->
            when (call.method) {
                "installedApk" -> result.success(runCatching { installedApk() }.getOrNull())
                "installApk" -> {
                    val archivePath = call.argument<String>("archive")
                    if (archivePath.isNullOrEmpty()) {
                        result.error("UPDATE", "Pacchetto di aggiornamento mancante.", null)
                    } else {
                        prepareUpdate(result) { PreparedUpdate(prepareApk(archivePath)) }
                    }
                }
                "installIncrementalApk" -> {
                    val path = call.argument<String>("apk")
                    val version = when (val value = call.argument<Any>("versionCode")) {
                        is Int -> value.toLong()
                        is Long -> value
                        else -> 0L
                    }
                    val expected = expectedApk(call.argument<String>("sha256"), version)
                    if (path.isNullOrEmpty() || expected == null) {
                        result.error("UPDATE", "Dati dell’aggiornamento incrementale non validi.", null)
                    } else {
                        prepareUpdate(result) { prepareIncrementalApk(path, expected) }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun prepareUpdate(result: MethodChannel.Result, prepare: () -> PreparedUpdate) {
        if (pendingApk != null || !preparingUpdate.compareAndSet(false, true)) {
            result.error("UPDATE", "Installazione già in preparazione.", null)
            return
        }
        Thread({
            val prepared = runCatching(prepare)
            runOnUiThread {
                try {
                    val apk = prepared.getOrThrow()
                    check(!isFinishing && !isDestroyed) { "L’aggiornamento è stato interrotto." }
                    if (needsInstallerPermission()) {
                        pendingApk = apk
                        startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName")))
                        result.success("installer_permission_required")
                    } else {
                        launchInstaller(apk.file)
                        result.success("installer_opened")
                    }
                } catch (error: Exception) {
                    pendingApk = null
                    result.error("UPDATE", error.message, null)
                } finally {
                    preparingUpdate.set(false)
                }
            }
        }, "oculum-prepare-apk").start()
    }

    @Suppress("DEPRECATION")
    private fun installedApk(): Map<String, Any>? {
        val info = packageManager.getPackageInfo(packageName, 0)
        val app = info.applicationInfo ?: return null
        if (!info.splitNames.isNullOrEmpty() || !app.splitSourceDirs.isNullOrEmpty()) return null
        val file = File(app.sourceDir)
        if (!file.isFile || !file.canRead()) return null
        return mapOf("path" to file.absolutePath, "versionCode" to versionCode(info))
    }

    private fun expectedApk(sha256: String?, versionCode: Long): ExpectedApk? =
        sha256?.takeIf { it.matches(Regex("[0-9a-fA-F]{64}")) && versionCode > 0 }
            ?.let { ExpectedApk(it.lowercase(), versionCode) }

    private fun updateCacheDirectory(name: String): File {
        val directory = File(cacheDir.canonicalFile, name)
        require(directory.canonicalFile == directory && (directory.isDirectory || directory.mkdir())) {
            "Cartella di aggiornamento non disponibile."
        }
        return directory
    }

    private fun incrementalUpdateFile(expected: ExpectedApk): File =
        File(updateCacheDirectory("oculum-updates"), "incremental-${expected.versionCode}-${expected.sha256}.apk")

    private fun incrementalCacheSource(path: String): File {
        val canonicalCache = cacheDir.canonicalFile
        val prefix = listOf(cacheDir.absolutePath, canonicalCache.path)
            .map { it + File.separator }.firstOrNull { path.startsWith(it) }
            ?: error("L’APK da verificare deve essere nella cache di Oculum.")
        val relative = path.removePrefix(prefix)
        require(isIncrementalApkCandidate(relative)) {
            "Percorso dell’APK da verificare non valido."
        }
        val file = File(canonicalCache, relative)
        require(file.canonicalFile == file && file.isFile) {
            "APK ricostruito mancante o non valido."
        }
        return file
    }

    private fun prepareIncrementalApk(path: String, expected: ExpectedApk): PreparedUpdate {
        val source = incrementalCacheSource(path)
        val checkDirectory = updateCacheDirectory("oculum-update-check")
        val temporary = File.createTempFile("candidate-", ".apk", checkDirectory)
        try {
            // Cache sibling directories share a filesystem. Seal the candidate without a second copy.
            Os.rename(source.path, temporary.path)
            verifyIncrementalApk(temporary, expected)
            val output = incrementalUpdateFile(expected)
            require(output.canonicalFile == output && (!output.exists() || output.isFile)) {
                "Destinazione dell’APK verificato non valida."
            }
            Os.rename(temporary.path, output.path)
            return PreparedUpdate(output, expected)
        } finally {
            temporary.delete()
        }
    }

    private fun verifyIncrementalApk(apk: File, expected: ExpectedApk) {
        require(apk.canonicalFile == apk && apk.isFile) { "APK verificato non disponibile." }
        val digest = MessageDigest.getInstance("SHA-256")
        apk.inputStream().buffered().use { input ->
            val buffer = ByteArray(128 * 1024)
            while (true) {
                val read = input.read(buffer)
                if (read < 0) break
                digest.update(buffer, 0, read)
            }
        }
        val actualSha256 = digest.digest().joinToString("") { (it.toInt() and 0xff).toString(16).padStart(2, '0') }
        require(actualSha256 == expected.sha256) { "Il controllo d’integrità dell’APK non è riuscito." }
        verifyPackageIdentity(apk, expected.versionCode)
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
            verifyPackageIdentity(temporary)
            require(temporary.renameTo(output)) { "Impossibile preparare l’APK verificato." }
            return output
        } finally {
            temporary.delete()
        }
    }

    @Suppress("DEPRECATION")
    private fun verifyPackageIdentity(apk: File, expectedVersion: Long? = null) {
        val compareCurrentSigners = expectedVersion != null && Build.VERSION.SDK_INT >= 28
        val signatureFlags = if (compareCurrentSigners) {
            // Also request the older flag so framework versions requiring it parse the APK signing block.
            PackageManager.GET_SIGNING_CERTIFICATES or PackageManager.GET_SIGNATURES
        } else {
            PackageManager.GET_SIGNATURES
        }
        val installed = packageManager.getPackageInfo(packageName, signatureFlags)
        if (expectedVersion != null) {
            require(installed.splitNames.isNullOrEmpty() && installed.applicationInfo?.splitSourceDirs.isNullOrEmpty()) {
                "Questa installazione Android richiede il pacchetto completo."
            }
            require(expectedVersion > versionCode(installed)) {
                "La versione Android prevista deve essere più recente di quella installata."
            }
        }
        val candidate = packageManager.getPackageArchiveInfo(apk.path, signatureFlags)
            ?: error("Pacchetto Android illeggibile.")
        require(candidate.packageName == packageName) { "Il pacchetto Android non appartiene a Oculum." }
        val candidateSignatures = signerIds(candidate, compareCurrentSigners)
        val installedSignatures = signerIds(installed, compareCurrentSigners)
        require(!candidateSignatures.isNullOrEmpty() && candidateSignatures == installedSignatures) {
            "Firma differente: aggiornamento annullato per conservare app e salvataggi."
        }
        if (expectedVersion != null) {
            require(versionCode(candidate) == expectedVersion) { "La versione dell’APK non coincide con quella attesa." }
        } else {
            require(versionCode(candidate) >= versionCode(installed)) { "Il pacchetto Android è più vecchio della versione installata." }
        }
    }

    @Suppress("DEPRECATION")
    private fun signerIds(info: PackageInfo, compareCurrentSigners: Boolean): Set<String>? {
        val signatures = if (compareCurrentSigners && Build.VERSION.SDK_INT >= 28) {
            val signing = info.signingInfo ?: return null
            if (signing.hasMultipleSigners()) signing.apkContentsSigners?.toList()
            else signing.signingCertificateHistory?.lastOrNull()?.let { listOf(it) }
        } else {
            info.signatures?.toList()
        }
        return signatures?.map { it.toCharsString() }?.toSet()
    }

    @Suppress("DEPRECATION")
    private fun versionCode(info: PackageInfo): Long =
        if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()

    private fun needsInstallerPermission() = Build.VERSION.SDK_INT >= 26 && !packageManager.canRequestPackageInstalls()

    private fun verifiedUpdateFile() = File(cacheDir, "oculum-updates/oculum-update.apk")

    override fun onResume() {
        super.onResume()
        val apk = pendingApk ?: return
        pendingApk = null
        if (needsInstallerPermission()) return
        if (apk.expected == null) {
            try {
                launchInstaller(apk.file)
            } catch (error: Exception) {
                Log.w("OculumUpdate", "Android installer unavailable after permission confirmation")
            }
            return
        }
        if (!preparingUpdate.compareAndSet(false, true)) return
        Thread({
            val verified = runCatching { verifyIncrementalApk(apk.file, apk.expected) }
            runOnUiThread {
                try {
                    verified.getOrThrow()
                    if (!isFinishing && !isDestroyed && !needsInstallerPermission()) launchInstaller(apk.file)
                } catch (error: Exception) {
                    Log.w("OculumUpdate", "APK incremental verification or Android installer failed after permission confirmation")
                } finally {
                    preparingUpdate.set(false)
                }
            }
        }, "oculum-recheck-apk").start()
    }

    private fun launchInstaller(apk: File) {
        val uri = FileProvider.getUriForFile(this, "$packageName.updates", apk)
        startActivity(Intent(Intent.ACTION_VIEW).setDataAndType(uri, "application/vnd.android.package-archive").addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
    }
}
