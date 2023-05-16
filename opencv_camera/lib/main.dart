import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ffi';
//import 'dart:isolate';

import 'package:ffi/ffi.dart';
//import 'package:path_provider/path_provider.dart';
void main() {
  runApp(const MaterialApp( home: MyHomePage(), ));
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String bar_title = "";  // AppBarタイトル
  Image? img;  // 画像表示Widget

  late String _outpath;
  late Pointer<Utf8> outpathPointer;

  late DynamicLibrary  dylib ;
  late Function cameraopen;
  late Function cameraclose;
  late Function capture;

  bool onGo = true;
  bool busy = false;
  int mode = 0;

  @override
  void initState(){
    super.initState();
    if(Platform.isWindows){
      dylib = DynamicLibrary.open("OpenCVCamera.dll");
    }else{
      dylib = DynamicLibrary.open("libOpenCVCamera.so");
    }
    cameraopen = dylib.lookupFunction<
        Void Function(),
        void Function()
        >("open");
    capture = dylib.lookupFunction<
        Void Function(Pointer<Utf8>, Int32),
        void Function(Pointer<Utf8>, int)
        >("capture");
    cameraclose = dylib.lookupFunction<
        Void Function(),
        void Function()
        >("close");
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    _outpath = "output.jpg";
    outpathPointer = _outpath.toNativeUtf8();

    cameraopen();
    Timer.periodic(const Duration(milliseconds: 100), showCapture);
  }

  void showCapture(Timer) async {
    if( busy )
      return;
    
    busy = true;
    capture( outpathPointer, mode );
    Uint8List  imageData = File(_outpath).readAsBytesSync();
    img = Image.memory( imageData ); 
    await precacheImage(img!.image, context);
    busy = false;

    setState(() { });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(bar_title),
        actions: [         // ここに並べたボタンWidgetがAppBarに並ぶ
          IconButton(onPressed: (){ 
            mode = 1; bar_title="adaptiveThreshold"; }, 
            icon: const Icon(Icons.filter_1)),
          IconButton(onPressed: (){ 
            mode = 0; bar_title="";  }, 
            icon: const Icon(Icons.filter_none)),
          Text(""),
          IconButton(onPressed: (){ 
            cameraclose(); exit(0); }, 
            icon: const Icon(Icons.close)),
        ],
      ),
      body:Center(
          child:
            InteractiveViewer(
              maxScale: 64,
              child: 
                Container(
                  child:
                    Center( child: 
                    img ?? Text("No Image")
                    ),
                )
            ),
      )
    );
  }
}
/*
  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    cameraopen();
    start_capture();
  }

  static Future<void> iso_capture( SendPort parentSendPort ) async {
    bool go = true;
    int mode = 1;
    final ReceivePort iso_receivePort = new ReceivePort("iso");
    
    iso_receivePort.listen(( message ) {
      if( message =="end"){
        go = false;
        iso_receivePort.close();
        return;
      }
      if( message =="filter_none"){
        mode=0;
        return;
      }
      if( message =="filter_1"){
        mode=1;
        return;
      }
    });
    parentSendPort.send(TransCmd("port","",iso_receivePort.sendPort));
    
    Function capture = DynamicLibrary.open("OpenCVCamera.dll").lookupFunction<
        Void Function(Pointer<Utf8>, Int32),
        void Function(Pointer<Utf8>, int)
        >("capture");

    while(go) {
      final outpathPointer = "output.jpg".toNativeUtf8();
      capture( outpathPointer, mode );
      parentSendPort!.send( TransCmd("show", "output.jpg", null) );
    }

    parentSendPort.send("end");
  }

  void start_capture()  {
    final ReceivePort receivePort = new ReceivePort("main");

    Isolate.spawn( iso_capture, receivePort.sendPort );

    // 通信側からのコールバック
    receivePort.listen(( message ) async{
      if( message.cmd =="end"){
        receivePort.close();
        cameraclose();
        return;
      }
      if( message.cmd =="port"){
        cmdsendport = message.sendport;
        return;
      }
      if( message.cmd =="show"){
      String capfile = message.msg;
      Uint8List  imageData = File(capfile).readAsBytesSync();
      img = Image.memory( imageData ); 
      await precacheImage(img!.image, context);

      setState(() { });
      }else{
        print("$message");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(imagefile),
        actions: [         // ここに並べたボタンWidgetがAppBarに並ぶ
          IconButton(onPressed: (){ 
            cmdsendport.send("filter_1"); }, 
            icon: const Icon(Icons.filter_1)),
          IconButton(onPressed: (){ 
            cmdsendport.send("filter_none"); }, 
            icon: const Icon(Icons.filter_none)),
          Text(""),
          IconButton(onPressed: (){ 
            cameraclose(); exit(0); }, 
            icon: const Icon(Icons.close)),
        ],
      ),
      body:Center(
          child:
            InteractiveViewer(
              maxScale: 64,
              child: 
                Container(
                  child:
                    Center( child: 
                    img ?? Text("No Image")
                    ),
                )
            ),
      )
    );
  }
}

class TransCmd {
  String? cmd;
  String? msg;
  SendPort? sendport;
  
  TransCmd( this.cmd, this.msg, this.sendport );
}
*/