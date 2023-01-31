
import 'package:flutter/cupertino.dart';

import '../StringUtils.dart';



class VMUPacket {
  /**
   * <p>The tag to display for logs.</p>
   */
  final String TAG = "VMUPacket";

  /**
   * The number of bytes to define the packet length information.
   */
  static final int LENGTH_LENGTH = 2;

  /**
   * The number of bytes to define the packet operation code information.
   */
  static final int OPCODE_LENGTH = 1;

  /**
   * The offset for the operation code information.
   */
  static final int OPCODE_OFFSET = 0;

  /**
   * The offset for the length information.
   */
  static final int LENGTH_OFFSET = OPCODE_OFFSET + OPCODE_LENGTH;

  /**
   * The offset for the data information.
   */
  static final int DATA_OFFSET = LENGTH_OFFSET + LENGTH_LENGTH;

  /**
   * The packet operation code information.
   */
  int mOpCode = -1;

  /**
   * The packet data information.
   */
  List<int>? mData;

  /**
   * The minimum length a VMU packet should have to be a VMU packet.
   */
  static final int REQUIRED_INFORMATION_LENGTH = LENGTH_LENGTH + OPCODE_LENGTH;

  static VMUPacket get(int opCode, {List<int>? data}) {
    VMUPacket vmuPacket = VMUPacket();
    vmuPacket.mOpCode = opCode;
    if (data != null) {
      vmuPacket.mData = data;
    }
    return vmuPacket;
  }

  static VMUPacket? getPackageFromByte(List<int> bytes) {
    int opCode = -1;
    if (bytes.length >= REQUIRED_INFORMATION_LENGTH) {
      opCode = bytes[0];
      //14000600BB08ADE403
      int length = StringUtils.byteListToInt([bytes[1], bytes[2]]);
      int dataLength = bytes.length - REQUIRED_INFORMATION_LENGTH;
      debugPrint("$length getPackageFromByte $dataLength");
      if (length > dataLength) {
        debugPrint("getPackageFromByte length > dataLength");
      } else if (length < dataLength) {
        debugPrint("getPackageFromByte length < dataLength");
      }
      List<int> data = bytes.sublist(3);
      return VMUPacket.get(opCode, data: data);
    }
    return null;
  }

  List<int> getBytes() {
    //000AC0010012
    List<int> packet = [];
    packet.add(mOpCode);
    packet.addAll(StringUtils.intTo2List((mData ?? []).length));
    packet.addAll(mData ?? []);
    return packet;
  }
}
