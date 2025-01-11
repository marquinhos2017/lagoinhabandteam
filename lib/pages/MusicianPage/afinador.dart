/*

import 'dart:math';
import 'dart:typed_data';


import 'package:flutter/material.dart';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:lagoinha_music/main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:pitchupdart/instrument_type.dart';
import 'package:pitchupdart/pitch_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Afinador());
}

class Afinador extends StatelessWidget {
  const Afinador({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tuner Simple',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    _checkPermission();
    _initializeAudioCapture();
  }

  bool _hasPitchDetectingStarted = false;
  bool iniciado = false;
  Color backgroundColor = Colors.black;
  Color textColor = Colors.white;

  final _audioRecorder = FlutterAudioCapture();

  final pitchDetectorDart =
      PitchDetector(audioSampleRate: 44100, bufferSize: 3000);
  final pitchupDart = PitchHandler(InstrumentType.guitar);

  var note = '';
  var status = 'Press the Image!';

  Future<void> _initializeAudioCapture() async {
    try {
      await _audioRecorder
          .init(); // Chame o método de inicialização se houver um
    } catch (e) {
      print('Erro ao inicializar o capturador de áudio: $e');
    }
  }

  Future<void> _checkPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  Future<void> _startCapture() async {
    await _audioRecorder.start(_listener, _onError,
        sampleRate: 44100, bufferSize: 3000);
    setState(() {
      note = '';
      status = 'Please Sing!';
      _hasPitchDetectingStarted = true;
    });
  }

  Future<void> _stopCapture() async {
    await _audioRecorder.stop();
    setState(() {
      note = '';
      status = 'Press Start!';
      _hasPitchDetectingStarted = false;
      backgroundColor = Colors.black;
      textColor = Colors.white;
    });
  }

  double _calculateRMS(List<double> samples) {
    double sumOfSquares =
        samples.fold(0.0, (prev, sample) => prev + sample * sample);
    return sqrt(sumOfSquares / samples.length);
  }

  void _listener(dynamic obj) async {
    var buffer = Float64List.fromList(obj.cast<double>());
    final List<double> audioSample = buffer.toList();
    double rms = _calculateRMS(audioSample);
    double volumeThreshold = 0.005;

    if (rms > volumeThreshold) {
      try {
        // Await the future to get the result
        final result =
            await pitchDetectorDart.getPitchFromFloatBuffer(audioSample);

        // Ensure result is not null and has a valid pitch
        if (result != null && result.pitch != -1.0) {
          _updateNoteAndColor(result.pitch);
        }
      } catch (e) {
        print('Error detecting pitch: $e');
      }
    }
  }

  void _updateNoteAndColor(double pitch) {
    Color correctColor = Colors.green;
    Color incorrectColor = Colors.red;

    String newNote = '';
    Color newBackgroundColor = backgroundColor;
    Color newTextColor = textColor;

    if (pitch >= 70 && pitch <= 350) {
      newNote = _determineNoteBasedOnPitch(pitch);

      if (newNote.isNotEmpty) {
        iniciado = true;
        if (_isPitchInRange(pitch, newNote)) {
          newBackgroundColor = correctColor;
          newTextColor = Colors.black;
        } else {
          newBackgroundColor = incorrectColor;
          newTextColor = Colors.white;
        }
      }
    }

    setState(() {
      note = newNote;
      backgroundColor = newBackgroundColor;
      textColor = newTextColor;
    });
  }

  String _determineNoteBasedOnPitch(double pitch) {
    if (pitch >= 72 && pitch <= 92) return "E";
    if (pitch >= 92 && pitch <= 120) return "A";
    if (pitch >= 136 && pitch <= 186) return "D";
    if (pitch >= 186 && pitch <= 206) return "G";
    if (pitch >= 237 && pitch <= 257) return "B";
    if (pitch >= 320 && pitch <= 340) return "E";
    return '';
  }

  bool _isPitchInRange(double pitch, String note) {
    Map<String, List<double>> noteRanges = {
      "E": [81.8, 82.2],
      "A": [109, 111],
      "D": [145, 147],
      "G": [195, 197],
      "B": [246.8, 247.2],
    };

    List<double>? range = noteRanges[note];
    if (range != null) {
      return pitch >= range[0] && pitch <= range[1];
    }
    return false;
  }

  void _onError(Object e) {
    print(e);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          title: Text(
            "HomeScreen",
            style: TextStyle(color: Colors.black),
          ),
        ),
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Visibility(
                visible: _hasPitchDetectingStarted,
                child: Text(
                  note,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 180,
                  ),
                ),
              ),
              Visibility(
                visible: !_hasPitchDetectingStarted,
                child: ElevatedButton(
                  child: Text(
                    "Afinar",
                  ),
                  onPressed: _startCapture,
                ),
              ),
              Visibility(
                visible: _hasPitchDetectingStarted && iniciado,
                child: ElevatedButton(
                  child: Text(
                    "Parar",
                  ),
                  onPressed: _stopCapture,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



*/
