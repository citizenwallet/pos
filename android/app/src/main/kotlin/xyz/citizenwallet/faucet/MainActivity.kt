package xyz.citizenwallet.faucet

import io.flutter.embedding.android.FlutterActivity
    import io.flutter.embedding.android.FlutterFragmentActivity
    import io.flutter.embedding.engine.FlutterEngine
    import io.flutter.plugin.common.MethodChannel
    import android.app.PendingIntent
    import android.content.Intent
    import android.nfc.NfcAdapter
import android.util.Log
import xyz.citizenwallet.nfc.NFCPlugin

class MainActivity: FlutterFragmentActivity() {
            override fun onResume() {
            super.onResume()
            val adapter: NfcAdapter? = NfcAdapter.getDefaultAdapter(this)
            val pendingIntent: PendingIntent = PendingIntent.getActivity(
                this, 0, Intent(this, javaClass).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP), PendingIntent.FLAG_IMMUTABLE)
            adapter?.enableForegroundDispatch(this, pendingIntent, null, null)
        }
        override fun onPause() {
            super.onPause()
            val adapter: NfcAdapter? = NfcAdapter.getDefaultAdapter(this)
            adapter?.disableForegroundDispatch(this)
        }

    private val CHANNEL = "xyz.citizenwallet.faucet/nfc"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        Log.d("nfc", "configureFlutterEngine")

        // Create the MethodChannel and register the Java plugin
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        NFCPlugin.registerWith(channel, this)
    }
}
