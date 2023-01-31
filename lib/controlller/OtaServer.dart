import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../utils/gaia/ConfirmationType.dart';
import '../../../utils/gaia/GAIA.dart';
import '../../../utils/gaia/GaiaPacketBLE.dart';
import '../../../utils/gaia/OpCodes.dart';
import '../../../utils/gaia/ResumePoints.dart';
import '../../../utils/gaia/UpgradeStartCFMStatus.dart';
import '../../../utils/gaia/VMUPacket.dart';
import '../../../utils/gaia/rwcp/RWCPClient.dart';
import '../TestOtaView.dart';
import '../utils/StringUtils.dart';
import '../utils/gaia/rwcp/RWCPListener.dart';
import 'package:path_provider/path_provider.dart';

class OtaServer extends GetxService implements RWCPListener {
  final flutterReactiveBle = FlutterReactiveBle();
  var logText = "".obs;
  final String TAG = "OtaServer";
  var devices = <DiscoveredDevice>[].obs;
  StreamSubscription<DiscoveredDevice>? _scanConnection;

  String connectDeviceId = "";
  Uuid otaUUID = Uuid.parse("00001100-d102-11e1-9b23-00025b00a5a5");
  Uuid notifyUUID = Uuid.parse("00001102-d102-11e1-9b23-00025b00a5a5");
  Uuid writeUUID = Uuid.parse("00001101-d102-11e1-9b23-00025b00a5a5");
  Uuid writeNoResUUID = Uuid.parse("00001103-d102-11e1-9b23-00025b00a5a5");
  StreamSubscription<ConnectionStateUpdate>? _connection;

  /**
   * To know if the upgrade process is currently running.
   */
  bool isUpgrading = false;

  bool transFerComplete = false;

  /**
   * To know how many times we try to start the upgrade.
   */
  var mStartAttempts = 0;

  /**
   * The offset to use to upload data on the device.
   */
  var mStartOffset = 0;

  /**
   * The file to upload on the device.
   */
  List<int>? mBytesFile;

  List<int> writeBytes = [];

  /**
   * The maximum value for the data length of a VM upgrade packet for the data transfer step.
   */
  var mMaxLengthForDataTransfer = 16;

  var mPayloadSizeMax = 16;

  /**
   * To know if the packet with the operation code "UPGRADE_DATA" which was sent was the last packet to send.
   */
  bool wasLastPacket = false;

  int mBytesToSend = 0;

  int mResumePoint = -1;

  var mIsRWCPEnabled = false.obs;
  int sendPkgCount = 0;

  RxDouble updatePer = RxDouble(0);

  /**
   * To know if we have to disconnect after any event which occurs as a fatal error from the board.
   */
  bool hasToAbort = false;

  final writeQueue = Queue<List<int>>();

  StreamSubscription<List<int>>? _subscribeConnection;

  StreamSubscription<List<int>>? _subscribeConnectionRWCP;

  String fileMd5 = "";

  var percentage = 0.0.obs;

  Timer? _timer;

  var timeCount = 0.obs;

  //RWCP
  ListQueue<double> mProgressQueue = ListQueue();

  late RWCPClient mRWCPClient;

  int mTransferStartTime = 0;

  int writeRTCPCount = 0;

  File? file;

  static OtaServer get to => Get.find();

  @override
  void onInit() {
    super.onInit();
    mRWCPClient = RWCPClient(this);
    flutterReactiveBle.statusStream.listen((event) {
      switch (event) {
        case BleStatus.ready:
          addLog("蓝牙打开");
          break;
        case BleStatus.poweredOff:
          addLog("蓝牙关闭");
          break;
      }
    });
  }

  void connectDevice(String id) async {
    try {
      addLog('开始连接$id');
      _connection = flutterReactiveBle
          .connectToDevice(id: id, connectionTimeout: const Duration(seconds: 5))
          .listen((connectionState) async {
        if (connectionState.connectionState == DeviceConnectionState.connected) {
          connectDeviceId = id;
          addLog("连接成功" + connectDeviceId);
          //IOS BUG
          await flutterReactiveBle.discoverServices(id);
          Future.delayed(const Duration(seconds: 1)).then((value) => registerNotice());
          if (!isUpgrading) {
            Get.to(() => const TestOtaView());
          }
        } else if (connectionState.connectionState == DeviceConnectionState.disconnected) {
          addLog('断开连接');
          Future.delayed(const Duration(seconds: 5)).then((value) => connectDevice(connectDeviceId));
        } else {
          addLog('断开${connectionState.connectionState}');
        }
      });
    } catch (e) {
      addLog('开始连接失败$e');
    }
  }

