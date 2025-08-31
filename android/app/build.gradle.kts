plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.modern_auth_app" // Ensure this matches your actual package name
    compileSdk = 35

    ndkVersion = "27.0.12077973" // Keep your specified NDK version
    
    buildFeatures {
        buildConfig = true // Enable BuildConfig generation
    }

    compileOptions {
        // Flag to enable support for the new language APIs
        isCoreLibraryDesugaringEnabled = true // <-- ADDED for desugaring
        // Your original settings were VERSION_11, which is fine.
        // Desugaring works with Java 8+, so 11 is compatible.
        // If you encounter issues, you can try setting these to 1_8, but 11 should generally work.
        sourceCompatibility = JavaVersion.VERSION_1_8 // Changed to 1.8 for broader desugaring compatibility
        targetCompatibility = JavaVersion.VERSION_1_8 // Changed to 1.8 for broader desugaring compatibility
    }

    kotlinOptions {
        // jvmTarget should match source/targetCompatibility
        jvmTarget = JavaVersion.VERSION_1_8.toString() // Changed to "1.8"
    }

    defaultConfig {
        applicationId = "com.modern_auth_app" // Ensure this matches
        minSdk = 24 // Your current minSdk
        targetSdk = 33
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true // ADDED: Good to have, especially with many dependencies
        
        // Add App Check debug token as a build config field
        buildConfigField("String", "APP_CHECK_DEBUG_TOKEN", "\"EB4958FE-A4F0-4C91-AB91-74A3C6791FA6\"")
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // Consider enabling R8/ProGuard for release builds to shrink and obfuscate code
            // isMinifyEnabled = true
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    // It's good practice to define signingConfigs if you haven't already,
    // especially if you plan to create release builds.
    // signingConfigs {
    //     debug {
    //         // Default debug signing configuration
    //     }
    //     // create("release") {
    //     //     // Your release signing config details here
    //     //     // storeFile file("your_keystore.jks")
    //     //     // storePassword "your_store_password"
    //     //     // keyAlias "your_key_alias"
    //     //     // keyPassword "your_key_password"
    //     // }
    // }
}

flutter {
    source = "../.."
}

dependencies {
    // Import the Firebase BoM (Bill of Materials)
    // This ensures that all Firebase libraries use compatible versions.
    implementation(platform("com.google.firebase:firebase-bom:33.1.0")) // Using the version from your file, ensure it's recent

    // Add Firebase SDKs
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-messaging")
    // Add other Firebase SDKs you use, e.g., firestore, storage
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")

    // App Check dependencies
    implementation("com.google.firebase:firebase-appcheck-playintegrity")
    implementation("com.google.android.gms:play-services-safetynet:18.1.0") // SafetyNet is a fallback
    implementation("com.google.firebase:firebase-appcheck-debug:17.0.0")

    // Add the core library desugaring dependency
    // Check for the latest version: https://mvnrepository.com/artifact/com.android.tools/desugar_jdk_libs
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5") // <-- ADDED for desugaring

    // implementation("androidx.multidex:multidex:2.0.1") // Only if multiDexEnabled=true and you still face issues.
                                                       // Modern AGP usually handles multidex well.
}

