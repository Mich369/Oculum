import java.security.KeyStore
import java.security.MessageDigest
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val oculumSigningProperties = Properties().apply {
    val propertiesFile = rootProject.file("key.properties")
    if (propertiesFile.isFile) propertiesFile.inputStream().use { load(it) }
}
fun signingValue(environment: String, property: String): String? =
    System.getenv(environment)?.takeIf { it.isNotBlank() }
        ?: oculumSigningProperties.getProperty(property)?.takeIf { it.isNotBlank() }

val oculumStorePath = signingValue("OCULUM_ANDROID_KEYSTORE_PATH", "storeFile")
val oculumStorePassword = signingValue("OCULUM_ANDROID_STORE_PASSWORD", "storePassword")
val oculumKeyPassword = signingValue("OCULUM_ANDROID_KEY_PASSWORD", "keyPassword")
val oculumKeyAlias = signingValue("OCULUM_ANDROID_KEY_ALIAS", "keyAlias")

val verifyOculumSigningIdentity = tasks.register("verifyOculumSigningIdentity") {
    doLast {
        check(oculumStorePath != null && oculumStorePassword != null &&
            oculumKeyPassword != null && oculumKeyAlias != null) {
            "Firma Android non configurata. Usa la chiave stabile Oculum tramite key.properties o OCULUM_ANDROID_*. Non generare una nuova chiave: non aggiornerebbe le installazioni esistenti."
        }
        val expected = rootProject.file("signing-certificate.sha256").readText().trim().lowercase()
        check(expected.matches(Regex("[a-f0-9]{64}"))) { "Impronta della firma Oculum non valida" }
        val store = KeyStore.getInstance(rootProject.file(oculumStorePath!!), oculumStorePassword!!.toCharArray())
        val certificate = store.getCertificate(oculumKeyAlias!!)
            ?: error("Certificato Oculum assente dal keystore configurato")
        check(store.isKeyEntry(oculumKeyAlias)) { "Chiave privata Oculum assente dal keystore configurato" }
        val actual = MessageDigest.getInstance("SHA-256").digest(certificate.encoded)
            .joinToString("") { "%02x".format(it.toInt() and 0xff) }
        check(actual == expected) {
            "Firma Android differente: build interrotta per proteggere aggiornamenti, salvataggi e accesso online. Attesa $expected, trovata $actual."
        }
    }
}

tasks.configureEach {
    if (name == "validateSigningRelease") dependsOn(verifyOculumSigningIdentity)
}

android {
    namespace = "com.mich.oculum"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mich.oculum"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("oculumRelease") {
            storeFile = oculumStorePath?.let { rootProject.file(it) }
            storePassword = oculumStorePassword
            keyAlias = oculumKeyAlias
            keyPassword = oculumKeyPassword
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("oculumRelease")
        }
    }
}

flutter {
    source = "../.."
}
