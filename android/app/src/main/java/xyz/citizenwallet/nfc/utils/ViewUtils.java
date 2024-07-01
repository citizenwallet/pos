package xyz.citizenwallet.nfc.utils;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.text.InputFilter;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.Toast;

/**
 * @author qzhhh on 2021/3/18 14:10
 */
public class ViewUtils {

    public static void showRequestAmountDialog(Context context, DialogInterface.OnClickListener listener) {
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setTitle("Please input amount...");
        EditText editText = new EditText(context);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        editText.setText("000000000001");
        editText.setLayoutParams(lp);
        editText.setInputType(8194);
        editText.setFilters(new InputFilter[]{new InputFilter.LengthFilter(12)});
        builder.setView(editText);
        builder.setCancelable(false);
        builder.setPositiveButton("Confirm", listener);
    }

    public static void createInputAlertDialog(Context context, String title, String defaultValue, int inputType, IInputDialogCallback callback) {
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setTitle(title);
        EditText editText = new EditText(context);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        editText.setText(defaultValue);
        editText.setLayoutParams(lp);
        editText.setInputType(inputType);
        builder.setView(editText);
        builder.setCancelable(false);
        builder.setPositiveButton("Confirm", null);
        AlertDialog dialog = builder.create();
        dialog.show();
        dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(v -> {
            if (callback != null) {
                callback.confirm(dialog, editText.getText().toString());
            }
        });

    }

    public static void createTipAlertDialog(Context context, String title, String message, IConfirmDialogCallback callback) {
        AlertDialog.Builder builder = new AlertDialog.Builder(context)
                .setTitle(title)
                .setMessage(message)
                .setPositiveButton("Confirm", (dialog, which) -> {
                    if (callback != null) {
                        callback.onClick(dialog, true);
                    }
                })
                .setNegativeButton("Cancel", (dialog, which) -> {
                    if (callback != null) {
                        callback.onClick(dialog, false);
                    }
                });
        builder.create().show();
    }

    public static void createSelectDialog(Context context, String title, String[] message, DialogInterface.OnClickListener callback) {
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setTitle(title);
        builder.setItems(message, callback);
        builder.create().show();
    }

    public static void toast(Context context, String message) {
        Toast.makeText(context, message, Toast.LENGTH_SHORT).show();
    }

    public interface IInputDialogCallback {
        void confirm(DialogInterface dialog, String input);
    }

    public interface IConfirmDialogCallback {
        void onClick(DialogInterface dialog, boolean result);
    }
}
