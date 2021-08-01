import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

// ignore: must_be_immutable
class InteractionalWidget extends StatefulWidget {
  // 控件宽度
  double width;

  // 控件高
  double height;

  // 水平方向最大的旋转角度
  double maxAngleX;

  // 竖直方向最大的旋转角度
  double maxAngleY;

  // 背景层缩放比
  double? backgroundScale;

  // 中景层缩放比
  double? middleScale;

  // 前景层的缩放比
  double? foregroundScale;

  // 背景层
  Widget? backgroundWidget;

  // 中景层
  Widget? middleWidget;

  // 前景层
  Widget? foregroundWidget;

  InteractionalWidget(
      {Key? key,
      this.backgroundWidget,
      this.middleWidget,
      this.foregroundWidget,
      this.backgroundScale,
      this.middleScale,
      this.foregroundScale,
      required this.maxAngleX,
      required this.maxAngleY,
      required this.width,
      required this.height})
      : super(key: key);

  @override
  _InteractionalWidgetState createState() => _InteractionalWidgetState();
}

class _InteractionalWidgetState extends State<InteractionalWidget> {
  var backgroundOffset = const Offset(0.1, 0.1);
  var foregroundOffset = const Offset(0.1, 0.1);
  double time = 0.02;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  @override
  void initState() {
    super.initState();
    _streamSubscriptions.add(gyroscopeEvents.listen((event) {
      setState(() {
        // 通过采集的旋转速度计算出背景 delta 偏移
        Offset deltaOffset = gyroscopeToOffset(-event.y, -event.x);
        // 初始偏移量 + delta 偏移 之后考虑越界
        backgroundOffset = considerBoundary(deltaOffset + backgroundOffset);
        // 前景计算相对速度之后取反即可
        foregroundOffset = getForegroundOffset(backgroundOffset);
      });
    }));
  }

  @override
  void dispose() {
    for (var element in _streamSubscriptions) {
      element.cancel();
    }
    super.dispose();
  }

  var lastLocalFocalPoint = Offset(0.1, 0.1);

  Offset gyroscopeToOffset(double x, double y) {
    double angleX = x * time * 180 / pi;
    double angleY = y * time * 180 / pi;
    angleX = angleX >= widget.maxAngleX ? widget.maxAngleX : angleX;
    angleY = angleY >= widget.maxAngleY ? widget.maxAngleY : angleY;

    return Offset((angleX / widget.maxAngleX) * maxBackgroundOffset.dx,
        (angleY / widget.maxAngleY) * maxBackgroundOffset.dy);
  }

  // 通过最大偏移约束计算偏移量
  Offset considerBoundary(Offset origin) {
    Offset maxOffset = maxBackgroundOffset;
    double dx = origin.dx;
    double dy = origin.dy;
    if (dx > maxOffset.dx) {
      dx = maxOffset.dx;
    }
    if (origin.dx < -maxOffset.dx) {
      dx = -maxOffset.dx;
    }

    if (dy > maxOffset.dy) {
      dy = maxOffset.dy;
    }
    if (origin.dy < -maxOffset.dy) {
      dy = -maxOffset.dy;
    }
    Offset result = Offset(dx, dy);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          Positioned(
              top: backgroundOffset.dy,
              left: backgroundOffset.dx,
              child: Transform.scale(
                  scale: widget.backgroundScale ?? 1.0,
                  child: widget.backgroundWidget ?? Row())),
          Positioned(
              child: Transform.scale(
                  scale: widget.middleScale ?? 1.0,
                  child: widget.middleWidget ?? Row())),
          Positioned(
              top: foregroundOffset.dy,
              left: foregroundOffset.dx,
              child: Transform.scale(
                  scale: widget.foregroundScale ?? 1.0,
                  child: widget.foregroundWidget ?? Row()))
        ],
      ),
    );
  }

  // 背景层的最大偏移
  Offset get maxBackgroundOffset {
    return Offset(((widget.backgroundScale ?? 1) - 1.0) * widget.width / 2,
        ((widget.backgroundScale ?? 1) - 1.0) * widget.height / 2);
  }

  // 通过背景偏移计算前景偏移
  Offset getForegroundOffset(Offset backgroundOffset) {
    // 假如前景缩放比是 1.4 背景是 1.8 控件宽度为 10
    // 那么前景最大移动 4 像素，背景最大 8 像素
    double offsetRate = ((widget.foregroundScale ?? 1) - 1) /
        ((widget.backgroundScale ?? 1) - 1);
    // 前景取反
    return -Offset(
        backgroundOffset.dx * offsetRate, backgroundOffset.dy * offsetRate);
  }
}
