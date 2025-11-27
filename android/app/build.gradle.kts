plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // ✅ use the correct Kotlin plugin ID
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services plugin removed - using Supabase instead of Firebase
}

android {
    namespace = "com.example.ml_smart_expense_track"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.ml_smart_expense_track"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
    // Firebase dependencies removed - using Supabase for authentication and data storage
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.2")
}

