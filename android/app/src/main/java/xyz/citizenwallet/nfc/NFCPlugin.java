package xyz.citizenwallet.nfc;

import android.content.Context;
import android.os.Bundle;
import android.os.RemoteException;
import android.util.Log;

import com.pos.sdk.DeviceManager;
import com.pos.sdk.DevicesFactory;
import com.pos.sdk.callback.ResultCallback;
import com.pos.sdk.mifare.MifareDevice;
import com.pos.sdk.printer.IPrinterResultListener;
import com.pos.sdk.printer.PrinterDevice;
import com.pos.sdk.printer.param.BarCodePrintItemParam;
import com.pos.sdk.printer.param.PrintItemAlign;
import com.pos.sdk.printer.param.QrPrintItemParam;
import com.pos.sdk.printer.param.TextPrintItemParam;
import com.pos.util.HexUtils;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import xyz.citizenwallet.nfc.utils.SlipModelUtils;

public class NFCPlugin implements MethodCallHandler {
    private MifareDevice mifareDevice;
    private PrinterDevice printerDevice;
    private Context context;

    public NFCPlugin(Context context) {
        this.context = context;
        Log.d("nfc", "NFCPlugin");

        DevicesFactory.create(context, new ResultCallback<DeviceManager>() {
            @Override
            public void onFinish(DeviceManager deviceManager) {
                Log.d("nfc", "onFinish getNtagDevice");
                mifareDevice = deviceManager.getMifareDevice();
                printerDevice = deviceManager.getPrintDevice();
            }

            @Override
            public void onError(int i, String s) {
                Log.d("nfc", s);
            }
        });
    }

    public static void registerWith(MethodChannel channel, Context context) {
        Log.d("nfc", "registerWith");
        NFCPlugin instance = new NFCPlugin(context);
        channel.setMethodCallHandler(instance);
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        Log.d("nfc", call.method);
        switch (call.method) {
            case "getJavaResponse":
                String response = getJavaResponse();
                if (response != null) {
                    result.success(response);
                } else {
                    result.error("UNAVAILABLE", "Response not available.", null);
                }
                break;
            case "exists":
                result.success(exists());
            case "read":
                try {
                    result.success(read());
                } catch (RemoteException e) {
                    throw new RuntimeException(e);
                }
                break;
            case "print":
                String amount = call.argument("amount");
                String symbol = call.argument("symbol");
                String description = call.argument("description");
                String link = call.argument("link");
                result.success(print(amount, symbol, description, link));
                break;
            default:
                result.notImplemented();
        }
    }

    private String getJavaResponse() {
        // Add your Java logic here
        return "Hello from Java!";
    }

    private boolean exists() {
        return mifareDevice.exists();
    }

    private String read() throws RemoteException {
        byte[] uid = readUID();

        return HexUtils.bytesToHexString(uid);
    }

    public byte[] readUID() {
        // Assuming reset() might give us a response that includes the UID
        byte[] resetResponse = mifareDevice.reset();
        if (resetResponse != null && resetResponse.length > 0) {
            // Extract UID from reset response
            // The exact method to extract the UID depends on the response format
            // This is a placeholder for the actual logic
            return extractUIDFromResetResponse(resetResponse);
        } else {
            System.err.println("Failed to reset or empty reset response.");
            return null;
        }
    }

    private byte[] extractUIDFromResetResponse(byte[] response) {
        Log.d("uid", String.valueOf(response.length));

        // Extract the UID directly from the byte array
        int uidStartIndex = 3; // Adjust index based on your actual data structure
        int uidLength = 7; // Length of the UID in bytes
        byte[] uid = new byte[uidLength];

        if (response.length < uidLength) {
            return uid;
        }

        System.arraycopy(response, uidStartIndex, uid, 0, uidLength);
        return uid;
    }

