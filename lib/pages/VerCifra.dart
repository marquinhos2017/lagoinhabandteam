import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class VerCifra extends StatefulWidget {
  final String documentId;
  final bool isAdmin;

  VerCifra({required this.documentId, required this.isAdmin});

  @override
  _VerCifraState createState() => _VerCifraState();
}

class _VerCifraState extends State<VerCifra> {
  late Future<Map<String, dynamic>?> _songDetailsFuture;
  bool _isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String tomOriginal = '';
  String _originalContent = '';
  int _transpositionSteps = 0; // Number of steps for transposition

  @override
  void initState() {
    super.initState();
    _songDetailsFuture = _fetchSongDetails();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
  }

  Future<Map<String, dynamic>?> _fetchSongDetails() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('songs')
        .where('SongId', isEqualTo: widget.documentId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final data = querySnapshot.docs.first.data();
      final content = data['content'] ?? '';

      // Extract the original key from the content
      final tomMatch = RegExp(r'Tom: <(.*?)>').firstMatch(content);
      if (tomMatch != null) {
        tomOriginal = tomMatch.group(1) ?? '';
      }

      _originalContent = content; // Save the original content
      _contentController.text = _transposeChords(content, _transpositionSteps);

      return data;
    } else {
      return null;
    }
  }

  void _enableEditing(Map<String, dynamic> songDetails) {
    setState(() {
      _isEditing = true;
      _titleController.text = songDetails['title'] ?? '';
      // Ensure we update the content controller with transposed content
      _contentController.text =
          _transposeChords(_originalContent, _transpositionSteps);
    });
  }

  Future<void> _saveChanges() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('songs')
        .where('SongId', isEqualTo: widget.documentId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final docId = querySnapshot.docs.first.id;

      await FirebaseFirestore.instance.collection('songs').doc(docId).update({
        'title': _titleController.text,
        'content': _contentController.text,
      });

      setState(() {
        _isEditing = false;
        _songDetailsFuture = _fetchSongDetails();
      });
    }
  }

  Map<String, String> _normalizeNotes = {
    'C': 'C',
    'C#': 'C#',
    'Db': 'C#',
    'D': 'D',
    'D#': 'D#',
    'Eb': 'D#',
    'E': 'E',
    'F': 'F',
    'F#': 'F#',
    'Gb': 'F#',
    'G': 'G',
    'G#': 'G#',
    'Ab': 'G#',
    'A': 'A',
    'A#': 'A#',
    'Bb': 'A#',
    'B': 'B'
  };

  List<String> _notes = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B'
  ];

  String _transposeChords(String content, int steps) {
    final chordRegex = RegExp(r'<([A-G][#b]?)([mM]?[7]?[9]?[11]?[b]?)>');

    return content.replaceAllMapped(chordRegex, (match) {
      final baseChord = match.group(1) ?? '';
      final variations = match.group(2) ?? '';

      // Normalize the baseChord to handle all forms of the same note
      final normalizedChord = _normalizeNotes[baseChord] ?? baseChord;
      final index = _notes.indexOf(normalizedChord);

      if (index != -1) {
        final newIndex = (index + steps) % _notes.length;
        final adjustedIndex = (newIndex + _notes.length) % _notes.length;
        final transposedChord = _notes[adjustedIndex];

        // Return the transposed chord with variations
        return '<${transposedChord}${variations}>';
      }

      // Return the original text if no chord is found
      return match.group(0) ?? '';
    });
  }

  void _increaseTransposition() {
    setState(() {
      _transpositionSteps++;
      _contentController.text =
          _transposeChords(_originalContent, _transpositionSteps);
    });
  }

  void _decreaseTransposition() {
    setState(() {
      _transpositionSteps--;
      _contentController.text =
          _transposeChords(_originalContent, _transpositionSteps);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  RichText buildRichText(String content) {
    final lines = content.split('\n');
    final textSpans = <TextSpan>[];

    for (var line in lines) {
      final chordMatches = RegExp(r'<(.*?)>').allMatches(line);

      if (chordMatches.isEmpty) {
        textSpans.add(
          TextSpan(
            text: line + '\n',
            style: TextStyle(color: Colors.white),
          ),
        );
      } else {
        int lastEnd = 0;

        for (final match in chordMatches) {
          final start = match.start;
          final end = match.end;
          final chord = match.group(1) ?? '';

          if (lastEnd < start) {
            textSpans.add(
              TextSpan(
                text: line.substring(lastEnd, start),
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          textSpans.add(
            TextSpan(
              text: chord,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  _showChordAlert(chord);
                },
            ),
          );

          lastEnd = end;
        }

        if (lastEnd < line.length) {
          textSpans.add(
            TextSpan(
              text: line.substring(lastEnd) + '\n',
              style: TextStyle(color: Colors.white),
            ),
          );
        } else {
          textSpans.add(
            TextSpan(
              text: '\n',
              style: TextStyle(color: Colors.white),
            ),
          );
        }
      }
    }

    return RichText(
      textAlign: TextAlign.start,
      text: TextSpan(
        style: TextStyle(fontSize: 16.0),
        children: textSpans,
      ),
    );
  }

  void _showChordAlert(String chord) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Acorde'),
          content: Text('Você clicou no acorde: $chord'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        title: FutureBuilder<Map<String, dynamic>?>(
          future: _songDetailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text(
                'Carregando...',
                style: TextStyle(color: Colors.white),
              );
            } else if (snapshot.hasError || !snapshot.hasData) {
              return Text('Erro', style: TextStyle(color: Colors.white));
            } else {
              return _isEditing
                  ? TextField(
                      controller: _titleController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Título',
                        hintStyle: TextStyle(color: Colors.white54),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          snapshot.data!['title'] ?? 'Sem título',
                          style: TextStyle(color: Colors.white),
                        ),
                        if (tomOriginal.isNotEmpty)
                          Text(
                            'Tom Original: $tomOriginal',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                      ],
                    );
            }
          },
        ),
        actions: [
          Text(
            tomOriginal,
            style: TextStyle(color: Colors.white),
          ),
          if (widget.isAdmin)
            FutureBuilder<Map<String, dynamic>?>(
              future: _songDetailsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  return IconButton(
                    icon: Icon(_isEditing ? Icons.save : Icons.edit),
                    onPressed: () {
                      if (_isEditing) {
                        _saveChanges();
                      } else {
                        _enableEditing(snapshot.data!);
                      }
                    },
                  );
                } else {
                  return Container();
                }
              },
            ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _songDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Erro ao carregar conteúdo',
                    style: TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData) {
            return Center(
                child: Text('Música não encontrada',
                    style: TextStyle(color: Colors.white)));
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isEditing) // Display the transposition buttons only when editing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _decreaseTransposition,
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.black),
                            foregroundColor:
                                MaterialStateProperty.all<Color>(Colors.blue),
                            padding: MaterialStateProperty.all<EdgeInsets>(
                                EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0)),
                            textStyle: MaterialStateProperty.all<TextStyle>(
                                TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold)),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          child: Text('−1 Semitom'),
                        ),
                        ElevatedButton(
                          onPressed: _increaseTransposition,
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.black),
                            foregroundColor:
                                MaterialStateProperty.all<Color>(Colors.blue),
                            padding: MaterialStateProperty.all<EdgeInsets>(
                                EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0)),
                            textStyle: MaterialStateProperty.all<TextStyle>(
                                TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold)),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          child: Text('+1 Semitom'),
                        ),
                      ],
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _isEditing
                          ? TextField(
                              controller: _contentController,
                              style:
                                  TextStyle(color: Colors.white, fontSize: 15),
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: 'Conteúdo',
                                hintStyle: TextStyle(color: Colors.white54),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                    child:
                                        buildRichText(_contentController.text)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
