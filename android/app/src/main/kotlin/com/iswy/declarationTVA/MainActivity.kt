package com.iswy.declarationTVA

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    companion object {
        private const val PERMISSION_REQUEST_CODE = 1
    }

    private fun requestStoragePermissions() {
        val writePermission = Manifest.permission.WRITE_EXTERNAL_STORAGE
        val readPermission = Manifest.permission.READ_EXTERNAL_STORAGE
        val permissions = arrayOf(writePermission, readPermission)
        val permissionGranted = PackageManager.PERMISSION_GRANTED

        if (ContextCompat.checkSelfPermission(
                this,
                writePermission
            ) != permissionGranted ||
            ContextCompat.checkSelfPermission(
                this,
                readPermission
            ) != permissionGranted
        ) {
            ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST_CODE)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestStoragePermissions()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}
