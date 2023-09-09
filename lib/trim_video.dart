// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, prefer_typing_uninitialized_variables, depend_on_referenced_packages, unused_import, duplicate_import, sort_child_properties_last

import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:flutter_ffmpeg/media_information.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';

// import 'package:video_watermark/video_watermark.dart';



class VideoRecordingPage extends StatefulWidget {
  const VideoRecordingPage({super.key});

  @override
  _VideoRecordingPageState createState() => _VideoRecordingPageState();
}

class _VideoRecordingPageState extends State<VideoRecordingPage> {
  CameraController? _controller;
  bool isRecording = false;
  dynamic videoFile;
  var timer;
  dynamic recordingTime = '0:0';
  dynamic duration;
  String logoPath = 'assets/image/Logo.png';
  dynamic trimmedVide;
  dynamic logPath;
  dynamic previousVideo;


  void videoRecordingTimer() {
    var startTime = DateTime.now();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      var diff = DateTime.now().difference(startTime);
      recordingTime =
          '${diff.inHours < 60 ? diff.inHours : 0}:${diff.inMinutes < 60 ? diff.inMinutes : 0}:${diff.inSeconds < 60 ? diff.inSeconds : diff.inSeconds % 60}';
      if (recordingTime == '0:5:0') {
        timer.cancel();
        startRecordingAgain();
      }
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  _initCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;
    _controller = CameraController(camera, ResolutionPreset.medium);
    await _controller?.initialize();
    setState(() {});
  }

  _startRecording() async {
    if (_controller != null && !_controller!.value.isRecordingVideo) {
      videoRecordingTimer();
      await _controller?.startVideoRecording();
      setState(() {
        isRecording = true;
      });
    }
  }

// This is for Stop Video Recording 
  _stopRecording() async {
    if (_controller?.value.isRecordingVideo ?? false) {
      videoFile = await _controller?.stopVideoRecording();
      setState(() {
        isRecording = false;
        timer.cancel();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video Recorded Stop and Saved')),
      );
    }
  }
// This is for save video into Gallery
  // storeTrimmedVideoInGallery(dynamic videoPath) async {
  //   await Gal.putVideo(videoPath, album: 'trimmedVideo');
  // }
  // This function is for save video and  start again recording

  _saveReplay() async {
    if (_controller?.value.isRecordingVideo ?? false) {
      videoFile = await _controller?.stopVideoRecording();
      setState(() {
        isRecording = false;
      });
      _trimAndSaveLast30Seconds();
      timer.cancel();
      if (videoFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Replay save')),
        );
      }
    }
    await _controller?.startVideoRecording();
    setState(() {
      videoRecordingTimer();
      isRecording = true;
    });
  }

// This function is for again start recording of a video
  startRecordingAgain() async {
    if (_controller?.value.isRecordingVideo ?? false) {
      videoFile = await _controller?.stopVideoRecording();
      setState(() {
        isRecording = false;
      });
      timer.cancel();
      if (videoFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Replay again')),
        );
      }
    }
    await _controller?.startVideoRecording();
    setState(() {
      videoRecordingTimer();
      isRecording = true;
    });
  }
  // get asset from assets 
  Future<String> extractAsset(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Directory tempDir = await getTemporaryDirectory();
    final String tempPath = p.join(tempDir.path, p.basename(assetPath));
    final File tempFile = File(tempPath);
    await tempFile.writeAsBytes(data.buffer.asUint8List());
    return tempPath;
  }
// get video last 30 seconds
  Future<void> _trimAndSaveLast30Seconds() async {

    final Directory? appDir = await getExternalStorageDirectory();
    File file = File('${appDir!.path}/my_file.txt');
    final Directory download = Directory(
        '/storage/emulated/0/Download');
    final String uniqueVideoId =
        DateTime.now().millisecondsSinceEpoch.toString();

    dynamic videoDuration = await _getVideoDurationInSeconds(videoFile!.path);

    final int startTime = videoDuration - 30;
    final int endTime = videoDuration;
    final FlutterFFmpeg ffmpeg = FlutterFFmpeg();
    logPath= await extractAsset(logoPath);

    final String previousVideo =
        '${appDir!.path}/final_video$uniqueVideoId.mp4';

    dynamic command =
    '-i ${videoFile.path} -ss $startTime -to $endTime -c:v copy -c:a copy $previousVideo';
    final overlayCommand =
        '-i $previousVideo -i $logPath -filter_complex "[1:v]scale=150:50[logo];[0:v][logo]overlay=5:10" '
        '${ '${download.path}/${uniqueVideoId}final_video.mp4'}';
    final int result = await ffmpeg.execute(command);
    if (result == 0) {
      final int overlayResult = await ffmpeg.execute(overlayCommand);

      log('$overlayResult overLayResult');
    }

    else {
      log('Error trimming video: FFmpeg returned non-zero status');
    }

  }
//get previous  video duratiuon

  Future<int> _getVideoDurationInSeconds(dynamic videoPath) async {
    final FlutterFFprobe flutterFFprobe = FlutterFFprobe();
    final MediaInformation info =
        await flutterFFprobe.getMediaInformation(videoPath.toString());

    final Map? mediaProperties = info.getMediaProperties();
    log('$mediaProperties media ');

    if (mediaProperties != null) {
      final String? durationString = mediaProperties['duration'];
      log('$durationString duration ');

      if (durationString != null) {
        final double duration = double.parse(durationString);
        log('$durationString double ');

        return duration.toInt();
      }
    }

    return 0;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Recording'),
      ),
      body: OrientationBuilder(
          builder: (BuildContext context, Orientation orientation) {
        return Center(
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              if (isRecording) Text(recordingTime),
              if (_controller != null && _controller!.value.isInitialized)
                Expanded(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: CameraPreview(_controller!),
                  ),
                ),
              if (isRecording) const Text('Recording Continued...'),
              ElevatedButton(
                child: const Text('Start recording'),
                onPressed: _startRecording,
              ),
              ElevatedButton(
                child: const Text('Save and  Replay'),
                onPressed: _saveReplay,
              ),
              ElevatedButton(
                child: const Text('Stop Recording'),
                onPressed: _stopRecording,
              ),
            ],
          ),
        );
      }),
    );
  }
}
