import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.attune"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.attune"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        if (keystoreProperties.containsKey("FACEBOOK_APP_ID")) {
            resValue("string", "facebook_app_id", keystoreProperties.getProperty("FACEBOOK_APP_ID"))
            resValue("string", "fb_login_protocol_scheme", "fb${keystoreProperties.getProperty("FACEBOOK_APP_ID")}")
        }

        if (keystoreProperties.containsKey("FACEBOOK_CLIENT_TOKEN")) {
            resValue("string", "facebook_client_token", keystoreProperties.getProperty("FACEBOOK_CLIENT_TOKEN"))
        }

        manifestPlaceholders["facebook_app_id"] = keystoreProperties.getProperty("FACEBOOK_APP_ID") ?: ""
    }


    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-splashscreen:1.0.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation(platform("com.google.firebase:firebase-bom:34.10.0"))
    implementation("com.google.firebase:firebase-analytics")
}
