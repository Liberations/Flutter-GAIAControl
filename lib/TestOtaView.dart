import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../utils/StringUtils.dart';
import '../../../../utils/http.dart';
import 'controlller/OtaServer.dart';

class TestOtaView extends StatefulWidget {
  const TestOtaView({Key? key}) : super(key: key);

  @override
  State<TestOtaView> createState() => _TestOtaState();
}

class _TestOtaState extends State<TestOtaView> {
  var isDownloading = false;
  var progress = 0;
  var savePath = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GAIA Control Demo"),
      ),
      body: Column(
        children: [
          MaterialButton(
            color: Colors.blue,
            onPressed: () {
              _download();
            },
            child: Text("下载bin\n${!isDownloading ? "路径：$savePath" : '下载中($progress)\n路径：$savePath'}"),
          ),
          Row(
            children: [
              Text('RWCP'),
              Obx(() {
                bool rwcp = OtaServer.to.mIsRWCPEnabled.value;
                return Checkbox(
                    value: rwcp,
                    onChanged: (on) async {
                      OtaServer.to.mIsRWCPEnabled.value = on ?? false;
                      await OtaServer.to.restPayloadSize();
                      await Future.delayed(const Duration(seconds: 1));
                      if (OtaServer.to.mIsRWCPEnabled.value) {
                        OtaServer.to.writeMsg(StringUtils.hexStringToBytes("000A022E01"));
                      } else {
                        OtaServer.to.writeMsg(StringUtils.hexStringToBytes("000A022E00"));
                      }
                    });
              }),
              Expanded(
                child: MaterialButton(
                    color: Colors.blue,
                    onPressed: () {
                      OtaServer.to.logText.value = "";
                    },
                    child: Text('清空LOG')),
              ),
            ],
          ),
          Obx(() {
            final per = OtaServer.to.updatePer.value;
            return Row(
              children: [
                Expanded(child: Slider(value: per, onChanged: (data) {}, max: 100, min: 0)),
                SizedBox(width: 60, child: Text('${per.toStringAsFixed(2)}%'))
              ],
            );
          }),
          Obx(() {
            final time = OtaServer.to.timeCount.value;
            return MaterialButton(
              color: Colors.blue,
              onPressed: () async {
                if (OtaServer.to.mIsRWCPEnabled.value) {
                  await OtaServer.to.restPayloadSize();
                  await Future.delayed(const Duration(seconds: 1));
                  OtaServer.to.writeMsg(StringUtils.hexStringToBytes("000A022E01"));
                } else {
                  OtaServer.to.startUpdate();
                }
              },
              child: Text('开始升级 $time'),
            );
          }),
          MaterialButton(
            color: Colors.blue,
            onPressed: () {
              OtaServer.to.stopUpgrade();
            },
            child: const Text('取消升级'),
          ),
          Expanded(child: Obx(() {
            final log = OtaServer.to.logText.value;
            return SingleChildScrollView(
                child: Text(
              log,
              style: const TextStyle(fontSize: 10),
            ));
          }))
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    OtaServer.to.disconnect();
  }

  void _download() async {
    if (isDownloading) return;
    var url = "https://file.mymei.tv/test/1.bin";
    //url = "https://file.mymei.tv/test/M2_20221230_DEMO.bin";
    final filePath = await getApplicationDocumentsDirectory();
    final saveBinPath = filePath.path + "/1.bin";
    setState(() {
      savePath = saveBinPath;
    });
    await HttpUtil().download(url, savePath: saveBinPath, onReceiveProgress: (int count, int total) {
      setState(() {
        isDownloading = true;
        progress = count * 100.0 ~/ total;
      });
    });
    setState(() {
      isDownloading = false;
    });
  }
}
