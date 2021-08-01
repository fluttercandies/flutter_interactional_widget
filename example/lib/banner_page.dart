import 'package:example/full_screen_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_interactional_widget/flutter_interactional_widget.dart';

class BannerPage extends StatefulWidget {
  const BannerPage({Key? key}) : super(key: key);

  @override
  _BannerPageState createState() => _BannerPageState();
}

class _BannerPageState extends State<BannerPage> {
  double height = 200;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 37,
          ),
          banner(),
          Expanded(child: contentWidget())
        ],
      ),
    );
  }

  Widget banner() {
    return InteractionalWidget(
      width: MediaQuery.of(context).size.width,
      height: height,
      maxAngleY: 30,
      maxAngleX: 40,
      middleScale: 1,
      foregroundScale: 1.1,
      backgroundScale: 1.3,
      backgroundWidget: backgroundWidget(),
      middleWidget: middleWidget(),
      foregroundWidget: foregroundWidget(),
    );
  }

  Widget contentWidget() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (c) {
          return FullScreenPage();
        }));
      },
      child: ListView.builder(
        itemBuilder: (c, i) {
          return ListTile(
            title: Text('hello $i 点击跳转全屏页'),
          );
        },
        itemCount: 8,
      ),
    );
  }

  Widget backgroundWidget() {
    return Container(
      child: getImage('back.png'),
    );
  }

  Widget foregroundWidget() {
    return Container(
      child: getImage('fore.png'),
    );
  }

  Widget middleWidget() {
    // return Center(child: Text('hello'));
    return Container(
      child: getImage('mid.png'),
    );
  }

  Image getImage(String s) {
    return Image.asset(
      "assets/banner/$s",
      width: MediaQuery.of(context).size.width,
      height: height,
      fit: BoxFit.fill,
      scale: 3.0,
    );
  }
}
