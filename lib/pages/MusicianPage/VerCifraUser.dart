import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class VerCifraUser extends StatefulWidget {
  final String documentId;
  final bool isAdmin;
  final String tone;

  VerCifraUser(
      {required this.documentId, required this.isAdmin, required this.tone});

  @override
  _VerCifraUserState createState() => _VerCifraUserState();
}

class _VerCifraUserState extends State<VerCifraUser> {
  late Future<Map<String, dynamic>?> _songDetailsFuture;
  String _selectedKey = 'C'; // Default key
  final List<String> _keys = [
    'C',
    'C#',
    'Db',
    'D',
    'D#',
    'Eb',
    'E',
    'F',
    'F#',
    'Gb',
    'G',
    'G#',
    'Ab',
    'A',
    'A#',
    'Bb',
    'B'
  ];

  @override
  void initState() {
    super.initState();
    _songDetailsFuture = _fetchSongDetails();
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

  String _transposeChords(String content, String originalKey, String newKey) {
    final chordRegex = RegExp(r'<([A-G][#b]?)([mM]?[7]?[9]?[11]?[b]?)>');
    final normalizedOriginalKey = _normalizeNotes[originalKey] ?? originalKey;
    final normalizedNewKey = widget.tone;

    final originalIndex = _notes.indexOf(normalizedOriginalKey);
    final newIndex = _notes.indexOf(normalizedNewKey);

    if (originalIndex == -1 || newIndex == -1) {
      return content; // Return original content if keys are invalid
    }

    final transpositionSteps =
        (newIndex - originalIndex + _notes.length) % _notes.length;

    return content.replaceAllMapped(chordRegex, (match) {
      final baseChord = match.group(1) ?? '';
      final variations = match.group(2) ?? '';

      // Normalize the baseChord to handle all forms of the same note
      final normalizedChord = _normalizeNotes[baseChord] ?? baseChord;
      final index = _notes.indexOf(normalizedChord);

      if (index != -1) {
        final newIndex = (index + transpositionSteps) % _notes.length;
        final adjustedIndex = (newIndex + _notes.length) % _notes.length;
        final transposedChord = _notes[adjustedIndex];

        // Return the transposed chord with variations
        return '<${transposedChord}${variations}>';
      }

      // Return the original text if no chord is found
      return match.group(0) ?? '';
    });
  }

  final Map<String, String> _normalizeNotes = {
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

  final List<String> _notes = [
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

  RichText buildRichText(String content, String originalKey) {
    final transposedContent =
        _transposeChords(content, originalKey, _selectedKey);
    final lines = transposedContent.split('\n');
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
    List<bool> notas = List.filled(13, false);

    bool buttonC = false;
    bool buttonD = false;
    bool buttonE = false;

    bool ButtonMajor = false;
    bool ButtonMenor = false;
    bool ButtonAug = false;

    int inicial = 0;
    int tipo = 0;

    void Clear() {
      setState(() {
        for (int i = 0; i <= 12; i++) {
          notas[i] = false;
        }
      });
    }

    void Major(int i) {
      Clear();
      setState(() {
        notas[0 + i] = true;
        notas[4 + i] = true;
        notas[7 + i] = true;
      });
    }

    void Menor(int i) {
      Clear();
      setState(() {
        notas[0 + i] = true;
        notas[3 + i] = true;
        notas[7 + i] = true;
      });
    }

    void Aug(int i) {
      Clear();
      setState(() {
        notas[0 + i] = true;
        notas[4 + i] = true;
        notas[8 + i] = true;
      });
    }

    const double altura_brancas = 150;
    const double largura_brancas = 30;
    const double largura_pretas = 20;
    const double altura_pretas = 100;
    final chordFormations = {
      'C': 'C (Tônica), E (Terça maior), G (Quinta justa)',
      'C#': 'C# (Tônica), F (Terça maior), G# (Quinta justa)',
      'Db': 'Db (Tônica), F (Terça maior), Ab (Quinta justa)',
      'D': 'D (Tônica), F# (Terça maior), A (Quinta justa)',
      'D#': 'D# (Tônica), G (Terça maior), A# (Quinta justa)',
      'Eb': 'Eb (Tônica), G (Terça maior), Bb (Quinta justa)',
      'E': 'E (Tônica), G# (Terça maior), B (Quinta justa)',
      'F': 'F (Tônica), A (Terça maior), C (Quinta justa)',
      'F#': 'F# (Tônica), A# (Terça maior), C# (Quinta justa)',
      'Gb': 'Gb (Tônica), Bb (Terça maior), Db (Quinta justa)',
      'G': 'G (Tônica), B (Terça maior), D (Quinta justa)',
      'G#': 'G# (Tônica), B# (Terça maior), D# (Quinta justa)',
      'Ab': 'Ab (Tônica), C (Terça maior), Eb (Quinta justa)',
      'A': 'A (Tônica), C# (Terça maior), E (Quinta justa)',
      'A#': 'A# (Tônica), Cx (Terça maior), E# (Quinta justa)',
      'Bb': 'Bb (Tônica), D (Terça maior), F (Quinta justa)',
      'B': 'B (Tônica), D# (Terça maior), F# (Quinta justa)'
    };

    final chordFormation = chordFormations[chord] ?? 'Formação desconhecida';

    // Determine the chord type
    if (chord == "C") {
      buttonC = true;
      buttonD = false;
      buttonE = false;
      inicial = 0;
      if (tipo == 0) {
        Major(inicial);
      } else if (tipo == 1) {
        Menor(inicial);
      } else if (tipo == 2) {
        Aug(inicial);
      }
    }

    // Determine the chord type
    if (chord == "F") {
      buttonC = true;
      buttonD = false;
      buttonE = false;
      inicial = 5;
      if (tipo == 0) {
        Major(inicial);
      } else if (tipo == 1) {
        Menor(inicial);
      } else if (tipo == 2) {
        Aug(inicial);
      }
    }

    // Determine the chord type
    if (chord == "Em") {
      buttonC = true;
      buttonD = false;
      buttonE = false;
      inicial = 4;
      tipo = 1;
      if (tipo == 0) {
        Major(inicial);
      } else if (tipo == 1) {
        Menor(inicial);
      } else if (tipo == 2) {
        Aug(inicial);
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          content: Container(
            height: 300,
            child: Column(
              children: [
                Text(
                  "$chordFormation",
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(
                  height: altura_brancas,
                  width: 240,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            print("C");
                          },
                          child: Container(
                            width: largura_brancas,
                            height: altura_brancas,
                            decoration: BoxDecoration(
                              color: notas[0] ? Colors.blue : Colors.white,
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(8),
                              ),
                              border: Border.all(
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 30,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            print("D");
                          },
                          child: Container(
                            width: largura_brancas,
                            height: altura_brancas,
                            decoration: BoxDecoration(
                              color: notas[2] ? Colors.blue : Colors.white,
                              border: Border.all(color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 60,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            print("E");
                          },
                          child: Container(
                            width: largura_brancas,
                            height: altura_brancas,
                            decoration: BoxDecoration(
                                color: notas[4] ? Colors.blue : Colors.white,
                                border: Border.all(color: Colors.black)),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 50,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            print("D#");
                          },
                          child: Container(
                            width: largura_pretas,
                            height: altura_pretas,
                            decoration: BoxDecoration(
                                color: notas[3] ? Colors.blue : Colors.black,
                                border: Border.all(color: Colors.black)),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 90,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            print("F");
                          },
                          child: Container(
                            width: largura_brancas,
                            height: altura_brancas,
                            decoration: BoxDecoration(
                                color: notas[5] ? Colors.blue : Colors.white,
                                border: Border.all(color: Colors.black)),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 120,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            print("G");
                          },
                          child: Container(
                            width: largura_brancas,
                            height: altura_brancas,
                            decoration: BoxDecoration(
                                color: notas[7] ? Colors.blue : Colors.white,
                                border: Border.all(color: Colors.black)),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 150,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            print("A");
                          },
                          child: Container(
                            width: largura_brancas,
                            height: altura_brancas,
                            decoration: BoxDecoration(
                                color: notas[9] ? Colors.blue : Colors.white,
                                border: Border.all(color: Colors.black)),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 180,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            print("B");
                          },
                          child: Container(
                            width: largura_brancas,
                            height: altura_brancas,
                            decoration: BoxDecoration(
                                color: notas[11] ? Colors.blue : Colors.white,
                                border: Border.all(color: Colors.black)),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 210,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            print("C - oitavado");
                          },
                          child: Container(
                            width: largura_brancas,
                            height: altura_brancas,
                            decoration: BoxDecoration(
                                color: notas[12] ? Colors.blue : Colors.white,
                                borderRadius: BorderRadius.horizontal(
                                    right: Radius.circular(8)),
                                border: Border.all(color: Colors.black)),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            print("C#");
                          },
                          child: Container(
                            width: largura_pretas,
                            height: altura_pretas,
                            decoration: BoxDecoration(
                                color: notas[1] ? Colors.blue : Colors.black,
                                border: Border.all(color: Colors.black)),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 110,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            print("F#");
                          },
                          child: Container(
                            width: largura_pretas,
                            height: altura_pretas,
                            decoration: BoxDecoration(
                                color: notas[6] ? Colors.blue : Colors.black,
                                border: Border.all(color: Colors.black)),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 140,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            print("G#");
                          },
                          child: Container(
                            width: largura_pretas,
                            height: altura_pretas,
                            decoration: BoxDecoration(
                                color: notas[8] ? Colors.blue : Colors.black,
                                border: Border.all(color: Colors.black)),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 170,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            print("A#");
                          },
                          child: Container(
                            width: largura_pretas,
                            height: altura_pretas,
                            decoration: BoxDecoration(
                                color: notas[10] ? Colors.blue : Colors.black,
                                border: Border.all(color: Colors.black)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
              final songTitle = snapshot.data!['title'] ?? 'Sem título';
              final content = snapshot.data!['content'] ?? '';
              final originalKeyMatch =
                  RegExp(r'Tom: <(.*?)>').firstMatch(content);
              final originalKey = originalKeyMatch?.group(1) ?? 'C';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    songTitle,
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              );
            }
          },
        ),
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
            final content = snapshot.data!['content'] ?? '';
            final originalKey =
                RegExp(r'Tom: <(.*?)>').firstMatch(content)?.group(1) ?? 'C';

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    buildRichText(content, originalKey),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
