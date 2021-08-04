import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

import '../assets/IconEraser.dart';
import 'painters.dart';



class CanvasPage extends StatefulWidget {
  @override
  State<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends State<CanvasPage> with TickerProviderStateMixin {
  bool mainMenuActive = false;
  bool newCanvasMenuActive = false;
  bool eraserActive = false;
  double buttonPadding = 9.0;
  double buttonSize = 50;
  double buttonBorder = 25;
  int desktopWidth = 1000;
  var points = _OffsetList(
      offsets: [],
      color: Colors.black,
      strokeWidth: 10.0
  );
  var penList = [];
  Color canvasColor = Colors.white;
  var screenWidth;
  var screenHeight;

  void initState(){
    super.initState();
    penList = [points];
  }

  _setMenuButtonSize(screenSize){
    if (screenSize < desktopWidth){
      setState(() {
        buttonSize = 35;
        buttonBorder = 20;
      });
    } else{
      buttonSize = 50;
      buttonBorder = 25;
    }
  }

  createNewCanvas(color) {
    setState(() {
      canvasColor = color;
      points.offsets = [];
      penList = [points];

      newCanvasMenuActive = false;
    });
  }

  _onPanStart(){
    setState(() {
      mainMenuActive = false;
      newCanvasMenuActive = false;
    });
  }

  _onPanUpdate(details) {
    var position = details.localPosition;

    setState(() {
      if(!eraserActive) {
        penList.last.offsets.add(position);

      } else {
        _deletePoints(position);
      }
    });



  }

  _onPanEnd() {
    setState(() {
      if(!eraserActive) {
        penList.last.offsets.add(Offset.zero);
      }
    });

  }

  _pointInRange(Offset position, drawPoint){
    var range = points.strokeWidth ;
    if ((position.dx>= drawPoint.dx - range && position.dx <= drawPoint.dx + range) &&
        position.dy>= drawPoint.dy - range && position.dy <= drawPoint.dy + range){
      return true;
    }

    return false;
  }

  _deletePoints(position){
    if(eraserActive){
      for(var i = 0; i<penList.length; i++){
        for(var j = 0; j<penList[i].offsets.length;j++){
          var drawPoint = penList[i].offsets[j];
          if (_pointInRange(position,drawPoint)){
            penList[i].offsets[j] =Offset.zero;
          }
        }
      }
    }
  }

  _saveCanvas(size) async {
    var basicName = "gemalt";
    var timeStamp = DateTime.now();
    var formatter = DateFormat('yyyyMMdd_HHmm');
    String timeStampFormatted = formatter.format(timeStamp);


    Picture backgroundPicture = _backgroundPicture(size);

    var drawingPngBytes = _drawing(size, backgroundPicture);

    _savePicture(drawingPngBytes, basicName + timeStampFormatted);

  }

  _backgroundPicture(size) {
    var backgroundPainter = BackgroundPainter(canvasColor);
    final PictureRecorder recorder = PictureRecorder();
    backgroundPainter.paint(Canvas(recorder), size);
    final Picture picture = recorder.endRecording();
    //final img = await picture.toImage(size.width.round(),size.height.round());

    //welches Format benötigt _drawing?
    return picture;
  }

  _drawing(size, backgroundPicture) async {
    var penPainter = PenPainter(points, penList, backgroundPicture);
    final PictureRecorder recorder = PictureRecorder();
    penPainter.paint(Canvas(recorder), size);
    final Picture picture = recorder.endRecording();
    final img = await picture.toImage(size.width.round(),size.height.round());
    final pngBytes = await img.toByteData(format: ImageByteFormat.png);

    return pngBytes;
  }

  _savePicture(pngBytes, name) async{
    final file = await _combinePathAndFilename(name);
    var data = await pngBytes;

    file.writeAsBytesSync(data.buffer.asInt8List());
  }

  Future<String> get _windowsPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> _combinePathAndFilename(name) async {
    var path;

    if (Platform.isAndroid){
      path = await checkAndroidPermissionAndGetPath();
    } else if(Platform.isWindows){
      path = await _windowsPath;
    }
    //print(path);
    return File('$path/$name.png');
  }

  checkAndroidPermissionAndGetPath() async {
    var path = "/storage/emulated/0/Download";
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    return path;
  }

  _openGalerie() async {

  }

  eraserOnOff(){
    setState(() {
      eraserActive? eraserActive = false : eraserActive = true;
    });
  }


  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    _setMenuButtonSize(screenWidth);

    return Scaffold(
      body: Center(
          child: GestureDetector(
              onPanStart: (details) => _onPanStart(),
              onPanDown: (details)=> _onPanUpdate(details),
              onPanUpdate: (details) => _onPanUpdate(details),
              onPanEnd: (details) => _onPanEnd(),
              child: MouseRegion(
                  cursor: SystemMouseCursors.basic,
                  child:
                        Container(
                          width: screenWidth,
                          height: screenHeight,
                          color: canvasColor,
                          child: CustomPaint(
                            painter: PenPainter(points, penList),

                          )
                        )
              )
          )
      ),
      floatingActionButton: mainMenuActive ? mainMenu() :
                            Container(
                                height: buttonSize,
                                width: buttonSize,
                                child: FittedBox(
                                    child:FloatingActionButton(
                                      mini: true,
                                      child: Icon(Icons.menu),
                                      onPressed: () {
                                        setState(() {
                                          mainMenuActive= true;
                                        });
                                      },
                                    )
                                )
                            )
    );
  }

