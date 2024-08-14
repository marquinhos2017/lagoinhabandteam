import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class VerCifraUserNewUI extends StatefulWidget {
  final String documentId;
  final bool isAdmin;
  final String tone;

  VerCifraUserNewUI(
      {required this.documentId, required this.isAdmin, required this.tone});

  @override
  _VerCifraUserNewUIState createState() => _VerCifraUserNewUIState();
}

class _VerCifraUserNewUIState extends State<VerCifraUserNewUI> {
  bool _isLoading = true; // Estado para controlar o carregamento
  bool _isContentVisible = false; // Estado para controlar o fade-in
  Timer? _fadeInTimer;
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  bool _isUserScrolling = false;
  bool _shouldScroll = true; // Flag to control auto-scrolling
  bool _isAutoScrollEnabled = false; // Controle de rolagem automática
  final Duration _scrollDuration =
      Duration(seconds: 120); // Tempo fixo para rolar do início ao fim

  final Duration _minScrollDuration = Duration(
      milliseconds: 500); // Duração mínima para evitar animações inválidas
  var _isChordsVisible = false;
  late Future<Map<String, dynamic>?> _songDetailsFuture;
  late Future<Map<String, dynamic>?> _informacoesmusicas;
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
    _informacoesmusicas = _informacoesmusica();
    Future<void> _loadData() async {
      // Simula um carregamento com um atraso de 3 segundos
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        _isLoading = false;
        // Inicia o fade-in após o carregamento
        _fadeInTimer = Timer(Duration(milliseconds: 300), () {
          setState(() {
            _isContentVisible = true;
          });
        });
      });
    }

    _loadData();

    _scrollController.addListener(() {
      print("Is Auto Scroll Enabled ?: $_isAutoScrollEnabled");
      //_isUserScrolling = true;
      // print(_scrollController.position);
      if (_scrollController.position.userScrollDirection !=
          ScrollDirection.idle) {
        setState(() {
          _isUserScrolling = false;
          print("Is User Scrolling ? : $_isUserScrolling");
          // _isAutoScrollEnabled = false;
        });
        _scrollTimer?.cancel();
      } else {
        setState(() {
          _isUserScrolling = false;
          // ao chegar no final  ele diz que o Scroll
          //_isUserScrolling = false;
        });
        _startAutoScrollTimer();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
    _fadeInTimer?.cancel(); // Cancela o timer quando o widget for descartado
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

  Future<Map<String, dynamic>?> _informacoesmusica() async {
    final documentSnapshot = await FirebaseFirestore.instance
        .collection('music_database') // Nome da coleção
        .doc(widget.documentId) // ID do documento
        .get();

    if (documentSnapshot.exists) {
      return documentSnapshot.data();
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
            style: TextStyle(color: Colors.black),
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
                style: TextStyle(color: Colors.black),
              ),
            );
          }

          textSpans.add(
            TextSpan(
              text: chord,
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.orange,
        title: Text("Cifra"),
        actions: [
          IconButton(
            icon: Icon(
              _isAutoScrollEnabled ? Icons.stop : Icons.play_arrow,
            ),
            onPressed: () {
              setState(() {
                _isAutoScrollEnabled = !_isAutoScrollEnabled;
                if (_isAutoScrollEnabled) {
                  final overlay = Overlay.of(context);
                  final overlayEntry = OverlayEntry(
                    builder: (context) => Positioned(
                      top: MediaQuery.of(context).size.height *
                          0.1, // Posição no topo
                      left: MediaQuery.of(context).size.width *
                          0.2, // Posição à esquerda
                      right: MediaQuery.of(context).size.width *
                          0.2, // Posição à direita
                      child: _FloatingMessage(
                        "Auto Scroll ON",
                        message: 'Auto Scroll ON',
                      ),
                    ),
                  );

                  overlay.insert(overlayEntry);

                  // Remove a mensagem após 2 segundos
                  Future.delayed(Duration(seconds: 5), () {
                    overlayEntry.remove();
                  });
                } else {
                  final overlay = Overlay.of(context);
                  final overlayEntry = OverlayEntry(
                    builder: (context) => Positioned(
                      top: MediaQuery.of(context).size.height *
                          0.1, // Posição no topo
                      left: MediaQuery.of(context).size.width *
                          0.2, // Posição à esquerda
                      right: MediaQuery.of(context).size.width *
                          0.2, // Posição à direita
                      child: _FloatingMessage(
                        "Auto Scroll OFF",
                        message: 'Auto Scroll OFF',
                      ),
                    ),
                  );

                  overlay.insert(overlayEntry);

                  // Remove a mensagem após 2 segundos
                  Future.delayed(Duration(seconds: 5), () {
                    overlayEntry.remove();
                  });
                }
                if (_scrollController.hasClients) {
                  final newOffset = _scrollController.offset -
                      0; // Ajuste o valor conforme necessário
                  _scrollController.animateTo(
                    newOffset.clamp(
                        0.0, _scrollController.position.maxScrollExtent),
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                  print(_scrollController.position);
                }
              });

              if (_isAutoScrollEnabled) {
                _scrollToBottom();
              } else {
                _scrollTimer?.cancel();
              }

              print("Print: Valor do IsAutoScroll $_isAutoScrollEnabled");
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Widget de carregamento
          Visibility(
            visible: _isLoading,
            child: LoadingWidget(),
          ),
          // Conteúdo com fade-in
          AnimatedOpacity(
            opacity: _isContentVisible ? 1.0 : 0.0,
            duration: Duration(milliseconds: 500),
            child: _isLoading
                ? SizedBox
                    .shrink() // Mantém o espaço quando o conteúdo não está visível
                : Column(
                    children: [
                      Expanded(
                        child: FutureBuilder<Map<String, dynamic>?>(
                          future: _songDetailsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
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
                              final originalKey = RegExp(r'Tom: <(.*?)>')
                                      .firstMatch(content)
                                      ?.group(1) ??
                                  'C';

                              return GestureDetector(
                                onVerticalDragCancel: () {
                                  print(
                                      " Is Auto Scroll, ao Clicar: $_isAutoScrollEnabled");
                                  if (_isAutoScrollEnabled == true) {
                                    _handleTap();
                                  }
                                },
                                child: SingleChildScrollView(
                                  controller: _scrollController,
                                  child: Column(
                                    children: [
                                      Container(
                                        child: Column(
                                          children: [
                                            FutureBuilder<
                                                Map<String, dynamic>?>(
                                              future: _informacoesmusicas,
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return Text(
                                                    'Carregando...',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  );
                                                } else if (snapshot.hasError ||
                                                    !snapshot.hasData) {
                                                  return Text('Erro',
                                                      style: TextStyle(
                                                          color: Colors.white));
                                                } else {
                                                  final songTitle =
                                                      snapshot.data!['Music'] ??
                                                          'Sem título';
                                                  final songAuthor = snapshot
                                                          .data!['Author'] ??
                                                      'Sem título';

                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        songTitle,
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 32),
                                                      ),
                                                      Text(
                                                        songAuthor,
                                                        style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: 20),
                                                      ),
                                                      Container(
                                                        margin: EdgeInsets.only(
                                                            top: 12),
                                                        width: 60,
                                                        height: 70,
                                                        decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            12)),
                                                            color:
                                                                Colors.white),
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              ("Tom"),
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .black,
                                                                  fontSize: 12),
                                                            ),
                                                            Text(
                                                              (widget.tone),
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .orange,
                                                                  fontSize: 32),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          _isChordsVisible
                                                              ? Icons
                                                                  .expand_less
                                                              : Icons
                                                                  .expand_more,
                                                          color: Colors.white,
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _isChordsVisible =
                                                                !_isChordsVisible;
                                                          });
                                                        },
                                                      ),
                                                      AnimatedContainer(
                                                        duration: Duration(
                                                            milliseconds: 300),
                                                        curve: Curves.easeInOut,
                                                        height: _isChordsVisible
                                                            ? 150 // Defina a altura desejada quando visível
                                                            : 0, // Expande e colapsa a altura
                                                        child: AnimatedOpacity(
                                                          duration: Duration(
                                                              milliseconds:
                                                                  300),
                                                          opacity: _isChordsVisible
                                                              ? 1
                                                              : 0, // Controla a opacidade
                                                          child:
                                                              _isChordsVisible
                                                                  ? Container(
                                                                      margin: EdgeInsets.only(
                                                                          top:
                                                                              8,
                                                                          bottom:
                                                                              8),
                                                                      padding:
                                                                          EdgeInsets.all(
                                                                              12),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Colors
                                                                            .white,
                                                                        borderRadius:
                                                                            BorderRadius.circular(12),
                                                                        boxShadow: [
                                                                          BoxShadow(
                                                                            color:
                                                                                Colors.black.withOpacity(0.1),
                                                                            blurRadius:
                                                                                8,
                                                                            offset:
                                                                                Offset(0, 4),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      child:
                                                                          Text(
                                                                        'Aqui vão os acordes para violão...',
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              Colors.black,
                                                                          fontSize:
                                                                              16,
                                                                        ),
                                                                      ),
                                                                    )
                                                                  : SizedBox
                                                                      .shrink(),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                          width:
                                              MediaQuery.sizeOf(context).width,
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(29))),
                                          child: Padding(
                                            padding: const EdgeInsets.all(24.0),
                                            child: buildRichText(
                                                content, originalKey),
                                          )),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          // Botões flutuantes
          Visibility(
            visible: _isAutoScrollEnabled,
            child: Positioned(
              bottom: 40,
              right: 20,
              //   left: 0,
              // top: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, // Cor de fundo do botão
                      borderRadius:
                          BorderRadius.circular(16), // Define o raio da borda
                      border: Border.all(
                        color: Colors.white, // Cor da borda
                        width: 0.2, // Largura da borda
                      ),
                    ),
                    child: FloatingActionButton(
                      heroTag: 'scroll_up_button', // Unique tag for this button
                      onPressed: _scrollUp,
                      child: Icon(Icons.arrow_upward),
                      foregroundColor: Colors.orange,

                      backgroundColor: Colors.white,

                      tooltip: 'Scroll Up',
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, // Cor de fundo do botão
                      borderRadius:
                          BorderRadius.circular(16), // Define o raio da borda
                      border: Border.all(
                        color: Colors.white, // Cor da borda
                        width: 0.2, // Largura da borda
                      ),
                    ),
                    child: FloatingActionButton(
                      heroTag:
                          'scroll_down_button', // Unique tag for this button
                      onPressed: _scrollDown,
                      child: Icon(
                        Icons.arrow_downward,
                        color: Colors.orange,
                      ),
                      foregroundColor: Colors.orange,

                      backgroundColor: Colors.white,
                      tooltip: 'Scroll Down',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollUp() {
    if (_scrollController.hasClients) {
      final newOffset =
          _scrollController.offset - 100; // Ajuste o valor conforme necessário
      _scrollController.animateTo(
        newOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    print(
        "Clicado para cima: Estao do _IsAutoScroll" + "$_isAutoScrollEnabled");
  }

  void _scrollDown() {
    if (_scrollController.hasClients) {
      final newOffset =
          _scrollController.offset + 100; // Ajuste o valor conforme necessário
      _scrollController.animateTo(
        newOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    print(
        "Clicado para baixo: Estao do _IsAutoScroll" + "$_isAutoScrollEnabled");
  }

  void _scrollToBottom() {
    print(_isAutoScrollEnabled);
    if (mounted && _scrollController.hasClients) {
      final currentPosition = _scrollController.offset;
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final distanceToBottom = maxScrollExtent - currentPosition;

      final calculatedDuration =
          _scrollDuration * (distanceToBottom / maxScrollExtent);

      final scrollDuration = calculatedDuration > _minScrollDuration
          ? calculatedDuration
          : _minScrollDuration; // Garantir que a duração não seja menor que o mínimo

      if (_isAutoScrollEnabled) {
        _scrollController.animateTo(
          maxScrollExtent,
          duration: scrollDuration,
          curve: Curves.linear,
        );
      }
    }
  }

  void _startAutoScrollTimer() {
    _scrollTimer?.cancel(); // Cancelar temporizador existente
    _scrollTimer = Timer(Duration(milliseconds: 300), () {
      if (mounted && !_isUserScrolling) {
        setState(() {
          _isAutoScrollEnabled = true; // Reativar rolagem automática
        });
        _scrollToBottom();
      }
    });
  }

  void _handleTap() {
    setState(() {
      _isAutoScrollEnabled = false; // Desativar rolagem automática
    });
    _scrollTimer?.cancel(); // Cancelar temporizador existente

    // Iniciar um temporizador para reativar a rolagem automática após 3 segundos
    Timer(Duration(milliseconds: 3000), () {
      if (mounted) {
        // Verificar se ainda está montado
        setState(() {
          _isAutoScrollEnabled = true;
        });
        _scrollToBottom(); // Continuar a rolagem automática a partir da posição atual
      }
    });
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
}

// Definição do widget de mensagem flutuante com animação de fade-in
class _FloatingMessage extends StatefulWidget {
  late String message;
  _FloatingMessage(String s, {super.key, required this.message});

  @override
  _FloatingMessageState createState() => _FloatingMessageState();
}

class _FloatingMessageState extends State<_FloatingMessage>
    with SingleTickerProviderStateMixin {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Trigger the fade-in effect after the first frame is rendered
    // Fade-in effect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _opacity = 1.0;
      });

      // Wait for 1 second while fully visible, then trigger fade-out
      Future.delayed(Duration(seconds: 3), () {
        setState(() {
          _opacity = 0.0;
        });
      });
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: Duration(milliseconds: 500),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white, // Fundo branco
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: Offset(0, 4), // Deslocamento da sombra
                blurRadius: 8, // Raio de desfoque
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.message,
              style: TextStyle(
                color: Colors.orange, // Texto laranja
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(), // Indicador de carregamento circular
    );
  }
}
