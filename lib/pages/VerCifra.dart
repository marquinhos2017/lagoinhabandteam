import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class VerCifra extends StatelessWidget {
  final String documentId;

  VerCifra({required this.documentId});

  Future<Map<String, dynamic>?> _fetchSongDetails() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('songs')
        .where('SongId', isEqualTo: documentId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data();
    } else {
      return null;
    }
  }

  List<TextSpan> _parseContent(BuildContext context, String content) {
    final spans = <TextSpan>[];
    final lines = content.split('\n');

    for (var line in lines) {
      final trimmedLine = line.trim();

      if (trimmedLine.isEmpty) {
        spans.add(TextSpan(text: '\n'));
      } else {
        final isChordLine = _isChordLine(trimmedLine);

        if (isChordLine) {
          spans.add(TextSpan(
            text: line + '\n',
            style: TextStyle(color: Colors.blue, fontFamily: 'monospace'),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _showChordDialog(context, trimmedLine);
              },
          ));
        } else {
          spans.add(TextSpan(
            text: line + '\n',
            style: TextStyle(color: Colors.black, fontSize: 16),
          ));
        }
      }
    }

    return spans;
  }

  bool _isChordLine(String line) {
    final trimmedLine = line.trim();

    if (trimmedLine.isEmpty) {
      return false;
    }

    final chordPattern = RegExp(
      r'^([A-Ga-g][#b]?m?(maj|min|dim|aug|sus[24]?|add[0-9]*|7|9|11|13)?|[A-Ga-g][#b]?/[A-Ga-g][#b]?|[A-Ga-g][#b]?maj7?|[A-Ga-g][#b]?m7?|[A-Ga-g][#b]?7?)(\s+[A-Ga-g][#b]?[m|maj|min|dim|aug|sus[24]?|add[0-9]*|7|9|11|13]?)*$',
      caseSensitive: false,
    );

    return chordPattern.hasMatch(trimmedLine);
  }

  void _showChordDialog(BuildContext context, String chord) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cifra'),
          content: Text('Você clicou na cifra: $chord'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>?>(
          future: _fetchSongDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Carregando...');
            } else if (snapshot.hasError || !snapshot.hasData) {
              return Text('Erro');
            } else {
              return Text(snapshot.data!['title'] ?? 'Sem título');
            }
          },
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchSongDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar conteúdo'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('Música não encontrada'));
          } else {
            final content = snapshot.data!['content'] ?? '';
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: RichText(
                  text: TextSpan(
                    children: _parseContent(context, content),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
