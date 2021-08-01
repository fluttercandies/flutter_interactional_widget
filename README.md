---
theme: qklhk-chocolate
---
## 引言

最近看到 [自如团队](https://juejin.cn/user/1494986085377223) 发布的 [自如客APP裸眼3D效果的实现](https://juejin.cn/post/6989227733410644005#comment)，这个布局确实做得很有趣，越玩越上瘾，感谢自如团队的分享。随即按照自己的思路用 Flutter 实现一遍，来看看最终效果。


| banner 样式 | 全屏样式 |
| --- | --- |
| ![IMG_0020.gif](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/f93cd02d259b4a42867f65adf3e3ff49~tplv-k3u1fbpfcp-watermark.image)| ![IMG_0021.gif](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/f71fd3ea3ade4d1e87ce201e4711e328~tplv-k3u1fbpfcp-watermark.image) |






本文会着重介绍我在实现过程中的思路和设计，所以无论你是前端 /iOS/Android/Flutter 都可以参考同样的路子去实现。如果有任何问题，也欢迎探讨。
***

## 一、整体构思

从效果上可以看出，随着我们设备的旋转，有的部分顺着倾斜方向滑动，有的朝着相反方向，而有的则不动。所以图片上的元素肯定分为不同的图层，旋转设备让图层发生移动即可达到效果。

将图片分为了前、中、后三层，**随着手机角度的旋转，中层保持不动，上层顺着旋转方向移动，下层与上层相逆。**

![](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/9909cd5efd0540c8985e817965179eed~tplv-k3u1fbpfcp-zoom-1.image)
（图片来自自如分享）

所以在图片分层之后，这个效果就变成了两步：

1、获取手机的旋转信息

2、根据旋转信息移动不同的图层
***
## 二、获取手机的旋转信息

Flutter 中有这样一个插件 [sensors_plus](https://pub.dev/packages/sensors_plus) ，使用它可以帮助我们获取两个传感器的信息：Accelerometer(加速度传感器)、Gyroscope(陀螺仪)。

![传感器.gif](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/2b9a1fc3c2ea408ab25fbefba093becd~tplv-k3u1fbpfcp-zoom-1.image)

每个传感器提供了一个 Stream ，其发送的事件包含 X、Y、Z 表示手机不同方向的变化的速度。通过对 Stream 的监听，我们便可实时获取相关传感器数据。

这个仓库中也附带了一个体感贪吃蛇的 demo，倾斜设备，小蛇便朝着倾斜方向前进。

![贪吃蛇.gif](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/a7b3d62386ed45beb90f1e7f82bccb8d~tplv-k3u1fbpfcp-zoom-1.image)

插件的更多介绍可以查看视频： [Flutter Widgets 介绍合集 —— 103. Sensors_plus](https://www.bilibili.com/video/BV1Kq4y1p724?t=60)

我们实现的效果需要根据手机旋转移动图层，自然使用陀螺仪传感器即可：
```dart
 gyroscopeEvents.listen(
       (GyroscopeEvent event) {
       // event.x  event.y  event.z
     ································
   },
 ),
```
回调的 GyroscopeEvent 包含三个属性，x、y、z，分别对应下图三个方向所检测到的旋转速度（单位：弧度/秒）

![xyz.png](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/360b3f84a64f452fb6c3484034470d06~tplv-k3u1fbpfcp-watermark.image)

结合需求来看，我们只需使用 Y 轴（对应图像在水平方向的移动）和 X 轴（对应图像在竖直方向的移动）的数据即可。

***
## 三、根据旋转信息移动图层

在网上找了一个 psd 文件，导出图片之后整体长这样：

![封面.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/0596843c01cd46ffb56234d4ac5b3a61~tplv-k3u1fbpfcp-watermark.image)


我在 psd 文件中导出 3 个图层，需要注意图片格式要为 .png，这样上一个图层的透明区域不会被填充为白色而遮挡住下一个图层，之后直接使用 Image widget 展示图片即可：

| 前景                                                                                                                              | 中景（白色的文字，所以看不见）                                                                                                                      | 背景                                                                                                                              |
| ------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| ![fore.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/b38b45cc5f1a4c07afef8e24c4f741ce~tplv-k3u1fbpfcp-zoom-1.image) | ![mid.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/846b5b7e53734048acdca30923fde68a~tplv-k3u1fbpfcp-zoom-1.image) | ![back.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/005efc69521e40f39aad976b8f1d7327~tplv-k3u1fbpfcp-zoom-1.image) |

### 1、让图层动起来

图片分为三层，我们自然想到使用 `Stack` 作为容器，依次放入三个图层（Widget）

```
 // 背景图层
 Widget? backgroundWidget;
 // 中景图层
 Widget? middleWidget;
 // 前景图层
 Widget? foregroundWidget;
```

图层移动其实很简单，就是去修改每一个图层的偏移量。再观察这个实现效果，会发现随着我们的旋转，图层中的内容好像 `滑` 出来一样。

![](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/de9f3abb049741daad225b0c9af8cc38~tplv-k3u1fbpfcp-zoom-1.image)

所以我们一开始进入时，看到的肯定只是图片的部分区域。我的想法是给每一个图层设置 `scale`，将图片进行放大。显示窗口是固定的，那么一开始只能看到图片的正中位置。（中层可以不用，因为中层本身是不移动的，所以也不必放大)

![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/4d4e6fadafc746b0a3fbf0da9695a6eb~tplv-k3u1fbpfcp-zoom-1.image)

旋转手机修改偏移量，为前景和背景层设置相反的偏移量，便可达到两个图层反向运动的效果。

在计算偏移量的时候还需要考虑两个因素：

**1、图层的最大偏移量**

图层经过了一定比例的放大，所以存在一个最大的偏移范围，偏移量不能超过这个范围。

![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/11308bb66e1242d884b9f9d7192bb672~tplv-k3u1fbpfcp-zoom-1.image)

不难看出水平方向上最大偏移计算方法为：`(缩放比例-1) * 宽 / 2，` 竖直方向同理。

**2、前景与背景图层的相对偏移速度**

因为前景和背景的缩放比例可能不同，如果两者以 1：1 的相对偏移，可能会出现以下情况。

![image-20210729005136818.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/16ff24920a8f445a91c5c46ff3d0544f~tplv-k3u1fbpfcp-watermark.image)
假如 前景缩放是 1.4，背景为 1.8，当显示区域向左移动 2 像素的时候。这时背景层所显示的区域同样向左移动 2 个像素，前景层相反。但这时前景已经达最大的偏移量，不能再继续移动。而背景其实还有区域未能显示，所以可以通过两者的缩放比计算对应的偏移比，保证两个图片都能完整的展示出来。

```
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
```

这里我通过背景偏移为标准，计算前景偏移，并且在计算背景偏移的之前先考虑了最大偏移范围，这样保证前景和背景都不会发生越界行为。先通过拖拽改变偏移量调用 setState 更新界面，看看图层部分实现的效果：

![1627550866693665.gif](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/afc0878c61fd4943bbff073a524b12c5~tplv-k3u1fbpfcp-zoom-1.image)

背景随着手指滑动而位移，同时前景朝相反的方向移动，当滑动到图层边界时无法继续，整个过程中层保持不动。

### 2、传感器控制偏移

图层位移实现之后，我们只需要将上面由手指滑动触发的偏移改变为由传感器触发即可。

这里我们来想一个问题，我们设备处于水平状态时，显示区域居中，而当设备倾斜的时候，显示区域移动。

![image.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/65b0f1bf14ca41c694f099aebc8836b6~tplv-k3u1fbpfcp-watermark.image)

那么该旋转多少角度达到最大偏移量呢？

所以这里我定义了两个变量：
```dart
  double maxAngleX;
  double maxAngleY;
```
分别表示水平和垂直方向的最大旋转角度。假设 maxAngleX 为 10，表示当你在水平方向旋转设备 10° 度的时候，图像显示到边界了。

有了这个定义我们便可反推出背景层 旋转 1° 的偏移量为：

**1/maxAngleX \* maxBackgroundOffset.dx**，垂直方向同理。


思路就是这样，不过我在实现的时候还遇到了一个棘手的问题：

**由于 sensors_plus 插件中提供的是各方向的旋转速度（rad/s），我们改如何计算实际的旋转角度？**。

其实并不难：旋转弧度 = **（旋转速度（rad/s） * 时间）**，那么这里时间是多少？

看 sensors_plus 插件的安卓端实现，这个插件通过 SensorManager 注册陀螺仪传感器的回调，通过 chanel 将采集到的数据直接传递到 Flutter 侧。
```java
sensorManager.registerListener(sensorEventListener, sensor, SensorManager.SENSOR_DELAY_NORMAL);
```
在安卓端 SensorManager 的采集灵敏度分几种

>-   SensorManager.SENSOR_DELAY_FASTEST(0微秒)：最快。最低延迟，一般不是特别敏感的处理不推荐使用，该模式可能在成手机电力大量消耗，由于传递的为原始数据，算法不处理好会影响游戏逻辑和UI的性能
>-   SensorManager.SENSOR_DELAY_GAME(20000微秒)：游戏。游戏延迟，一般绝大多数的实时性较高的游戏都是用该级别
>-   SensorManager.SENSOR_DELAY_NORMAL(200000微秒):普通。标准延时，对于一般的益智类或EASY级别的游戏可以使用，但过低的采样率可能对一些赛车类游戏有跳帧现象
>-   SensorManager.SENSOR_DELAY_UI(60000微秒):用户界面。一般对于屏幕方向自动旋转使用，相对节省电能和逻辑处理，一般游戏开发中不使用

不同灵敏度的采集时间不同，sensors_plus 默认是 `SENSOR_DELAY_NORMAL` 即 0.2S ，实际使用时感觉响应并没那么及时。所以我直接 fork 项目下来，将 `SENSOR_DELAY_NORMAL` 改为了 `SENSOR_DELAY_GAME` ，即每次采集时间为 **20000微秒（0.02秒）**。

换算成角度就是：**x \* 0.02 \* 180 / π**，再用角度换算背景偏移量，背景偏移量考虑最大偏移范围之后，计算前景，调用 setState 更新界面即可。关键步骤如下：

```dart
gyroscopeEvents.listen((event) {
  setState(() {
    // 通过采集的旋转速度计算出背景 delta 偏移
    Offset deltaOffset = gyroscopeToOffset(-event.y, -event.x);
    // 初始偏移量 + delta 偏移 之后考虑越界
    backgroundOffset = considerBoundary(deltaOffset + backgroundOffset);
    // 背景偏移根据缩放比例获取前景偏移
    foregroundOffset = getForegroundOffset(backgroundOffset);
  });
});
```
***
## 四、构造函数说明

**InteractionalWidget**

属性                       | 说明          | 是否必选 |
| ------------------------ | ----------- | ---- |
| double width             | 视窗宽度        | 是    |
| double height            | 视窗高度        | 是    |
| double maxAngleX         | 水平方向最大的旋转角度 | 是    |
| double maxAngleY         | 竖直方向最大的旋转角度 | 是    |
| double? backgroundScale  | 背景层缩放比      | 否    |
| double? middleScale      | 中景层缩放比      | 否    |
| double? foregroundScale  | 前景层的缩放比     | 否    |
| Widget? backgroundWidget | 背景层 widget  | 否    |
| Widget? middleWidget     | 中景层 widget  | 否    |
| Widget? foregroundWidget | 前景层 widget  | 否

三个图层均非必传，所以你也可以只指定 前景/背景 单一图层的位移。

仓库已上传至 pub 通过依赖：

所有代码皆已上传至 github，其中演示程序 apk 可以直接下载运行，后面这个仓库还会更新一些交互式的小组件，给个点赞、关注、 star 不过分吧~
***
## 五、最后


本来是打算接着写网络编程，中途看到 [自如客APP裸眼3D效果的实现](https://juejin.cn/post/6989227733410644005#comment) 于是趁着周末赶紧实现了一下，再次感谢 [自如团队](https://juejin.cn/user/1494986085377223) 提供这么妙的创意。下一期，还是按照之前的计划，通过 广播/组播的方式实现一个基础的局域网多端群聊服务。

如果你有任何疑问可以通过公众号与联系我，如果文章对你有所启发，希望能得到你的点赞、关注和收藏，这是我持续写作的最大动力。Thanks~


公众号：**进击的Flutter**或者 **runflutter** 里面整理收集了最详细的Flutter进阶与优化指南，欢迎关注。

**往期精彩内容：**

[Flutter 进阶优化](https://juejin.cn/column/6970873233809604639)

[Flutter核心渲染机制](<https://juejin.cn/column/6960657267184271396>)

[Flutter路由设计与源码解析](https://juejin.cn/column/6960659401136930830)


