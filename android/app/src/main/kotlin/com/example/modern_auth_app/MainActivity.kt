package com.modern_auth_app

import android.os.Bundle
import android.util.Log
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.GooglePlayServicesNotAvailableException
import com.google.android.gms.common.GooglePlayServicesRepairableException
import com.google.android.gms.security.ProviderInstaller
import com.google.firebase.FirebaseApp
import com.google.firebase.appcheck.FirebaseAppCheck
import com.google.firebase.appcheck.debug.DebugAppCheckProviderFactory
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        FirebaseApp.initializeApp(this)
        
        // Set the App Check debug token before configuring the provider
        // This ensures the debug token is available for both debug and release builds
        System.setProperty("firebase.appcheck.debug_token", "EB4958FE-A4F0-4C91-AB91-74A3C6791FA6")
        
        // Configure App Check with debug provider
        val firebaseAppCheck = FirebaseAppCheck.getInstance()
        firebaseAppCheck.installAppCheckProviderFactory(
            DebugAppCheckProviderFactory.getInstance()
        )
        
        Log.d("MainActivity", "App Check configured with debug token for manual APK distribution")
        
        super.onCreate(savedInstanceState)
        installDynamicSecurityProvider()
    }

    private fun installDynamicSecurityProvider() {
        try {
            ProviderInstaller.installIfNeeded(this)
            Log.d("MainActivity", "Security provider installed successfully.")
        } catch (e: GooglePlayServicesRepairableException) {
            Log.e("MainActivity", "Google Play Services is repairable.", e)
            // Prompt user to update Google Play Services.
            GoogleApiAvailability.getInstance().showErrorNotification(this, e.connectionStatusCode)
        } catch (e: GooglePlayServicesNotAvailableException) {
            Log.e("MainActivity", "Google Play Services not available.", e)
            // Prompt user to install Google Play Services.
            GoogleApiAvailability.getInstance().showErrorNotification(this, e.errorCode)
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to install security provider.", e)
        }
    }
}
