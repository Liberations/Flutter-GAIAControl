import 'package:flutter/material.dart';

class Log {
  static bool isLog = false;

  static void i(String tag, String msg) {
    if (!isLog) return;
    debugPrint("$tag $msg");
  }

  static void d(String tag, String msg) {
    if (!isLog) return;
    debugPrint("$tag $msg");
  }

  static void e(String tag, String msg) {
    if (!isLog) return;
    debugPrint("$tag $msg");
  }

  static void w(String tag, String msg) {
    if (!isLog) return;
    debugPrint("$tag $msg");
  }
}
