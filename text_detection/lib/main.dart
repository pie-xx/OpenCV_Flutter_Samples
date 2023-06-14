import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';  // 追加プラグインの指定
import 'package:path_provider/path_provider.dart';
void main() {
  runApp(const MaterialApp( 
    home: MyHomePage(),
    debugShowCheckedModeBanner: false, 
    ));
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String imagefile = "";  // AppBarタイトル
  Image? img;  // 画像表示Widget

  late String inpath;
  late String outpath;
  late String modelpath;

  late DynamicLibrary  dylib ;
  late Function text_detection;
  late Function rotimage;
  late Function drawarea;

  late Pointer<Int32> results;
  static const int max_result = 1024;

  @override
  void initState(){
    super.initState();
    if(Platform.isAndroid){
      dylib = DynamicLibrary.open("libOpenCV_ffi.so");
    }else
    if(Platform.isWindows){
      dylib = DynamicLibrary.open("text_detection.dll");
    }else{
      dylib = DynamicLibrary.open("libOpenCV_ffi.so");
    }

    results = malloc.allocate<Int32>(2*4*max_result+9);

    text_detection = dylib.lookupFunction<
        Void Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Int32> ),
        void Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Int32> )
        >("text_detection");
    drawarea = dylib.lookupFunction<
        Void Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Int32> ),
        void Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Int32> )
        >("drawarea");    
    rotimage = dylib.lookupFunction<
        Void Function(Pointer<Utf8>, Pointer<Utf8>, Int32),
        void Function(Pointer<Utf8>, Pointer<Utf8>, int)
        >("RotImg");
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    final tempDir = await getTemporaryDirectory();
    outpath = "${tempDir.path}/output.jpg";
    modelpath = "${tempDir.path}/DB.onnx";

    // assetsに格納したモデルを共有ライブラリが読めるようファイルに格納
    ByteData data = await rootBundle.load("assets/DB_TD500_resnet18.onnx");
    File tempFile = File(modelpath);
    await tempFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
  }

  void loadImage() async {
    var res = await FilePicker.platform.pickFiles();  // ファイル選択ダイアログ
    if( res!=null  ){
      setState(() {  // 状態変化を通知するメソッド
        imagefile = res.files[0].path ?? "";        // AppBarタイトルにファイル名セット
        img = Image.file( File( imagefile ) ); // Image Widgetに画像セット
        inpath = imagefile;
      });
    }
  }

  void detectImage() async {
    results[0] = max_result;
    text_detection( inpath.toNativeUtf8(), outpath.toNativeUtf8(), 
                      modelpath.toNativeUtf8(), results);
    if(results[0]==0){
      return;
    }
    inpath = outpath;
    print("results=${results[0]}");
    int maxX, minX, maxY, minY;
    maxX = 0; maxY = 0;
    minX = results[1];
    minY = results[2];
    for( int n=0; n < results[0]; ++n){
      print("$n(${results[n*8+1]},${results[n*8+2]})(${results[n*8+3]},${results[n*8+4]})(${results[n*8+5]},${results[n*8+6]})(${results[n*8+7]},${results[n*8+8]})");
      for( int m=0; m < 8; m=m+2 ){
        if( maxX < results[n*8+m+1]){
          maxX = results[n*8+m+1];
        }
        if( maxY < results[n*8+m+2]){
          maxY = results[n*8+m+2];
        }
        if( minX > results[n*8+m+1]){
          minX = results[n*8+m+1];
        }
        if( minY > results[n*8+m+2]){
          minY = results[n*8+m+2];
        }
      }
    }
    results[0]=1;
    results[1]=minX;
    results[2]=minY;
    results[3]=minX;
    results[4]=maxY;
    results[5]=maxX;
    results[6]=maxY;
    results[7]=maxX;
    results[8]=minY;
    drawarea( inpath.toNativeUtf8(), outpath.toNativeUtf8(), results);

    Uint8List  imageData = File(outpath).readAsBytesSync();
    img = Image.memory( imageData ); 
    setState(() { });
  }

  void drawImage() async {

    var res = await FilePicker.platform.pickFiles();  // ファイル選択ダイアログ
    if( res!=null  ){
      List<String> lines = await File(res.files[0].path ?? "").readAsLinesSync();
      int maxset = lines.length;
      results[0] = maxset;
      for( int i = 0; i < maxset; ++i){
        List<String> vals = lines[i].split(",");
        for( int n=0; n < 8; ++n ){
          results[i*8+n+1]=int.parse(vals[n]);
        }
      }

      drawarea( inpath.toNativeUtf8(), outpath.toNativeUtf8(), results);

      Uint8List  imageData = File(outpath).readAsBytesSync();
      img = Image.memory( imageData ); 
      setState(() { });
    }
  }

  void rotateImage() async {
    final outpathPointer = outpath.toNativeUtf8();
    final inpathPointer = inpath.toNativeUtf8();

    rotimage( inpathPointer, outpathPointer, 0);

    Uint8List  imageData = File(outpath).readAsBytesSync();
    img = Image.memory( imageData ); 
    inpath = outpath;
    
    setState(() { });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(imagefile),
        actions: [         // ここに並べたボタンWidgetがAppBarに並ぶ
          IconButton(onPressed: detectImage, icon: const Icon(Icons.search)),
          IconButton(onPressed: rotateImage, icon: const Icon(Icons.rotate_right)),
          IconButton(onPressed: loadImage, icon: const Icon(Icons.image)),
        ],
      ),
      body: Center(
        child:
            InteractiveViewer(
              maxScale: 64,
              child: Container( child: Center( child: 
                  img ?? Text("No Image")
              ),
            ),
      ),
    ),
    );
  }
}
