package xyz.citizenwallet.nfc.utils;

import com.pos.util.HexUtils;

import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.List;

/**
 * @author: shayne
 * @date: 2023/3/8
 */
public class RequestAids {
    String aid;
    String lable;
    String preferredName;
    byte prioIndicatorFlag;
    byte priority;
    String preferredLanguage;
    byte issuerCodeTableIndexFlag;
    byte issuerCodeTableIndex;

    public static List<RequestAids> parseLength41Array(byte[] dataBytes) {
        int index = 0;
        List<RequestAids> list = new ArrayList<>();

        do {
            RequestAids requestAids = new RequestAids();
            try {
                int length = dataBytes[index++] & 0xff;
                requestAids.aid = new String(dataBytes, index, length);
            } catch (Exception e) {
                requestAids.aid = null;
            }
            index += 40;
            list.add(requestAids);
        } while (index < dataBytes.length);

        return list;
    }

    public RequestAids parseLength41(byte[] dataBytes) {
        int index = 0;

        try {
            int length = dataBytes[index++] & 0xff;
            aid = new String(dataBytes, index, length);
        } catch (Exception e) {
            aid = null;
        }

        return this;
    }


    public RequestAids parseLength88(byte[] dataBytes) {
        int index = 0;

        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        int aidLength = dataBytes[index++];
        outputStream.write(dataBytes, index, aidLength);
        aid = HexUtils.bytesToHexString(outputStream.toByteArray());
        index += 20;

        int lableLength = dataBytes[index++];
        try {
            lable = new String(dataBytes, index, lableLength, "gbk");
        } catch (Exception e) {
            lable = null;
        }
        index += 20;

        int prefNameLength = dataBytes[index++];
        try {
            preferredName = new String(dataBytes, index, prefNameLength, "gbk");
        } catch (Exception e) {
            preferredName = null;
        }
        index += 20;

        prioIndicatorFlag = dataBytes[index++];
        priority = dataBytes[index++];

        int languageLength = dataBytes[index++];
        try {
            preferredLanguage = new String(dataBytes, index, languageLength, "gbk");
        } catch (Exception e) {
            preferredLanguage = null;
        }
        index += 20;
        issuerCodeTableIndexFlag = dataBytes[index++];
        issuerCodeTableIndex = dataBytes[index];

        return this;
    }


    public static List<RequestAids> parseLength88Array(byte[] dataBytes) {
        List<RequestAids> list = new ArrayList<>();
        int index = 0;

        do {
            RequestAids requestAids = new RequestAids();
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            int aidLength = dataBytes[index++];
            outputStream.write(dataBytes, index, aidLength);
            requestAids.aid = HexUtils.bytesToHexString(outputStream.toByteArray());
            index += 20;

            int lableLength = dataBytes[index++];
            try {
                requestAids.lable = new String(dataBytes, index, lableLength, "gbk");
            } catch (Exception e) {
                requestAids.lable = null;
            }
            index += 20;

            int prefNameLength = dataBytes[index++];
            try {
                requestAids.preferredName = new String(dataBytes, index, prefNameLength, "gbk");
            } catch (Exception e) {
                requestAids.preferredName = null;
            }
            index += 20;

            requestAids.prioIndicatorFlag = dataBytes[index++];
            requestAids.priority = dataBytes[index++];

            int languageLength = dataBytes[index++];
            try {
                requestAids.preferredLanguage = new String(dataBytes, index, languageLength, "gbk");
            } catch (Exception e) {
                requestAids.preferredLanguage = null;
            }
            index += 20;
            requestAids.issuerCodeTableIndexFlag = dataBytes[index++];
            requestAids.issuerCodeTableIndex = dataBytes[index++];
            list.add(requestAids);
        } while (index < dataBytes.length);

        return list;
    }

    public String getLable() {
        return lable;
    }
}
