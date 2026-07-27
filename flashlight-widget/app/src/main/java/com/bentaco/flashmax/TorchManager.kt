package com.bentaco.flashmax

import android.content.Context
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.Build

/**
 * Owns the camera torch and always drives it to the phone's HARDWARE MAXIMUM
 * brightness.
 *
 * The reason a normal flashlight widget looks dim is that it uses
 * [CameraManager.setTorchMode], which lights the LED at the system's *default*
 * strength level — often well below what the LED can do. On Android 13+ the
 * camera exposes a maximum strength level, and
 * [CameraManager.turnOnTorchWithStrengthLevel] lets us request exactly that.
 * That is the same ceiling the built-in flashlight button reaches, so this
 * matches the bright native torch instead of the weak default.
 */
class TorchManager private constructor(context: Context) {

    private val appContext = context.applicationContext
    private val cameraManager =
        appContext.getSystemService(Context.CAMERA_SERVICE) as CameraManager

    /** True while our torch is lit. Kept in sync via the torch callback below. */
    @Volatile
    var isOn: Boolean = false
        private set

    /** The back-facing camera id that owns the flash LED. */
    private val torchCameraId: String? by lazy { findTorchCamera() }

    /** The maximum strength level the LED supports (1 == on/off only). */
    private val maxLevel: Int by lazy { readMaxStrength() }

    init {
        // If the OS or another app changes the torch, mirror that into our state
        // and refresh any placed widgets so the icon stays correct.
        try {
            cameraManager.registerTorchCallback(
                object : CameraManager.TorchCallback() {
                    override fun onTorchModeChanged(cameraId: String, enabled: Boolean) {
                        if (cameraId == torchCameraId) {
                            isOn = enabled
                            FlashWidgetProvider.updateAll(appContext)
                        }
                    }
                },
                null
            )
        } catch (_: Exception) {
            // Torch callbacks are best-effort; state still tracks our own actions.
        }
    }

    /** Flip the torch: off -> on-at-max, on -> off. */
    fun toggleMax() {
        if (isOn) turnOff() else turnOnMax()
    }

    /** Turn the LED on at the brightest level the hardware allows. */
    fun turnOnMax() {
        val id = torchCameraId ?: return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && maxLevel > 1) {
                // Android 13+: request the true maximum strength level.
                cameraManager.turnOnTorchWithStrengthLevel(id, maxLevel)
            } else {
                // Older devices, or LEDs with a single level: plain full-on.
                cameraManager.setTorchMode(id, true)
            }
            isOn = true
        } catch (_: CameraAccessException) {
            // Camera busy (e.g. camera app open) — nothing we can do this instant.
        } catch (_: IllegalArgumentException) {
            // Strength level rejected on this device; fall back to plain on.
            runCatching {
                cameraManager.setTorchMode(id, true)
                isOn = true
            }
        }
    }

    /** Turn the LED off. */
    fun turnOff() {
        val id = torchCameraId ?: return
        runCatching {
            cameraManager.setTorchMode(id, false)
            isOn = false
        }
    }

    /** Prefer the back camera with a flash; fall back to any camera with a flash. */
    private fun findTorchCamera(): String? {
        return try {
            val ids = cameraManager.cameraIdList
            ids.firstOrNull { id ->
                val ch = cameraManager.getCameraCharacteristics(id)
                val hasFlash = ch.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
                val facing = ch.get(CameraCharacteristics.LENS_FACING)
                hasFlash && facing == CameraCharacteristics.LENS_FACING_BACK
            } ?: ids.firstOrNull { id ->
                cameraManager.getCameraCharacteristics(id)
                    .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            }
        } catch (_: CameraAccessException) {
            null
        }
    }

    /** Read the LED's maximum strength level (Android 13+); 1 elsewhere. */
    private fun readMaxStrength(): Int {
        val id = torchCameraId ?: return 1
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val ch = cameraManager.getCameraCharacteristics(id)
                ch.get(CameraCharacteristics.FLASH_INFO_STRENGTH_MAXIMUM_LEVEL) ?: 1
            } else {
                1
            }
        } catch (_: Exception) {
            1
        }
    }

    companion object {
        @Volatile
        private var instance: TorchManager? = null

        fun get(context: Context): TorchManager {
            return instance ?: synchronized(this) {
                instance ?: TorchManager(context).also { instance = it }
            }
        }
    }
}
