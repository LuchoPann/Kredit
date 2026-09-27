package com.kredit.kredit

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth requires a FragmentActivity host on Android (it needs a
// FragmentManager to show the biometric prompt) — plain FlutterActivity
// crashes at runtime when authenticate() is called.
class MainActivity : FlutterFragmentActivity()
