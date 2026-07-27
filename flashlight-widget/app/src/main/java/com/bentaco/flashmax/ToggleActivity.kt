package com.bentaco.flashmax

import android.app.Activity
import android.os.Bundle

/**
 * A no-UI launcher activity. Tapping the app icon toggles the torch at maximum
 * brightness and immediately finishes, so the icon behaves like a button too.
 */
class ToggleActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        TorchManager.get(this).toggleMax()
        FlashWidgetProvider.updateAll(this)
        finish()
    }
}
