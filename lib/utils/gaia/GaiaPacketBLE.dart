
import 'package:flutter/material.dart';


import '../StringUtils.dart';
import 'GAIA.dart';

class GaiaPacketBLE {
  /// <p>The vendor ID of the packet.</p>
  int mVendorId = GAIA.VENDOR_QUALCOMM;

  /// <p>This attribute contains the full command of the packet. If this packet is an acknowledgement packet, this
  /// attribute will contain the acknowledgement bit set to 1.</p>
  int mCommandId = 0;

  int getCommand() {
    return mCommandId & GAIA.COMMAND_MASK;
  }

  /// <p>The payload which contains all values for the specified command.</p> <p>If the
  /// packet is an acknowledgement packet, the first <code>byte</code> of the packet corresponds to the status of the
  /// sent command.</p>
  List<int>? mPayload;

  /// <p>The bytes which represent this packet.</p>
  List<int>? mBytes;

  GaiaPacketBLE(this.mCommandId, {this.mPayload});

  int getStatus() {
    final int STATUS_OFFSET = 0;
    final int STATUS_LENGTH = 1;

    if (!isAcknowledgement() || mPayload == null || (mPayload ?? []).length < STATUS_LENGTH) {
      return GAIA.NOT_STATUS;
    } else {
      return (mPayload ?? [0])[STATUS_OFFSET];
    }
  }

  /**
   * <p>A packet is an acknowledgement packet if its command contains the acknowledgement mask.</p>
   *
   * @return <code>true</code> if the command is an acknowledgement.
   */
  bool isAcknowledgement() {
    return (mCommandId & GAIA.ACKNOWLEDGMENT_MASK) > 0;
  }

  /**
   * <p>Gets the event found in byte zero of the payload if the packet is a notification event packet.</p>
   *
   * @return The event code according to {@link GAIA.NotificationEvents}
   */
  int getEvent() {
    final int EVENT_OFFSET = 0;
    final int EVENT_LENGTH = 1;

    if ((mCommandId & GAIA.COMMANDS_NOTIFICATION_MASK) < 1 ||
        mPayload == null ||
        (mPayload?.length ?? 0) < EVENT_LENGTH) {
      return GAIA.NOT_NOTIFICATION;
    } else {
      return (mPayload ?? [0])[EVENT_OFFSET];
    }
  }

  /**
   * <p>To get the bytes which correspond to this packet.</p>
   *
   * @return A new byte array if this packet has been created using its characteristics or the source bytes if this
   * packet has been created from a source <code>byte</code> array.
   *
   * @throws GaiaException for types:
   * <ul>
   *     <li>{@link GaiaException.Type#PAYLOAD_LENGTH_TOO_LONG}</li>
   * </ul>
   */
  List<int> getBytes() {
    if (mBytes != null) {
      return mBytes ?? [];
    } else {
      mBytes = buildBytes(mCommandId, mPayload);
      return mBytes ?? [];
    }
  }

  static GaiaPacketBLE buildGaiaNotificationPacket(int commandID, int event, List<int>? data, int type) {
    List<int> payload = [];
    payload.add(event);
    if (data != null && data.isNotEmpty) {
      payload.addAll(data);
    }

    return GaiaPacketBLE(commandID, mPayload: payload);
  }

  /**
   * <p>The maximum length for the packet payload.</p>
   * <p>The BLE data length maximum for a packet is 20.</p>
   */
  static final int MAX_PAYLOAD = 16;

  /**
   * <p>The offset for the bytes which represents the vendor id in the byte structure.</p>
   */
  static final int OFFSET_VENDOR_ID = 0;

  /**
   * <p>The number of bytes which represents the vendor id in the byte structure.</p>
   */
  static final int LENGTH_VENDOR_ID = 2;

  /**
   * <p>The offset for the bytes which represents the command id in the byte structure.</p>
   */
  static final int OFFSET_COMMAND_ID = 2;

  /**
   * <p>The number of bytes which represents the command id in the byte structure.</p>
   */
  static final int LENGTH_COMMAND_ID = 2;

  /**
   * <p>The offset for the bytes which represents the payload in the byte structure.</p>
   */
  static final int OFFSET_PAYLOAD = 4;

  /**
   * <p>The number of bytes which contains the information to identify the type of packet.</p>
   */
  static final int PACKET_INFORMATION_LENGTH = LENGTH_COMMAND_ID + LENGTH_VENDOR_ID;

  /**
   * <p>The minimum length of a packet.</p>
   */
  static final int MIN_PACKET_LENGTH = PACKET_INFORMATION_LENGTH;

  static GaiaPacketBLE? fromByte(List<int> source) {
    int payloadLength = source.length - PACKET_INFORMATION_LENGTH;
    if (payloadLength < 0) {
      debugPrint("GaiaPacketBLE fromByte error");
      return null;
    }
    int mVendorId = StringUtils.extractIntFromByteArray(source, OFFSET_VENDOR_ID, LENGTH_VENDOR_ID, false);
    int mCommandId = StringUtils.extractIntFromByteArray(source, OFFSET_COMMAND_ID, LENGTH_COMMAND_ID, false);
    var mCommandIdStr = StringUtils.intTo2HexString(mCommandId);
    debugPrint(
        "GaiaPacketBLE ${StringUtils.byteToHexString(source)} vendorId $mVendorId payloadLength$payloadLength mCommandId$mCommandId mCommandIdStr $mCommandIdStr");
    List<int> mPayload = [];
    if (payloadLength > 0) {
      mPayload.addAll(source.sublist(PACKET_INFORMATION_LENGTH));
    }
    GaiaPacketBLE gaiaPacketBLE = GaiaPacketBLE(mCommandId, mPayload: mPayload);
    gaiaPacketBLE.mBytes = source;
    return gaiaPacketBLE;
  }

  List<int> buildBytes(int commandId, List<int>? payload) {
    List<int> bytes = [];
    bytes.addAll(StringUtils.intTo2List(mVendorId));
    bytes.addAll(StringUtils.intTo2List(mCommandId));
    if (payload != null) {
      bytes.addAll(payload);
    }

    return bytes;
  }

  int getCommandId() {
    return mCommandId;
  }
}