  void writeMsg(List<int> data) {
    scheduleMicrotask(() async {
      await writeData(data);
    });
  }

  void registerRWCP() async {
    await _subscribeConnectionRWCP?.cancel();
    //IOS BUG
    await flutterReactiveBle.discoverServices(connectDeviceId);
    await Future.delayed(const Duration(seconds: 1));
    final characteristic =
        QualifiedCharacteristic(serviceId: otaUUID, characteristicId: writeNoResUUID, deviceId: connectDeviceId);
    _subscribeConnectionRWCP = flutterReactiveBle.subscribeToCharacteristic(characteristic).listen((data) {
      //addLog("wenDataRec2>${StringUtils.byteToHexString(data)}");
      mRWCPClient.onReceiveRWCPSegment(data);
      // code to handle incoming data
    }, onError: (dynamic error) {
      // code to handle errors
    });
    addLog("isUpgrading$isUpgrading transFerComplete $transFerComplete");
    await Future.delayed(const Duration(seconds: 1));
    if (isUpgrading && transFerComplete) {
      transFerComplete = false;
      sendUpgradeConnect();
    } else {
      if (!isUpgrading) {
        startUpdate();
      }
    }
  }

  //注册通知
  void registerNotice() async {
    await _subscribeConnection?.cancel();
    //IOS需要先发现否则订阅失败
    await flutterReactiveBle.discoverServices(connectDeviceId);
    await Future.delayed(const Duration(seconds: 1));
    final characteristic =
        QualifiedCharacteristic(serviceId: otaUUID, characteristicId: notifyUUID, deviceId: connectDeviceId);
    _subscribeConnection = flutterReactiveBle.subscribeToCharacteristic(characteristic).listen((data) {
      addLog("收到通知>${StringUtils.byteToHexString(data)}");
      handleRecMsg(data);
      // code to handle incoming data
    }, onError: (dynamic error) {
      // code to handle errors
    });
    await Future.delayed(const Duration(seconds: 1));
    GaiaPacketBLE packet =
        GaiaPacketBLE.buildGaiaNotificationPacket(GAIA.COMMAND_REGISTER_NOTIFICATION, GAIA.VMU_PACKET, null, GAIA.BLE);
    writeMsg(packet.getBytes());
    //如果开启RWCP那么需要在重连之后启用RWCP
    if (isUpgrading && transFerComplete && mIsRWCPEnabled.value) {
      //开启RWCP
      await Future.delayed(const Duration(seconds: 1));
      writeMsg(StringUtils.hexStringToBytes("000A022E01"));
    }
  }

