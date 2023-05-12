import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:file_picker/file_picker.dart';  // 追加プラグインの指定
import 'package:path_provider/path_provider.dart';
void main() {
  runApp(const MaterialApp( home: MyHomePage(), ));
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String imagefile = "";  // AppBarタイトル
  Image? img;  // 画像表示Widget

  late String _outpath;
  late DynamicLibrary  dylib ;
  late Function rotimage;

  @override
  void initState(){
    super.initState();
    if(Platform.isAndroid){
      dylib = DynamicLibrary.open("libOpenCV_ffi.so");
    }else
    if(Platform.isWindows){
      dylib = DynamicLibrary.open("OpenCVProc.dll");
    }else{
      dylib = DynamicLibrary.open("libOpenCV_ffi.so");
    }
    rotimage = dylib.lookupFunction<
        Void Function(Pointer<Utf8>, Pointer<Utf8>, Int32),
        void Function(Pointer<Utf8>, Pointer<Utf8>, int)
        >("RotImg");
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    final directory = await getTemporaryDirectory();
    _outpath = "${directory.path}/output.jpg";
  }

  void _loadImage() async {
    var res = await FilePicker.platform.pickFiles();  // ファイル選択ダイアログ
    if( res!=null  ){
      setState(() {  // 状態変化を通知するメソッド
        imagefile = res.files[0].path ?? "";        // AppBarタイトルにファイル名セット
        img = Image.file( File( imagefile ) ); // Image Widgetに画像セット
      });
    }
  }

  void _rotateImage() async {
    final outpathPointer = _outpath.toNativeUtf8();
    final inpathPointer = imagefile.toNativeUtf8();

    rotimage( inpathPointer, outpathPointer, 0);

    Uint8List  imageData = File(_outpath).readAsBytesSync();
    img = Image.memory( imageData ); 
    imagefile = _outpath;
    
    setState(() { });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(imagefile),
        actions: [         // ここに並べたボタンWidgetがAppBarに並ぶ
          IconButton(onPressed: _rotateImage, icon: const Icon(Icons.rotate_right)),
          IconButton(onPressed: _loadImage, icon: const Icon(Icons.image))
        ],
      ),
      body: Center(
        child:
            img ?? const Text('no image', ),
      ),
    );
  }
}
