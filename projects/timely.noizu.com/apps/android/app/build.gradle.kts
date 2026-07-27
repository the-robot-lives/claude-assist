plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
    id("org.jetbrains.kotlin.plugin.serialization")
    id("com.google.devtools.ksp")
    id("com.google.dagger.hilt.android")
}

android {
    namespace = "com.noizu.timely"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.noizu.timely"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "0.1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        // Default backend. Overridable per build type / local dev.
        buildConfigField("String", "TIMELY_BASE_URL", "\"https://timely.noizu.com/\"")
        // Authentik OIDC discovery + client id for the AppAuth flow.
        buildConfigField("String", "OIDC_ISSUER", "\"https://auth.noizu.com/application/o/timely/\"")
        buildConfigField("String", "OIDC_CLIENT_ID", "\"timely-android\"")
        // EXACT-MATCH against ops' SSO_REDIRECT_ALLOWLIST. Not a prefix, not a
        // pattern -- if this string and the allow-list entry differ by one
        // character the flow fails at runtime with `redirect_not_allowed` and
        // nothing else. It is asserted by RedirectUriTest against both the
        // allow-listed literal AND the manifest's intent filter, so the value we
        // SEND and the value we are REGISTERED to receive cannot drift apart.
        buildConfigField(
            "String",
            "OIDC_REDIRECT_URI",
            "\"https://timely.noizu.com/app/auth/callback\"",
        )
    }

    buildTypes {
        debug {
            buildConfigField("String", "TIMELY_BASE_URL", "\"http://10.0.2.2:4000/\"")
        }
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    packaging {
        resources.excludes += setOf(
            "/META-INF/{AL2.0,LGPL2.1}",
            "META-INF/LICENSE.md",
            "META-INF/LICENSE-notice.md",
        )
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            isReturnDefaultValues = true
        }
    }

    // The canon() fixture suite is a shared contract artifact that must not be
    // copied (a copy silently rots). Read it from apps/shared/contracts directly.
    sourceSets {
        getByName("test") {
            resources.srcDir("${rootDir}/../shared/contracts")
        }
    }
}

kotlin {
    jvmToolchain(17)
}

ksp {
    arg("room.schemaLocation", "$projectDir/schemas")
    arg("room.generateKotlin", "true")
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2025.06.01")
    implementation(composeBom)
    androidTestImplementation(composeBom)

    // --- Compose / Material 3 ---
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.activity:activity-compose:1.10.1")
    implementation("androidx.navigation:navigation-compose:2.8.9")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.7")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    debugImplementation("androidx.compose.ui:ui-tooling")

    // --- Room (local store, the UI's source of truth) ---
    implementation("androidx.room:room-runtime:2.7.1")
    implementation("androidx.room:room-ktx:2.7.1")
    ksp("androidx.room:room-compiler:2.7.1")

    // --- Networking ---
    implementation("com.squareup.retrofit2:retrofit:2.11.0")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.8.0")
    implementation("com.jakewharton.retrofit:retrofit2-kotlinx-serialization-converter:1.0.0")

    // --- DI ---
    implementation("com.google.dagger:hilt-android:2.56.1")
    ksp("com.google.dagger:hilt-android-compiler:2.56.1")
    implementation("androidx.hilt:hilt-navigation-compose:1.2.0")
    implementation("androidx.hilt:hilt-work:1.2.0")
    ksp("androidx.hilt:hilt-compiler:1.2.0")

    // --- Background sync ---
    implementation("androidx.work:work-runtime-ktx:2.10.0")

    // --- Storage: DataStore for preferences, Jetpack Security for tokens ---
    implementation("androidx.datastore:datastore-preferences:1.1.3")
    implementation("androidx.security:security-crypto:1.1.0-alpha06")

    // --- SSO browser leg ---
    // Custom Tabs, not AppAuth. AppAuth models the app as the OAuth client
    // talking to an IdP; here Timely's server is the confidential client and
    // completes the IdP leg itself, so the app only needs to open a URL and
    // receive a redirect. Using AppAuth would have meant configuring it around a
    // token endpoint it must never call.
    implementation("androidx.browser:browser:1.8.0")

    // --- Tests ---
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.9.0")
    testImplementation("org.robolectric:robolectric:4.14.1")
    testImplementation("androidx.test:core:1.6.1")
    testImplementation("androidx.test.ext:junit:1.2.1")
    testImplementation("androidx.room:room-testing:2.7.1")
    testImplementation("com.squareup.okhttp3:mockwebserver:4.12.0")
    testImplementation("androidx.work:work-testing:2.10.0")

    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
