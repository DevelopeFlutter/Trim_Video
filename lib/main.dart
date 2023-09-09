import 'package:flutter/material.dart';
import 'package:trim_video/trim_video.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(

home:  VideoRecordingPage());
  }
}

// '-i ${videoFile.path} -ss $startTime -to $endTime -c:v copy -c:a copy $trimmedVideoPath';