  Widget mainMenu(){
    return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          MenuButton(
              icon:Icon(Icons.undo),
              onPressed: () {},
              //canvasColor: canvasColor
              ),
          SizedBox(height: buttonPadding),
          MenuButton(
              icon:Icon(Icons.collections),
              onPressed: () => _openGalerie(),
              canvasColor: canvasColor
          ),
          SizedBox(height: buttonPadding),
          MenuButton(
            icon:Icon(Icons.save),
            onPressed:()=> _saveCanvas(Size(screenWidth, screenHeight)),
            canvasColor: canvasColor,
          ),
          SizedBox(height: buttonPadding),
          newCanvasMenu(),
          SizedBox(height: buttonPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children:[
              penWidthMenu(screenWidth),
              MenuButton(
                icon:Icon(eraserActive?Icons.brush: OwnIcons.eraser),
                onPressed: () => eraserOnOff(),
                canvasColor: canvasColor,
              )
            ]
          ),
          SizedBox(height: buttonPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              colorSelectionMenu(),
              Container(
                  height: buttonSize,
                  width: buttonSize,
                  child: FittedBox(
                      child:FloatingActionButton(
                        mini: true,
                        child: Icon(Icons.menu_open),
                        onPressed: () {
                            setState(() {
                              newCanvasMenuActive = false;
                              mainMenuActive= false;
                            });
                        },
                      )
                  )
              ),
            ],
          )
        ]
    );
  }

  Widget newCanvasMenu(){
    List<Widget> canvasMenu = [];
    List colorList = [Colors.black,Colors.grey,Colors.brown,
      Colors.purple,Colors.pinkAccent,Colors.red, Colors.orange,
      Colors.yellow, Colors.green,Colors.lightGreen,Colors.greenAccent,
      Colors.indigoAccent, Colors.blue, Colors.white,
    ];

    _openMenu(){
      setState(() {
        newCanvasMenuActive ? newCanvasMenuActive = false : newCanvasMenuActive = true;
      });
    }

    if(newCanvasMenuActive){
      for(var i=0; i < colorList.length;i++){
        canvasMenu.add(
          MenuButton(
            color: colorList[i],
            onPressed: () =>createNewCanvas(colorList[i]),
            canvasColor: canvasColor
          )
        );
        canvasMenu.add(
            SizedBox(width: buttonPadding)
        );
      }
    }

    canvasMenu.add(
        MenuButton(
            icon:Icon(Icons.note_add),
            onPressed: () => _openMenu(),
            canvasColor: canvasColor
        )
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: canvasMenu,

    );
  }

  Widget newCanvasButton(color){
    return Container(
        height: buttonSize,
        width: buttonSize,
        decoration: BoxDecoration(
            border: Border.all(
              width: 1,
              color: canvasColor == Colors.black? Colors.white : Colors.black
            ),
            borderRadius: BorderRadius.all(Radius.circular(buttonBorder))
        ),
        child: FittedBox(
            child:FloatingActionButton(
              backgroundColor: color,
              onPressed: (){
                createNewCanvas(color);
              }
            )
        )
    );
  }

  Widget colorSelectionMenu(){
    List<Widget> colorMenu = [];
    List colorList = [Colors.black,Colors.grey,Colors.brown,
      Colors.purple,Colors.pinkAccent,Colors.red, Colors.orange,
      Colors.yellow, Colors.green,Colors.lightGreen,Colors.greenAccent,
      Colors.indigoAccent, Colors.blue, Colors.white,
    ];


    _changePenColor(color) {
      setState(() {
        points = _OffsetList(offsets: [], color: color, strokeWidth: points.strokeWidth);
        penList.add(points);
      });
    }

    for(var i = 0; i<colorList.length; i++){
      colorMenu.add(
          MenuButton(
            color: colorList[i],
            onPressed: () => _changePenColor(colorList[i]),
            canvasColor: canvasColor,
            active: points.color == colorList[i],
          )
      );
      colorMenu.add(SizedBox(width: buttonPadding));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: colorMenu,
    );
  }

  Widget penWidthMenu(screenSize){
    List<Widget> penWidthMenu = [];
    List widthList = [];


    setWidth(){
      if (screenSize > desktopWidth) {
        widthList = [2.5,5.0,10.0,20.0,30.0,40.0,50.0];
      } else{
        widthList = [1.0,2.5,5.0,10.0,15.0,20.0,25.0];
      }
      widthList = widthList.reversed.toList();
    }

    _changePenWidth(width){
      setState(() {
        points = _OffsetList(offsets: [], color: points.color, strokeWidth: width);
        penList.add(points);
      });
    }

    createMenu(){
      for(var i = 0; i<widthList.length; i++){
        penWidthMenu.add(
            MenuButton(
                icon:Icon(Icons.circle, size: widthList[i] /1.5),
                onPressed: () => _changePenWidth(widthList[i]),
                canvasColor: canvasColor,
                active: points.strokeWidth == widthList[i],
            )
        );
        penWidthMenu.add(
            SizedBox(
                width: buttonPadding)
        );
      }
    }

    setWidth();

    createMenu();


    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: penWidthMenu,
    );

  }

}

class _OffsetList {
  List<Offset> offsets;
  Color color;
  double strokeWidth;

  _OffsetList(
      {required this.offsets, required this.color, required this.strokeWidth});
}

class MenuButton extends StatelessWidget{
  MenuButton({this.icon, this.color, this.onPressed, this.canvasColor, this.active=false});

  var icon;
  var onPressed;
  var canvasColor;
  var color;
  var active;
  double buttonSize = 50;
  double buttonBorder = 25;


  Widget build(BuildContext context) {
    return Container(
        height: buttonSize,
        width: buttonSize,
        decoration: BoxDecoration(
            border: Border.all(
                width: active? 3: 1,
                color: canvasColor == Colors.black? Colors.white : Colors.black
            ),
            borderRadius: BorderRadius.all(Radius.circular(buttonBorder))
        ),
        child: FittedBox(
            child: FloatingActionButton(
                mini: true,
                backgroundColor: color,
                child: icon,
                onPressed: onPressed
            )
        )
    );
  }
}


