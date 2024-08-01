import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SongDetailPage extends StatelessWidget {
  final String title;
  final String content;

  SongDetailPage({required this.title, required this.content});

  List<TextSpan> _parseContent(BuildContext context, String content) {
    final spans = <TextSpan>[];
    final lines = content.split('\n');

    for (var line in lines) {
      final trimmedLine = line.trim();

      if (trimmedLine.isEmpty) {
        spans.add(TextSpan(text: '\n'));
      } else {
        // Determine if the line is a chord line or lyrics line
        final isChordLine = _isChordLine(trimmedLine);

        if (isChordLine) {
          // Line contains chords
          spans.add(TextSpan(
            text: line + '\n',
            style: TextStyle(color: Colors.blue, fontFamily: 'monospace'),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _showChordDialog(context, trimmedLine);
              },
          ));
        } else {
          // Line contains lyrics
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

    // Expressão regular para identificar cifras
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
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: RichText(
            text: TextSpan(
              children: _parseContent(context, content),
            ),
          ),
        ),
      ),
    );
  }
}
