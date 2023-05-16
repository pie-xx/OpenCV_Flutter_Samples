import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:file_picker/file_picker.dart'; // 追加プラグインの指定
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
  String filename = ""; // AppBarタイトル
  Image? frameImg, diffImg;
  late String _outpath;
  late String _diffpath;
  late DynamicLibrary dylib ;
  late Function getProperty;
  var inarray = malloc.allocate<Int32>(128);
  var outarray = malloc.allocate<Int32>(128);
  int width=0;
  int height=0;
  int num_frames=0;
  int currentFrame=0;
  static const int difflen = 8;

  @override
  void initState(){
    super.initState();
    if(Platform.isAndroid){
      dylib = DynamicLibrary.open("libOpenCV_ffi.so");
    }else
    if(Platform.isWindows){
      dylib = DynamicLibrary.open("video_proc.dll");
    }else{
      dylib = DynamicLibrary.open("libOpenCV_ffi.so");
    }
    getProperty = dylib.lookupFunction<
      Void Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, 
        Pointer<Uint32>, Pointer<Uint32>),
      void Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, 
        Pointer<Uint32>, Pointer<Uint32>)
    >("getProperty");
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    final directory = await getTemporaryDirectory();
    _outpath = "${directory.path}/output.png";
    _diffpath = "${directory.path}/diff.png";
  }

  void loadVideo() async {
    var res = await FilePicker.platform.pickFiles(); // ファイル選択ダイアログ
    if( res!=null ){
      filename = res.files[0].path ?? ""; // AppBarタイトルにファイル名セット
      currentFrame = 0; 
      loadFrame();
    }
  }

  void loadFrame() async {
    inarray[0]=currentFrame;
    inarray[1]=difflen;
    getProperty( filename.toNativeUtf8(), _outpath.toNativeUtf8(), 
                    _diffpath.toNativeUtf8(), inarray, outarray );
    if( outarray[0]==0){
      width = outarray[1];
      height = outarray[2];
      num_frames = outarray[3];
      print("fps=${outarray[4]}");
      if( num_frames==0 ){
        num_frames = 60 * 5 * 30;
      }
      Uint8List imageData = File(_outpath).readAsBytesSync();
      frameImg = Image.memory( imageData ); 
      await precacheImage(frameImg!.image, context);
      imageData = File(_diffpath).readAsBytesSync();
      diffImg = Image.memory( imageData ); 
      await precacheImage(diffImg!.image, context);
      setState(() { // 状態変化を通知するメソッド
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var scwidth = MediaQuery.of(context).size.width;
    var scheight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(filename),
        actions: [ // ここに並べたボタンWidgetがAppBarに並ぶ
          IconButton(onPressed: loadVideo, icon: const Icon(Icons.video_file)),
          const Text('video file')
        ],
      ),
      body: 
      Column( 
        children:[
          Text("width: $width height: $height num_frames: $num_frames $currentFrame"),
          SizedBox(
            width: scwidth,
            height: (scheight-192)/2,
            child:(frameImg ?? const Text('no image'))), 
          SizedBox(
            width: scwidth,
            height: (scheight-192)/2,
            child:(diffImg ?? const Text('no image'))),
          Row(children: [
            IconButton(
              onPressed: (){
                if(currentFrame >= difflen ){
                  currentFrame = currentFrame - difflen;
                  loadFrame();
                }
              }, 
              icon: const Icon(Icons.navigate_before)),
            IconButton(
              onPressed: (){
                if(currentFrame < num_frames - difflen ){
                  currentFrame = currentFrame + difflen;
                  loadFrame();
                }
              }, 
              icon: const Icon(Icons.navigate_next)),
            SizedBox(
              width: scwidth * 3/4,
              child:
              Slider(
                value: currentFrame.toDouble(),
                max: num_frames.toDouble(),
                min: 0,
                divisions: scwidth~/4,
                label: currentFrame.toString(),
                onChangeEnd: (double value) {
                  setState(() {
                    currentFrame = value.toInt();
                    loadFrame();
                  });
                },
                onChanged: (double value ){
                  currentFrame = value.toInt();
                }
              )
            ),
          ],)
        ],)
      );
  }
}