  void startUpdate() async {
    logText.value = "";
    writeBytes.clear();
    writeRTCPCount = 0;
    mProgressQueue.clear();
    mTransferStartTime = 0;
    timeCount.value = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      timeCount.value += 1;
    });
    sendPkgCount = 0;
    updatePer.value = 0;
    isUpgrading = false;
    writeQueue.clear();
    resetUpload();
    //registerNotice();
    sendUpgradeConnect();
    //startUpgradeProcess();
  }

  void handleRecMsg(List<int> data) async {
    GaiaPacketBLE packet = GaiaPacketBLE.fromByte(data) ?? GaiaPacketBLE(0);
    if (packet.isAcknowledgement()) {
      int status = packet.getStatus();
      if (status == GAIA.SUCCESS) {
        receiveSuccessfulAcknowledgement(packet);
      } else {
        receiveUnsuccessfulAcknowledgement(packet);
      }
    } else if (packet.getCommand() == GAIA.COMMAND_EVENT_NOTIFICATION) {
      final payload = packet.mPayload ?? [];
      //000AC0010012
      if (payload.isNotEmpty) {
        int event = packet.getEvent();
        if (event == GAIA.VMU_PACKET) {
          createAcknowledgmentRequest();
          await Future.delayed(const Duration(milliseconds: 1000));
          receiveVMUPacket(payload.sublist(1));
          return;
        } else {
          // not supported
          return;
        }
      } else {
        createAcknowledgmentRequest();
        await Future.delayed(const Duration(milliseconds: 1000));
        return;
      }
    }
  }

  void receiveSuccessfulAcknowledgement(GaiaPacketBLE packet) {
    addLog("receiveSuccessfulAcknowledgement ${StringUtils.intTo2HexString(packet.getCommand())}");
    switch (packet.getCommand()) {
      case GAIA.COMMAND_VM_UPGRADE_CONNECT:
        {
          if (isUpgrading) {
            resetUpload();
            sendSyncReq();
          } else {
            int size = mPayloadSizeMax;
            if (mIsRWCPEnabled.value) {
              size = mPayloadSizeMax - 1;
              size = (size % 2 == 0) ? size : size - 1;
            }
            mMaxLengthForDataTransfer = size - VMUPacket.REQUIRED_INFORMATION_LENGTH;
            addLog("mMaxLengthForDataTransfer $mMaxLengthForDataTransfer mPayloadSizeMax $mPayloadSizeMax");
            //开始发送升级包
            startUpgradeProcess();
          }
        }
        break;
      case GAIA.COMMAND_VM_UPGRADE_DISCONNECT:
        stopUpgrade();
        break;
      case GAIA.COMMAND_VM_UPGRADE_CONTROL:
        onSuccessfulTransmission();
        break;
      case GAIA.COMMAND_SET_DATA_ENDPOINT_MODE:
        if (mIsRWCPEnabled.value) {
          registerRWCP();
        } else {
          _subscribeConnectionRWCP?.cancel();
        }

        break;
    }
  }

  void receiveUnsuccessfulAcknowledgement(GaiaPacketBLE packet) {
    addLog("命令发送失败${StringUtils.intTo2HexString(packet.getCommand())}");
    if (packet.getCommand() == GAIA.COMMAND_VM_UPGRADE_CONNECT ||
        packet.getCommand() == GAIA.COMMAND_VM_UPGRADE_CONTROL) {
      sendUpgradeDisconnect();
    } else if (packet.getCommand() == GAIA.COMMAND_VM_UPGRADE_DISCONNECT) {
    } else if (packet.getCommand() == GAIA.COMMAND_SET_DATA_ENDPOINT_MODE ||
        packet.getCommand() == GAIA.COMMAND_GET_DATA_ENDPOINT_MODE) {
      mIsRWCPEnabled.value = false;
      onRWCPNotSupported();
    }
  }

  void startUpgradeProcess() {
    if (!isUpgrading) {
      isUpgrading = true;
      resetUpload();
      sendSyncReq();
    } else if (isUpgrading) {
      stopUpgrade();
      addLog("正在升级");
    } else {
      stopUpgrade();
      // mBytesFile == null
      addLog("升级文件不存在");
    }
  }

  /**
   * <p>To reset the file transfer.</p>
   */
  void resetUpload() {
    transFerComplete = false;
    mStartAttempts = 0;
    mBytesToSend = 0;
    mStartOffset = 0;
  }

  void stopUpgrade() async {
    _timer?.cancel();
    timeCount.value = 0;
    abortUpgrade();
    resetUpload();
    writeRTCPCount = 0;
    updatePer.value = 0;
    isUpgrading = false;
    await Future.delayed(const Duration(milliseconds: 500));
    sendUpgradeDisconnect();
  }

  void sendSyncReq() async {
    //A2305C3A9059C15171BD33F3BB08ADE4 MD5
    //000A0642130004BB08ADE4
    final filePath = await getApplicationDocumentsDirectory();
    final saveBinPath = filePath.path + "/1.bin";
    File file = File(saveBinPath);
    mBytesFile = await file.readAsBytes();
    fileMd5 = StringUtils.file2md5(mBytesFile ?? []).toUpperCase();
    addLog("读取到文件MD5$fileMd5");
    final endMd5 = StringUtils.hexStringToBytes(fileMd5.substring(24));
    VMUPacket packet = VMUPacket.get(OpCodes.UPGRADE_SYNC_REQ, data: endMd5);
    sendVMUPacket(packet, false);
  }

  /// <p>To send a VMUPacket over the defined protocol communication.</p>
  ///
  /// @param bytes
  ///              The packet to send.
  /// @param isTransferringData
  ///              True if the packet is about transferring the file data, false for any other packet.
  void sendVMUPacket(VMUPacket packet, bool isTransferringData) {
    List<int> bytes = packet.getBytes();
    if (isTransferringData && mIsRWCPEnabled.value) {
      final packet = GaiaPacketBLE(GAIA.COMMAND_VM_UPGRADE_CONTROL, mPayload: bytes);
      try {
        List<int> bytes = packet.getBytes();
        if (mTransferStartTime <= 0) {
          mTransferStartTime = DateTime.now().millisecond;
        }
        bool success = mRWCPClient.sendData(bytes);
        if (!success) {
          addLog("Fail to send GAIA packet for GAIA command: ${packet.getCommandId()}");
        }
      } catch (e) {
        addLog("Exception when attempting to create GAIA packet: " + e.toString());
      }
    } else {
      final pkg = GaiaPacketBLE(GAIA.COMMAND_VM_UPGRADE_CONTROL, mPayload: bytes);
      writeMsg(pkg.getBytes());
    }
  }

  void receiveVMUPacket(List<int> data) {
    try {
      final packet = VMUPacket.getPackageFromByte(data);
      if (isUpgrading || packet!.mOpCode == OpCodes.UPGRADE_ABORT_CFM) {
        handleVMUPacket(packet);
      } else {
        addLog("receiveVMUPacket Received VMU packet while application is not upgrading anymore, opcode received");
      }
    } catch (e) {
      addLog("receiveVMUPacket $e");
    }
  }

  ///创建回包
  void createAcknowledgmentRequest() {
    writeMsg(StringUtils.hexStringToBytes("000AC00300"));
  }

  void handleVMUPacket(VMUPacket? packet) {
    switch (packet?.mOpCode) {
      case OpCodes.UPGRADE_SYNC_CFM:
        receiveSyncCFM(packet);
        break;
      case OpCodes.UPGRADE_START_CFM:
        receiveStartCFM(packet);
        break;
      case OpCodes.UPGRADE_DATA_BYTES_REQ:
        receiveDataBytesREQ(packet);
        break;
      case OpCodes.UPGRADE_ABORT_CFM:
        receiveAbortCFM();
        break;
      case OpCodes.UPGRADE_ERROR_WARN_IND:
        receiveErrorWarnIND(packet);
        break;
      case OpCodes.UPGRADE_IS_VALIDATION_DONE_CFM:
        receiveValidationDoneCFM(packet);
        break;
      case OpCodes.UPGRADE_TRANSFER_COMPLETE_IND:
        receiveTransferCompleteIND();
        break;
      case OpCodes.UPGRADE_COMMIT_REQ:
        receiveCommitREQ();
        break;
      case OpCodes.UPGRADE_COMPLETE_IND:
        receiveCompleteIND();
        break;
    }
  }

  void sendUpgradeConnect() async {
    GaiaPacketBLE packet = GaiaPacketBLE(GAIA.COMMAND_VM_UPGRADE_CONNECT);
    writeMsg(packet.getBytes());
  }

  void cancelNotification() async {
    GaiaPacketBLE packet =
        GaiaPacketBLE.buildGaiaNotificationPacket(GAIA.COMMAND_CANCEL_NOTIFICATION, GAIA.VMU_PACKET, null, GAIA.BLE);
    writeMsg(packet.getBytes());
  }

  void sendUpgradeDisconnect() {
    GaiaPacketBLE packet = GaiaPacketBLE(GAIA.COMMAND_VM_UPGRADE_DISCONNECT);
    writeMsg(packet.getBytes());
  }

  void receiveSyncCFM(VMUPacket? packet) {
    List<int> data = packet?.mData ?? [];
    if (data.length >= 6) {
      int step = data[0];
      addLog("上次传输步骤 step $step");
      if (step == ResumePoints.IN_PROGRESS) {
        setResumePoint(step);
      } else {
        mResumePoint = step;
      }
    } else {
      mResumePoint = ResumePoints.DATA_TRANSFER;
    }
    sendStartReq();
  }

  /**
   * To send an UPGRADE_START_REQ message.
   */
  void sendStartReq() {
    VMUPacket packet = VMUPacket.get(OpCodes.UPGRADE_START_REQ);
    sendVMUPacket(packet, false);
  }

  void receiveStartCFM(VMUPacket? packet) {
    List<int> data = packet?.mData ?? [];
    if (data.length >= 3) {
      if (data[0] == UpgradeStartCFMStatus.SUCCESS) {
        mStartAttempts = 0;
        // the device is ready for the upgrade, we can go to the resume point or to the upgrade beginning.
        switch (mResumePoint) {
          case ResumePoints.COMMIT:
            askForConfirmation(ConfirmationType.COMMIT);
            break;
          case ResumePoints.TRANSFER_COMPLETE:
            askForConfirmation(ConfirmationType.TRANSFER_COMPLETE);
            break;
          case ResumePoints.IN_PROGRESS:
            askForConfirmation(ConfirmationType.IN_PROGRESS);
            break;
          case ResumePoints.VALIDATION:
            sendValidationDoneReq();
            break;
          case ResumePoints.DATA_TRANSFER:
          default:
            sendStartDataReq();
            break;
        }
      }
    }
  }

  void receiveAbortCFM() {
    addLog("receiveAbortCFM");
    stopUpgrade();
  }

  void receiveErrorWarnIND(VMUPacket? packet) async {
    List<int> data = packet?.mData ?? [];
    sendErrorConfirmation(data); //
    int returnCode = StringUtils.extractIntFromByteArray(data, 0, 2, false);
    //A2305C3A9059C15171BD33F3BB08ADE4
    addLog("receiveErrorWarnIND 升级失败 错误码0x${returnCode.toRadixString(16)} fileMd5$fileMd5");
    //noinspection IfCanBeSwitch
    if (returnCode == 0x81) {
      addLog("包不通过");
      askForConfirmation(ConfirmationType.WARNING_FILE_IS_DIFFERENT);
    } else if (returnCode == 0x21) {
      addLog("电量过低");
      askForConfirmation(ConfirmationType.BATTERY_LOW_ON_DEVICE);
    } else {
      stopUpgrade();
    }
  }

  void receiveValidationDoneCFM(VMUPacket? packet) {
    addLog("receiveValidationDoneCFM");
    List<int> data = packet?.getBytes() ?? [];
    if (data.length == 2) {
      final time = StringUtils.extractIntFromByteArray(data, 0, 2, false);
      Future.delayed(Duration(milliseconds: time)).then((value) => sendValidationDoneReq());
    } else {
      sendValidationDoneReq();
    }
  }

  void receiveTransferCompleteIND() {
    addLog("receiveTransferCompleteIND");
    transFerComplete = true;
    setResumePoint(ResumePoints.TRANSFER_COMPLETE);
    askForConfirmation(ConfirmationType.TRANSFER_COMPLETE);
  }

  void receiveCommitREQ() {
    addLog("receiveCommitREQ");
    setResumePoint(ResumePoints.COMMIT);
    askForConfirmation(ConfirmationType.COMMIT);
  }

  void receiveCompleteIND() {
    isUpgrading = false;
    addLog("receiveCompleteIND 升级完成");
    disconnectUpgrade();
  }

  void sendValidationDoneReq() {
    VMUPacket packet = VMUPacket.get(OpCodes.UPGRADE_IS_VALIDATION_DONE_REQ);
    sendVMUPacket(packet, false);
  }

  void sendStartDataReq() {
    setResumePoint(ResumePoints.DATA_TRANSFER);
    VMUPacket packet = VMUPacket.get(OpCodes.UPGRADE_START_DATA_REQ);
    sendVMUPacket(packet, false);
  }

  void setResumePoint(int point) {
    mResumePoint = point;
  }

  void receiveDataBytesREQ(VMUPacket? packet) {
    List<int> data = packet?.mData ?? [];

    // Checking the data has the good length
    if (data.length == OpCodes.DATA_LENGTH) {
      // retrieving information from the received packet
      //REC 120300080000002400000000
      //SEND 000A064204000D0000030000FFFF0001FFFF0002
      var lengthByte = [data[0], data[1], data[2], data[3]];
      var fileByte = [data[4], data[5], data[6], data[7]];
      mBytesToSend = int.parse(StringUtils.byteToHexString(lengthByte), radix: 16);
      int fileOffset = int.parse(StringUtils.byteToHexString(fileByte), radix: 16);

      addLog(StringUtils.byteToHexString(data) + "本次发包: $fileOffset $mBytesToSend");
      // we check the value for the offset
      mStartOffset += (fileOffset > 0 && fileOffset + mStartOffset < (mBytesFile?.length ?? 0)) ? fileOffset : 0;

      // if the asked length doesn't fit with possibilities we use the maximum length we can use.
      mBytesToSend = (mBytesToSend > 0) ? mBytesToSend : 0;
      // if the requested length will look for bytes out of the array we reduce it to the remaining length.
      int remainingLength = mBytesFile?.length ?? 0 - mStartOffset;
      mBytesToSend = (mBytesToSend < remainingLength) ? mBytesToSend : remainingLength;
      if (mIsRWCPEnabled.value) {
        while (mBytesToSend > 0) {
          sendNextDataPacket();
        }
      } else {
        addLog("receiveDataBytesREQ: sendNextDataPacket");
        sendNextDataPacket();
      }
    } else {
      addLog("UpgradeError 数据传输失败");
      abortUpgrade();
    }
  }

  void abortUpgrade() {
    if (mRWCPClient.isRunningASession()) {
      mRWCPClient.cancelTransfer();
    }
    mProgressQueue.clear();
    sendAbortReq();
    isUpgrading = false;
  }

  void sendAbortReq() {
    VMUPacket packet = VMUPacket.get(OpCodes.UPGRADE_ABORT_REQ);
    sendVMUPacket(packet, false);
  }

  //主要发包逻辑
  void sendNextDataPacket() {
    if (!isUpgrading) {
      stopUpgrade();
      return;
    }
    // inform listeners about evolution
    onFileUploadProgress();
    int bytesToSend = mBytesToSend < mMaxLengthForDataTransfer - 1 ? mBytesToSend : mMaxLengthForDataTransfer - 1;
    // to know if we are sending the last data packet.
    bool lastPacket = (mBytesFile ?? []).length - mStartOffset <= bytesToSend;
    if (lastPacket) {
      addLog("mMaxLengthForDataTransfer$mMaxLengthForDataTransfer bytesToSend$bytesToSend lastPacket$lastPacket");
    }
    List<int> dataToSend = [];
    for (int i = 0; i < bytesToSend; i++) {
      dataToSend.add((mBytesFile ?? [])[mStartOffset + i]);
    }

    if (lastPacket) {
      wasLastPacket = true;
      mBytesToSend = 0;
    } else {
      mStartOffset += bytesToSend;
      mBytesToSend -= bytesToSend;
    }

    sendData(lastPacket, dataToSend);
  }

  //计算进度
  void onFileUploadProgress() {
    double percentage = (mStartOffset * 100.0 / (mBytesFile ?? []).length);
    percentage = (percentage < 0)
        ? 0
        : (percentage > 100)
            ? 100
            : percentage;
    if (mIsRWCPEnabled.value) {
      mProgressQueue.add(percentage);
    } else {
      updatePer.value = percentage;
    }
  }

  void sendData(bool lastPacket, List<int> data) {
    List<int> dataToSend = [];
    dataToSend.add(lastPacket ? 0x01 : 0x00);
    dataToSend.addAll(data);
    sendPkgCount++;
    VMUPacket packet = VMUPacket.get(OpCodes.UPGRADE_DATA, data: dataToSend);
    sendVMUPacket(packet, true);
  }

  void onSuccessfulTransmission() {
    if (wasLastPacket) {
      if (mResumePoint == ResumePoints.DATA_TRANSFER) {
        wasLastPacket = false;
        setResumePoint(ResumePoints.VALIDATION);
        sendValidationDoneReq();
      }
    } else if (hasToAbort) {
      hasToAbort = false;
      abortUpgrade();
    } else {
      if (mBytesToSend > 0 && mResumePoint == ResumePoints.DATA_TRANSFER && !mIsRWCPEnabled.value) {
        sendNextDataPacket();
      }
    }
  }

  void onRWCPNotSupported() {
    addLog("RWCP onRWCPNotSupported");
  }

  void askForConfirmation(int type) {
    int code = -1;
    switch (type) {
      case ConfirmationType.COMMIT:
        {
          code = OpCodes.UPGRADE_COMMIT_CFM;
        }
        break;
      case ConfirmationType.IN_PROGRESS:
        {
          code = OpCodes.UPGRADE_IN_PROGRESS_RES;
        }
        break;
      case ConfirmationType.TRANSFER_COMPLETE:
        {
          code = OpCodes.UPGRADE_TRANSFER_COMPLETE_RES;
        }
        break;
      case ConfirmationType.BATTERY_LOW_ON_DEVICE:
        {
          sendSyncReq();
        }
        return;
      case ConfirmationType.WARNING_FILE_IS_DIFFERENT:
        {
          stopUpgrade();
        }
        return;
    }
    addLog("askForConfirmation ConfirmationType type $type $code");
    VMUPacket packet = VMUPacket.get(code, data: [0]);
    sendVMUPacket(packet, false);
  }

  void sendErrorConfirmation(List<int> data) {
    VMUPacket packet = VMUPacket.get(OpCodes.UPGRADE_ERROR_WARN_RES, data: data);
    sendVMUPacket(packet, false);
  }

  void disconnectUpgrade() {
    cancelNotification();
    sendUpgradeDisconnect();
  }

  @override
  void onTransferFailed() {
    abortUpgrade();
  }

  @override
  void onTransferFinished() {
    onSuccessfulTransmission();
    mProgressQueue.clear();
  }

  @override
  void onTransferProgress(int acknowledged) {
    if (acknowledged > 0) {
      double percentage = 0;
      while (acknowledged > 0 && mProgressQueue.isNotEmpty) {
        percentage = mProgressQueue.removeFirst();
        acknowledged--;
      }
      if (mIsRWCPEnabled.value) {
        updatePer.value = percentage;
      }
      // addLog("$mIsRWCPEnabled 升级进度$percentage");
    }
  }

  @override
  bool sendRWCPSegment(List<int> bytes) {
    writeMsgRWCP(bytes);
    return true;
  }

  //一般命令写入通道
  Future<void> writeData(List<int> data) async {
    addLog("${DateTime.now()} wenDataWrite start>${StringUtils.byteToHexString(data)}");
    await Future.delayed(const Duration(milliseconds: 100));
    final characteristic =
        QualifiedCharacteristic(serviceId: otaUUID, characteristicId: writeUUID, deviceId: connectDeviceId);
    await flutterReactiveBle.writeCharacteristicWithResponse(characteristic, value: data);
    addLog("${DateTime.now()} wenDataWrite end>${StringUtils.byteToHexString(data)}");
  }

  //RWCP写入通道
  void writeMsgRWCP(List<int> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final characteristic =
        QualifiedCharacteristic(serviceId: otaUUID, characteristicId: writeNoResUUID, deviceId: connectDeviceId);
    await flutterReactiveBle.writeCharacteristicWithoutResponse(characteristic, value: data);
  }

  void disconnect() {
    stopUpgrade();
    _connection?.cancel();
    _subscribeConnection?.cancel();
    _subscribeConnectionRWCP?.cancel();
  }

  Future<void> restPayloadSize() async {
    int mtu = await flutterReactiveBle.requestMtu(deviceId: connectDeviceId, mtu: 256);
    if (!mIsRWCPEnabled.value) {
      mtu = 23;
    }
    int dataSize = mtu - 3;
    mPayloadSizeMax = dataSize - 4;
    addLog("协商mtu $mtu mPayloadSizeMax $mPayloadSizeMax");
  }

  void addLog(String s) {
    debugPrint("wenTest " + s);
    logText.value += s + "\n";
  }

  void startScan() async {
    devices.clear();
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
      var location = await Permission.location.status;
      var bluetooth = await Permission.bluetooth.status;
      var bluetoothScan = await Permission.bluetoothScan.status;
      var bluetoothConnect = await Permission.bluetoothConnect.status;
      if (location.isDenied) {
        addLog("location deny");
        return;
      }
      if (bluetoothScan.isDenied) {
        return;
      }
      if (bluetoothConnect.isDenied) {
        addLog("bluetoothConnect deny");
        return;
      }
    }
    try {
      await _scanConnection?.cancel();
    } catch (e) {}
    // Start scannin
    _scanConnection = flutterReactiveBle.scanForDevices(
        withServices: [], scanMode: ScanMode.lowLatency, requireLocationServicesEnabled: true).listen((device) {
      if (device.name.isNotEmpty) {
        final knownDeviceIndex = devices.indexWhere((d) => d.id == device.id);
        if (knownDeviceIndex >= 0) {
          devices[knownDeviceIndex] = device;
        } else {
          devices.add(device);
        }
      }
      //code for handling results
    });
  }
}
