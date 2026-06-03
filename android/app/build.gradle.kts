plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    
    // 1. Google Services dipindahkan ke sini menggunakan sintaks Kotlin
    id("com.google.gms.google-services") 
}

android {
    namespace = "com.example.inspectaapp"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.inspectaapp"
        
        // 2. minSdk diubah menjadi 21
        minSdk = 21 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 3. Sintaks placeholder Supabase diperbaiki ke format Kotlin
        manifestPlaceholders += mapOf("appAuthRedirectScheme" to "io.supabase.inspecta")
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

// 4. Blok dependencies ditambahkan di bagian paling bawah
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}