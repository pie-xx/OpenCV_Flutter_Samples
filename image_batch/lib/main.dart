import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Batch',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Image Batch'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/*
画像変換処理のパラメータを格納するクラスです。SendPort、srcdir(ソースディレクトリ)、dstdir(出力ディレクトリ)、rotangl(回転角度)が含まれます。
*/
class TransCmd {
  SendPort? sendport;
  String? srcdir;
  String? dstdir;
  int rotangl;
  
  TransCmd(this.sendport, this.srcdir, this.dstdir, this.rotangl);
}

class _MyHomePageState extends State<MyHomePage> {

  String srcdir = "";
  String dstdir = "";

  int rotangle = 0;
  String transmsg="";

/*
画像変換処理を行う関数です。TransCmdオブジェクトを引数に取り、srcdirからdstdirへの画像変換を行います。
この関数は、dart:ffiを経由してC/C++関数であるRotImgを呼び出します。
これにより、画像が指定された角度で回転されます。
*/
  static void isoTrans( TransCmd cmd ){
    String srcdir = cmd.srcdir ?? "";
    String dstdir = cmd.dstdir ?? "";

    DynamicLibrary  dylib ;
    if(Platform.isAndroid){
      dylib = DynamicLibrary.open("libOpenCV_ffi.so");
    }else
    if(Platform.isWindows){
      dylib = DynamicLibrary.open("OpenCVProc.dll");
    }else{
      dylib = DynamicLibrary.open("/home/pie/libOpenCV_ffi.so");
    }

    Function rotImg = dylib.lookupFunction<
        Void Function(Pointer<Utf8>, Pointer<Utf8>, Int32),
        void Function(Pointer<Utf8>, Pointer<Utf8>, int)
        >("RotImg");

    try{
      List<FileSystemEntity> plist = Directory(srcdir).listSync();
      plist.sort((a,b) => a.path.compareTo(b.path));
      int count=0;
      for( var p in plist ){
        cmd.sendport?.send( "${++count} / ${plist.length}");
        final outPath = "$dstdir${p.path.substring(srcdir.length)}".toNativeUtf8().cast<Uint8>();
        final inPath = p.path.toNativeUtf8().cast<Uint8>();
        rotImg(inPath, outPath, cmd.rotangl);
      }
    }catch(e){
      cmd.sendport?.send(e.toString());
    }
    cmd.sendport?.send("end");
  }

/*
isoTrans関数を新しいIsolateで実行し、画像変換処理を実行します。
ReceivePortを使って、メインIsolateと新しいIsolate間の通信を行います。
*/
  void trans(){
    final ReceivePort receivePort = ReceivePort();

    // 通信側からのコールバック
    receivePort.listen(( message ) {
      if( message=="end"){
        receivePort.close();
      }
      setState(() {      
        transmsg = message;
      });
    });

    Isolate.spawn( isoTrans, TransCmd(receivePort.sendPort, srcdir, dstdir, rotangle) );
  }

  @override
  Widget build(BuildContext context) {
/*
dirsetting: カラムウィジェットで、アプリケーションのメインコンテンツが含まれます。
以下の要素が含まれています。
  transmsg: 画像変換処理の進行状況を表示するテキストウィジェットです。
  ソースディレクトリと出力ディレクトリを選択するための2つのボタンがあります。
  ボタンを押すと、FilePickerを使用してディレクトリを選択できます。
  回転角度を選択するための4つのラジオボタンがあります。0°、90°、180°、270°の角度を選択できます。
*/
    var dirsetting = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
          Text("$transmsg", style: Theme.of(context).textTheme.bodyLarge,),
          const Text(' '),   
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(' '),
              TextButton(
                onPressed: ()async{
                  var res = await FilePicker.platform.getDirectoryPath();
                  setState(() {
                    srcdir = res ?? "";
                  });
                },
              style: TextButton.styleFrom( backgroundColor: Colors.orange, ), 
              child: const Text("src"),
            ),
            Text(' $srcdir',style: Theme.of(context).textTheme.bodyLarge,),
          ],),    
          const Text(' '),    
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(' '),
              TextButton(
              onPressed: ()async{
                var res = await FilePicker.platform.getDirectoryPath();
                setState(() {
                  dstdir = res ?? "";
                });
              },
              style: TextButton.styleFrom( backgroundColor: Colors.orange, ), 
              child: const Text("dst"),
            ),
              Text(' $dstdir',style: Theme.of(context).textTheme.bodyLarge,),
          ],), 
          const Divider(
                  height: 20,
                  thickness: 2,
                  indent: 20,
                  endIndent: 10,
                  color: Colors.blue,
          ),  
          Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text('  rotate angle '),
                    Radio(
                      activeColor: const Color.fromRGBO(33, 150, 243, 1),
                      value: 3,
                      groupValue: rotangle,
                      onChanged: 
                        (v){ setState(() {
                          rotangle=3;
                        });  },
                    ),
                    const Text('0'),
                    Radio(
                      activeColor: Colors.blue,
                      value: 0,
                      groupValue: rotangle,
                      onChanged: 
                        (v){ setState(() {
                          rotangle=0;
                        });  },
                    ),
                    const Text('→90'),
                    Radio(
                      activeColor: Colors.blue,
                      value: 1,
                      groupValue: rotangle,
                      onChanged:
                        (v){ setState(() {
                          rotangle=1;
                        });  },
                    ),
                    const Text('↓180'),
                    Radio(
                      activeColor: Colors.blue,
                      value: 2,
                      groupValue: rotangle,
                      onChanged:
                        (v){ setState(() {
                          rotangle=2;
                        });  },
                    ),
                    const Text('←270'),
                ],), 
    ],);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // GOボタンを押すと、trans()メソッドが呼び出され、画像変換処理が開始されます。
          IconButton(onPressed: (){ 
            trans();  }, 
            icon: const Icon(Icons.run_circle)),
          const Text("GO"),
        ],
      ),
      body: dirsetting
    );
  }
}
