import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

class Verletra extends StatefulWidget {
  final String documentId;
  final bool isAdmin;

  Verletra({required this.documentId, required this.isAdmin});

  @override
  _VerCifraUserState createState() => _VerCifraUserState();
}

class _VerCifraUserState extends State<Verletra> {
  final ScrollController _scrollController = ScrollController();
  bool _isEditing = false;
  Timer? _scrollTimer;
  Timer? _userScrollTimer;
  bool _isAutoScrollEnabled = false;
  bool _isDarkMode = false; // Variable to control dark mode
  final Duration _scrollDuration = const Duration(seconds: 120);
  final Duration _minScrollDuration = const Duration(milliseconds: 500);
  final Duration _userInactivityDuration = const Duration(seconds: 3);

  TextEditingController _lyricsController = TextEditingController();

  late Future<Map<String, dynamic>?> _songDetailsFuture;

  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _songDetailsFuture = _fetchSongDetails();

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection !=
          ScrollDirection.idle) {
        _scrollTimer?.cancel();
        _userScrollTimer?.cancel();
        _isAutoScrollEnabled = false;
      } else if (_isAutoScrollEnabled) {
        _startAutoScrollTimer();
      }
    });
  }

  void _enableEditing(Map<String, dynamic> songDetails) {
    setState(() {
      _isEditing = true;
      // Atribua a letra carregada ao controlador de texto
      _lyricsController.text = songDetails['letra']?.replaceAll('\\n', '\n') ??
          'Letra não disponível';
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollTimer?.cancel();
    _userScrollTimer?.cancel();
    super.dispose();
  }

  void HandleTab() {
    setState(() {
      _isAutoScrollEnabled = false;
    });
    _scrollTimer?.cancel();

    Timer(Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          _isAutoScrollEnabled = true;
        });
        _scrollToBottom();
      }
    });
  }

  Future<Map<String, dynamic>?> _fetchSongDetails() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('music_database')
          .doc(widget.documentId)
          .get();
      return docSnapshot.data();
    } catch (e) {
      print('Erro ao buscar detalhes da música: $e');
      return null;
    }
  }

  void _toggleAutoScroll() {
    setState(() {
      _isAutoScrollEnabled = !_isAutoScrollEnabled;
      if (_isAutoScrollEnabled) {
        _scrollToBottom();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color(0xff4465D9),
            content: Text('Rolagem Automática Ativada'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        _scrollTimer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Rolagem Automática Desativada'),
            duration: Duration(seconds: 1),
          ),
        );
        _scrollController.jumpTo(_scrollController.offset);
      }
    });
  }

  Future<void> _saveChanges() async {
    try {
      await FirebaseFirestore.instance
          .collection('music_database')
          .doc(widget.documentId)
          .update({'letra': _lyricsController.text});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Letra atualizada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _songDetailsFuture = _fetchSongDetails(); // Recarrega os dados
        _isEditing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar a letra: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final currentOffset = _scrollController.offset;
      final distanceToScroll = maxScrollExtent - currentOffset;
      final calculatedDuration =
          _scrollDuration * (distanceToScroll / maxScrollExtent);

      final scrollDuration = (calculatedDuration.inMilliseconds <
              _minScrollDuration.inMilliseconds)
          ? _minScrollDuration
          : Duration(milliseconds: calculatedDuration.inMilliseconds);

      _scrollController.animateTo(
        maxScrollExtent,
        duration: scrollDuration,
        curve: Curves.linear,
      );
    }
  }

  void _startAutoScrollTimer() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(Duration(milliseconds: 300), () {
      if (mounted && _isAutoScrollEnabled) {
        _scrollToBottom();
      }
    });
  }

  void _startUserInactivityTimer() {
    _userScrollTimer?.cancel();
    _userScrollTimer = Timer(_userInactivityDuration, () {
      setState(() {
        _isAutoScrollEnabled = true;
        _scrollToBottom();
      });
    });
  }

  void _increaseFontSize() {
    setState(() {
      _fontSize += 2.0;
    });
  }

  void _decreaseFontSize() {
    setState(() {
      if (_fontSize > 10) _fontSize -= 2.0;
    });
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Faz com que nao consiga voltar caso eu esteja editando a letra
      canPop: !_isEditing, //
      child: Scaffold(
        backgroundColor: _isDarkMode ? Colors.black : Colors.white,
        appBar: AppBar(
          foregroundColor: _isDarkMode ? Colors.white : Colors.white,
          backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.black,
          title: FutureBuilder<Map<String, dynamic>?>(
            future: _songDetailsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text('Carregando...',
                    style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.white));
              } else if (snapshot.hasError || !snapshot.hasData) {
                return Text('Erro',
                    style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black));
              } else {
                final songTitle = snapshot.data!['Music'] ?? 'Sem título';
                return Text("Lyrics: " + songTitle,
                    style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.white));
              }
            },
          ),
          actions: [
            FutureBuilder<Map<String, dynamic>?>(
              future: _songDetailsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(); // Optionally add a loading indicator
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return IconButton(
                    icon: Icon(Icons.error),
                    onPressed: null, // Handle error here
                  );
                } else {
                  return IconButton(
                    icon: Icon(_isEditing ? Icons.save : Icons.edit),
                    onPressed: () {
                      if (_isEditing) {
                        _saveChanges();
                      } else {
                        final songDetails = snapshot.data;
                        if (songDetails != null) {
                          _enableEditing(
                              songDetails); // Enable editing when the user presses the edit icon
                        }
                      }
                    },
                  );
                }
              },
            ),
            IconButton(
              icon: Icon(_isAutoScrollEnabled ? Icons.stop : Icons.play_arrow),
              onPressed: _toggleAutoScroll,
            ),
            Switch(
              value: _isDarkMode,
              onChanged: _toggleDarkMode,
              activeColor: Colors.white,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey,
              activeTrackColor: Colors.black,
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
                child: Text('Erro ao carregar conteúdo: ${snapshot.error}',
                    style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black)),
              );
            } else if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                child: Text('Música não encontrada',
                    style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black)),
              );
            } else {
              final songDetails = snapshot.data!;
              final letra = songDetails['letra']?.replaceAll('\\n', '\n') ??
                  'Letra não disponível';

              return GestureDetector(
                onVerticalDragCancel: () {
                  if (_isAutoScrollEnabled) {
                    HandleTab();
                  }
                },
                child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _isEditing
                          ? TextField(
                              controller: _lyricsController,
                              style:
                                  TextStyle(color: Colors.black, fontSize: 15),
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: 'Conteúdo',
                                hintStyle: TextStyle(color: Colors.white54),
                              ),
                            )
                          : Text(
                              letra,
                              textAlign: TextAlign.left,
                              style: GoogleFonts.montserrat(
                                textStyle: TextStyle(
                                  color:
                                      _isDarkMode ? Colors.white : Colors.black,
                                  fontSize: _fontSize,
                                ),
                              ),
                            ),
                    )),
              );
            }
          },
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'unique_tag_for_hero',
              onPressed: _increaseFontSize,
              backgroundColor: _isDarkMode ? Colors.white : Colors.black,
              child: Icon(Icons.add,
                  color: _isDarkMode ? Colors.black : Colors.white),
            ),
            SizedBox(height: 12),
            FloatingActionButton(
              onPressed: _decreaseFontSize,
              backgroundColor: _isDarkMode ? Colors.white : Colors.black,
              child: Icon(Icons.remove,
                  color: _isDarkMode ? Colors.black : Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
