package com.serendipity.serendipity_music

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.RenderMode
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Giải phóng Splash Screen của Android 12+ ngay tức thì để không bao giờ bị đè màn hình đen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { splashScreenView ->
                splashScreenView.remove()
            }
        }
    }

    override fun getRenderMode(): RenderMode {
        return RenderMode.texture
    }
}

