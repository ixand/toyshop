plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // ← без version, тут уже apply true автоматично
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.frontend"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13113456"

    defaultConfig {
        applicationId = "com.example.frontend"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
    jvmTarget = "11"
    }

}

flutter {
    source = "../.."
}

dependencies {
 
    implementation("com.google.firebase:firebase-storage")
}
