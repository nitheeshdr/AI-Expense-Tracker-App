package com.setupsworks.aiexpensetracker

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

// FragmentActivity is required by local_auth (biometric prompt).
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Android 15 (API 35) draws edge-to-edge by default; calling this
        // explicitly keeps status/nav bar inset handling consistent on
        // older OS versions too, instead of relying on the deprecated
        // Window.setStatusBarColor/setNavigationBarColor path Play Console
        // flagged.
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