    private Object print(String amount, String symbol, String description, String link) {
        addTestData(amount, symbol, description, link);

        Bundle bundle = new Bundle();
        printerDevice.print(bundle, new IPrinterResultListener.Stub() {
            @Override
            public void onPrintFinish() throws RemoteException {
                Log.d("print", "finish");
            }

            @Override
            public void onPrintError(int errorCode, String msg) throws RemoteException {
                Log.d("print", msg);
                // showErrorMessage(String.format(Locale.US, "print failed,the error code is
                // %d,the error message is:%s", errorCode, msg));
            }
        });
        return null;
    }

    public void addQRCode(String link) {
        QrPrintItemParam qrPrintItemParam = new QrPrintItemParam();
        qrPrintItemParam.setQRCode(link);
        qrPrintItemParam.setQrWidth(200);
        qrPrintItemParam.setItemAlign(PrintItemAlign.CENTER);
        try {
            printerDevice.addQrPrintItemParam(qrPrintItemParam);
        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    public void addBarCode() {
        BarCodePrintItemParam barCodePrintItemParam = new BarCodePrintItemParam();
        barCodePrintItemParam.setBarcodeContent("1234567890123456789012345678");
        barCodePrintItemParam.setHeight(50);
        barCodePrintItemParam.setWidth(384);
        barCodePrintItemParam.setItemAlign(PrintItemAlign.CENTER);
        try {
            printerDevice.addBarCodePrintItem(barCodePrintItemParam);
        } catch (Exception e) {
            e.printStackTrace();
            // showMessage("add barcode result exception " + e.getMessage());
        }
    }

    public void addTestData(String amount, String symbol, String description, String link) {
        SimpleDateFormat formatter = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
        Date date = new Date();
        String formattedDate = formatter.format(date);

        long begin = System.currentTimeMillis();
        SlipModelUtils slip = new SlipModelUtils();
        try {
            printerDevice.addBitmapPrintItem(slip.addBitmapItem(this.context, "logo.png"));
            printerDevice.addTextPrintItem(slip.addTextOnePrint("RECEIPT", true, 32, PrintItemAlign.CENTER));
            addLineHa(slip);
            printerDevice.addTextPrintItem(slip.addTextOnePrint("MERCHANT NAME:", false, -1, PrintItemAlign.LEFT));
            printerDevice.addTextPrintItem(slip.addTextOnePrint("NFC Wallet",
                    false, -1, PrintItemAlign.LEFT));
            printerDevice
                    .addMultipleTextPrintItem(slip.addLeftAndRightItem("TRANS TIME.", formattedDate, null));
            printerDevice
                    .addMultipleTextPrintItem(slip.addLeftAndRightItem("AMOUNT", symbol + " " + amount, 32, 32, null));
            addLineHa(slip);
            printerDevice.addTextPrintItem(slip.addTextOnePrint("SIGNATURE:", false, 16, PrintItemAlign.LEFT));
            printerDevice.addBitmapPrintItem(slip.addBitmapItem(this.context, "sign.png"));
            addLineHa(slip);
            printerDevice.addTextPrintItem(slip.addTextOnePrint(
                    "I ACKNOWLEDGE SATISFACTORY RECEIPT OF RELATIVE GOODS/SERVICES", false, 16, PrintItemAlign.CENTER));
            addQRCode(link);
            printerDevice.addTextPrintItem(addLines(2));

            long end = System.currentTimeMillis();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void addLineHa(SlipModelUtils slip) throws RemoteException {
        printerDevice.addTextPrintItem(
                slip.addTextOnePrint("--------------------------------------", true, -1, PrintItemAlign.CENTER));
    }

    private TextPrintItemParam addLines(int lines) {
        StringBuffer sb = new StringBuffer();
        TextPrintItemParam t1 = new TextPrintItemParam();
        for (int i = 0; i < lines; i++) {
            sb.append("\n");
        }
        t1.setContent(sb.toString());
        return t1;
    }
}
