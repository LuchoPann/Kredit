package com.luchopan.kredit

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth requires a FragmentActivity host on Android (it needs a
// FragmentManager to show the biometric prompt) — plain FlutterActivity
// crashes at runtime when authenticate() is called.
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Remove the Android 12+ splash exit animation to avoid a flicker
            // before Flutter draws its first frame.
            splashScreen.setOnExitAnimationListener { it.remove() }
        }
        super.onCreate(savedInstanceState)
    }
}
