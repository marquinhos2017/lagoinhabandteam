import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VerCifra extends StatefulWidget {
  final String documentId;

  VerCifra({required this.documentId});

  @override
  _VerCifraState createState() => _VerCifraState();
}

class _VerCifraState extends State<VerCifra> {
  late Future<Map<String, dynamic>?> _songDetailsFuture;

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
              return Text('Carregando...');
            } else if (snapshot.hasError || !snapshot.hasData) {
              return Text('Erro');
            } else {
              return Text(
                snapshot.data!['title'] ?? 'Sem título',
                style: TextStyle(color: Colors.white),
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
            return Center(child: Text('Erro ao carregar conteúdo'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('Música não encontrada'));
          } else {
            final content = snapshot.data!['content'] ?? '';
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
