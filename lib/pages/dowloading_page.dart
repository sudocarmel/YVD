import 'package:flutter/material.dart';

class Dowloading extends StatefulWidget {
  const Dowloading({super.key});

  @override
  State<Dowloading> createState() => _DowloadingState();
}

class _DowloadingState extends State<Dowloading> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
          padding: EdgeInsets.only(top: 8, bottom: 8, left: 8, right: 8),
          width: 70,
          height: 70,
          child: Image.asset(
            "assets/images/ytd_img.png",
            fit: BoxFit.cover,
          ),
        ),
        title: Text("YOUTUBE VIDEO DOWNLOADER"),
      ),
      body: Center(
        child: Text("Downloading"),
      ),
    );
  }
}
