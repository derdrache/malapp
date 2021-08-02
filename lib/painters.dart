import 'package:flutter/material.dart';
import 'dart:ui';


class PenPainter extends CustomPainter {
  PenPainter(this.currentPen, this.penList, [this.backgroundPicture]);
  var currentPen;
  var penList;
  var backgroundPicture;


  void _paintPen(canvas, pen) {
    List<Offset> points = pen.offsets;
    var penColor = pen.color;
    var strokeWidth = pen.strokeWidth;

    var paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = penColor;

    for (var i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
        canvas.drawLine(points[i], points[i + 1], paint);
      } else if (points[i] != Offset.zero && points[i + 1] == Offset.zero) {
        canvas.drawPoints(PointMode.points, [points[i]], paint);
      }
    }
  }

  void _paintPenList(canvas) {
    for (var i = 0; i < penList.length; i++) {
      _paintPen(canvas, penList[i]);
    }
  }

  void paint(canvas, size) {
    if (backgroundPicture != null){
      canvas.drawPicture(backgroundPicture);
    }
    _paintPenList(canvas);
  }

  bool shouldRepaint(oldDelegate) => true;
}


class BackgroundPainter extends CustomPainter{
  BackgroundPainter(this.color);
  var color;

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color;

    canvas.drawRect(Offset(0,0) & size, paint);
  }

  bool shouldRepaint(oldDelegate) => true;

}