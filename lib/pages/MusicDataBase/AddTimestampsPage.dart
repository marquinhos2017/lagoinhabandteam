import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTimestampsPage extends StatefulWidget {
  final String title;
  final String document_id;

  AddTimestampsPage({required this.title, required this.document_id});

  @override
  _AddTimestampsPageState createState() => _AddTimestampsPageState();
}

class _AddTimestampsPageState extends State<AddTimestampsPage> {
  final TextEditingController timestampController = TextEditingController();
  final TextEditingController lyricController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _addLyric() async {
    final timestampText = timestampController.text;
    final lyricText = lyricController.text;

    if (timestampText.isEmpty || lyricText.isEmpty) {
      // Handle empty fields
      return;
    }

    try {
      final parts = timestampText.split(':');
      if (parts.length != 2)
        throw FormatException("Formato de timestamp inválido");

      final minutes = int.parse(parts[0]);
      final seconds = double.parse(parts[1]);

      final timestamp = Duration(
        minutes: minutes,
        seconds: seconds.toInt(),
        milliseconds: ((seconds - seconds.toInt()) * 1000).toInt(),
      );

      // Salvar no Firestore
      await _firestore.collection('lrcs').add({
        'lyrics_id': widget.document_id,
        'timestamp': timestamp.inMilliseconds,
        'lyric': lyricText,
      });

      setState(() {
        timestampController.clear();
        lyricController.clear();
      });

      // Optionally show a confirmation message
    } catch (e) {
      print('Erro ao adicionar letra: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Timestamps e Letras'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: timestampController,
              decoration: InputDecoration(
                labelText: 'Timestamp (mm:ss)',
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.datetime,
            ),
            TextField(
              controller: lyricController,
              decoration: InputDecoration(
                labelText: 'Letra',
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.multiline,
              maxLines: null, // This allows for multi-line input
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addLyric,
              child: Text('Adicionar Letra'),
            ),
          ],
        ),
      ),
    );
  }
}
