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
  String filtername = "original";
  Image? img0;  // 画像表示Widget
  Image? img1;

  late String _outpath;
  late String _tmppath;
  late DynamicLibrary  dylib ;
  late Function emphasize_red;
  int mode = 0;

  @override
  void initState(){
    super.initState();

    if(Platform.isAndroid){
      dylib = DynamicLibrary.open("libemphasize_red.so");
    }else
    if(Platform.isWindows){
      dylib = DynamicLibrary.open("emphasize_red.dll");
    }else{
      dylib = DynamicLibrary.open("libemphasize_red.so");
    }

    emphasize_red = dylib.lookupFunction<
        Void Function(Pointer<Utf8>, Pointer<Utf8>),
        void Function(Pointer<Utf8>, Pointer<Utf8>)
        >("emphasize_red");
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    final directory = await getTemporaryDirectory();
    _outpath = "${directory.path}/output.jpg";
    _tmppath = "${directory.path}/tmp.jpg";
  }

  void _loadImage() async {
    var res = await FilePicker.platform.pickFiles();  // ファイル選択ダイアログ
    if( res!=null  ){
      setState(() {
        imagefile = res.files[0].path ?? "";        // AppBarタイトルにファイル名セット
        img0 = Image.file( File( imagefile ) );

        emphasize_red( imagefile.toNativeUtf8(), _outpath.toNativeUtf8() );

        Uint8List  imageData = File(_outpath).readAsBytesSync();
        img1 = Image.memory( imageData ); 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var scwidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("$filtername $imagefile"),
        actions: [         // ここに並べたボタンWidgetがAppBarに並ぶ
          IconButton(onPressed: _loadImage, icon: const Icon(Icons.image))
        ],
      ),
      body:
       Row( children:[
          SizedBox( width: scwidth /2,
            child: InteractiveViewer(
              maxScale: 64,
              child: Container( child: Center( child: 
                  img0 ?? Text("No Image0")
              ),
            ))
          ),
          SizedBox( width: scwidth /2,
            child: InteractiveViewer(
              maxScale: 64,
              child: Container( child: Center( child: 
                  img1 ?? Text("No Image1")
              ),
            )),
          )
        ]
      ),
    );
  }
}
