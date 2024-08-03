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
      return querySnapshot.docs.first.data();
    } else {
      return null;
    }
  }

  void _enableEditing(Map<String, dynamic> songDetails) {
    setState(() {
      _isEditing = true;
      _titleController.text = songDetails['title'] ?? '';
      _contentController.text = songDetails['content'] ?? '';
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

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Utility function to build RichText with mixed styles
  RichText buildRichText(String content) {
    final lines = content.split('\n');
    final textSpans = <TextSpan>[];

    for (var line in lines) {
      // Find all chord matches and their positions
      final chordMatches = RegExp(r'<(.*?)>').allMatches(line);

      if (chordMatches.isEmpty) {
        // If no chords found, add the whole line as normal text
        textSpans.add(
          TextSpan(
            text: line + '\n',
            style: TextStyle(color: Colors.white),
          ),
        );
      } else {
        int lastEnd = 0;

        // Add text before the first chord
        for (final match in chordMatches) {
          final start = match.start;
          final end = match.end;
          final chord = match.group(1) ?? '';

          // Add text from last match to the start of the current chord
          if (lastEnd < start) {
            textSpans.add(
              TextSpan(
                text: line.substring(lastEnd, start),
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // Add the chord itself with a GestureDetector
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

        // Add any remaining text after the last chord
        if (lastEnd < line.length) {
          textSpans.add(
            TextSpan(
              text: line.substring(lastEnd) + '\n',
              style: TextStyle(color: Colors.white),
            ),
          );
        } else {
          // Ensure a newline is added after the last chord if there's no remaining text
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
                  : Text(
                      snapshot.data!['title'] ?? 'Sem título',
                      style: TextStyle(color: Colors.white),
                    );
            }
          },
        ),
        actions: [
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
              child: SingleChildScrollView(
                child: _isEditing
                    ? TextField(
                        controller: _contentController,
                        style: TextStyle(color: Colors.white, fontSize: 15),
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Conteúdo',
                          hintStyle: TextStyle(color: Colors.white54),
                        ),
                      )
                    : buildRichText(snapshot.data!['content'] ?? ''),
              ),
            );
          }
        },
      ),
    );
  }
}
