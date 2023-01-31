import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class StringUtils {
  final hexDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'];

  static String byteToString(List<int> list) {
    try {
      String string = const Utf8Decoder().convert(list);
      return string;
    } catch (e) {
      log("转换异常 $e");
    }
    return "";
  }

  static String byteToHexString(List<int> bytes) {
    const hexDigits = '0123456789ABCDEF';
    var charCodes = Uint8List(bytes.length * 2);
    for (var i = 0, j = 0; i < bytes.length; i++) {
      var byte = bytes[i];
      charCodes[j++] = hexDigits.codeUnitAt((byte >> 4) & 0xF);
      charCodes[j++] = hexDigits.codeUnitAt(byte & 0xF);
    }
    return String.fromCharCodes(charCodes);
  }

  static List<int> hexStringToBytes(String hexString) {
    if (hexString.length % 2 != 0) {
      hexString = "0" + hexString;
    }
    List<int> ret = [];
    for (int i = 0; i < hexString.length; i += 2) {
      var hex = hexString.substring(i, i + 2);
      ret.add(int.parse(hex, radix: 16));
    }
    return ret;
  }

  /// 用官方的crypto库同步获取md5
  static String file2md5(List<int> input) {
    return md5.convert(input).toString(); // 283M文件用时14148毫秒
  }

  static List<int> encode(String s) {
    return utf8.encode(s);
  }

  static int minToSecond(String s) {
    if (s.isEmpty || !s.contains(":")) return 0;
    return int.parse(s.split(":")[0]) * 60 + int.parse(s.split(":")[1]);
  }

  /**
   * <p>Extract an <code>int</code> value from a <code>bytes</code> array.</p>
   *
   * @param source
   *         The array to extract from.
   * @param offset
   *         Offset within source array.
   * @param length
   *         Number of bytes to use (maximum 4).
   * @param reverse
   *         True if bytes should be interpreted in reverse (little endian) order.
   *
   * @return The extracted <code>int</code>.
   */
  static int extractIntFromByteArray(List<int> source, int offset, int length, bool reverse) {
    if (length < 0 || length > 8) {
      return 0;
    }
    int result = 0;
    int shift = (length - 1) * 8;

    if (reverse) {
      for (int i = offset + length - 1; i >= offset; i--) {
        result |= ((source[i] & 0xFF) << shift);
        shift -= 8;
      }
    } else {
      for (int i = offset; i < offset + length; i++) {
        result |= ((source[i] & 0xFF) << shift);
        shift -= 8;
      }
    }
    return result;
  }


  static String intTo2HexString(int mVendorId) {
    var high = mVendorId >> 8 & 0xff;
    var low = mVendorId & 0xff;
    return byteToHexString([high, low]);
  }

  static List<int> intTo2List(int mVendorId) {
    var high = mVendorId >> 8 & 0xff;
    var low = mVendorId & 0xff;
    return [high, low];
  }

  static int byteListToInt(List<int> hex) {
    return hex[1] & 0xff | hex[0] << 8 & 0xff;
    //return int.parse(byteToHexString(hex), radix: 16);
  }
}
