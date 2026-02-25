import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// 릴리스 키스토어 설정 (prd flavor에서 사용)
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}
val isPrdTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("prd", ignoreCase = true)
}

if (isPrdTaskRequested && !keystorePropertiesFile.exists()) {
    throw GradleException(
        "prd 빌드에는 android/key.properties가 필요합니다. (release keystore 설정 필수)"
    )
}

android {
    namespace = "kr.sudatalk.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "kr.sudatalk.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile") ?: "")
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    flavorDimensions += "environment"
    productFlavors {
        create("local") {
            dimension = "environment"
            applicationIdSuffix = ".local"
            resValue("string", "app_name", "SUDA Local")
            signingConfig = signingConfigs.getByName("debug")
        }
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "SUDA Dev")
            signingConfig = signingConfigs.getByName("debug")
        }
        create("stg") {
            dimension = "environment"
            applicationIdSuffix = ".stg"
            resValue("string", "app_name", "SUDA Stg")
            signingConfig = signingConfigs.getByName("debug")
        }
        create("prd") {
            dimension = "environment"
            // production은 suffix 없음 (kr.sudatalk.app)
            resValue("string", "app_name", "SUDA")
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // task가 prd가 아니면 sync 편의를 위해 debug로 둔다.
                signingConfigs.getByName("debug")
            }
        }
    }

    buildTypes {
        release {}
    }
}

flutter {
    source = "../.."
}
