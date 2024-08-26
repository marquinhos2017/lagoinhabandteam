import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class Verletra extends StatefulWidget {
  final String documentId;
  final bool isAdmin;

  Verletra({required this.documentId, required this.isAdmin});

  @override
  _VerCifraUserState createState() => _VerCifraUserState();
}

class _VerCifraUserState extends State<Verletra> {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  Timer? _userScrollTimer; // Timer to handle user inactivity
  bool _isAutoScrollEnabled = false; // Controle de rolagem automática
  final Duration _scrollDuration =
      Duration(seconds: 120); // Tempo fixo para rolar do início ao fim
  final Duration _minScrollDuration = Duration(
      milliseconds: 500); // Duração mínima para evitar animações inválidas
  final Duration _userInactivityDuration =
      Duration(seconds: 3); // Tempo de inatividade do usuário
  late Future<Map<String, dynamic>?> _songDetailsFuture;

  @override
  void initState() {
    super.initState();
    _songDetailsFuture = _fetchSongDetails();

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection !=
          ScrollDirection.idle) {
        // Se o usuário estiver rolando manualmente, cancelar a rolagem automática e iniciar o temporizador de inatividade
        _scrollTimer?.cancel();
        _userScrollTimer?.cancel();
        _isAutoScrollEnabled = false;
      } else if (_isAutoScrollEnabled) {
        // Reiniciar o temporizador de rolagem automática se estiver habilitado
        _startAutoScrollTimer();
      }
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
      _isAutoScrollEnabled = false; // Desativar rolagem automática
    });
    _scrollTimer?.cancel(); // Cancelar temporizador existente

    // Iniciar um temporizador para reativar a rolagem automática após 3 segundos
    Timer(Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          _isAutoScrollEnabled = true;
        });
        _scrollToBottom(); // Continuar a rolagem automática a partir da posição atual
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
        // Parar a rolagem instantaneamente
        _scrollController.jumpTo(_scrollController.offset);
      }
    });
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
          : Duration(
              milliseconds: calculatedDuration
                  .inMilliseconds); // Garantir que a duração não seja menor que o mínimo

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        title: FutureBuilder<Map<String, dynamic>?>(
          future: _songDetailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Carregando...',
                  style: TextStyle(color: Colors.white));
            } else if (snapshot.hasError || !snapshot.hasData) {
              return Text('Erro', style: TextStyle(color: Colors.white));
            } else {
              final songTitle = snapshot.data!['Music'] ?? 'Sem título';
              return Text("Lyrics: " + songTitle,
                  style: TextStyle(color: Colors.white));
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isAutoScrollEnabled ? Icons.stop : Icons.play_arrow),
            onPressed: _toggleAutoScroll,
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
                    style: TextStyle(color: Colors.black)));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(
                child: Text('Música não encontrada',
                    style: TextStyle(color: Colors.black)));
          } else {
            final songDetails = snapshot.data!;
            final letra = songDetails['letra']?.replaceAll('\\n', '\n') ??
                'Letra não disponível';

            return GestureDetector(
              onVerticalDragCancel: () {
                print(" Is Auto Scroll, ao Clicar: $_isAutoScrollEnabled");
                if (_isAutoScrollEnabled == true) {
                  HandleTab();
                }
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Text(
                    letra,
                    style: TextStyle(fontSize: 16, color: Colors.black),
                    textAlign: TextAlign.left,
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
