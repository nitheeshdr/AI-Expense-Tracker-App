import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.setupsworks.aiexpensetracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.setupsworks.aiexpensetracker"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keyAliasVal = keystoreProperties["keyAlias"] as? String
            val keyPasswordVal = keystoreProperties["keyPassword"] as? String
            val storeFileVal = keystoreProperties["storeFile"] as? String
            val storePasswordVal = keystoreProperties["storePassword"] as? String
            
            if (keyAliasVal != null && keyPasswordVal != null && storeFileVal != null && storePasswordVal != null) {
                keyAlias = keyAliasVal
                keyPassword = keyPasswordVal
                storeFile = file(storeFileVal)
                storePassword = storePasswordVal
            }
        }
    }

    buildTypes {
        release {
            val releaseConfig = signingConfigs.findByName("release")
            if (releaseConfig != null && keystorePropertiesFile.exists()) {
                signingConfig = releaseConfig
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
            // Explicit now that we ship our own proguard-rules.pro (needed
            // for the google_mlkit_text_recognition -dontwarn rules) —
            // isMinifyEnabled/isShrinkResources were previously only on by
            // Flutter's own implicit default, which doesn't pick up a
            // custom rules file.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // enableEdgeToEdge() in MainActivity — pinned explicitly rather than
    // relying on whatever version another plugin happens to pull in.
    implementation("androidx.activity:activity-ktx:1.9.3")
    // Meta Audience Network as an AdMob mediation bidding partner. Meta is
    // bidding-only (waterfall mediation was retired in 2021), so this same
    // adapter serves bidding once Meta is added as a bidding ad source in
    // the AdMob mediation groups — no app code beyond this dependency is
    // required, per Google's own mediation guide.
    implementation("com.google.ads.mediation:facebook:6.22.0.0")
}
