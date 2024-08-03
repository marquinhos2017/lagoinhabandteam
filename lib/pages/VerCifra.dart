import 'package:cloud_firestore/cloud_firestore.dart';
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
                    : Text(
                        snapshot.data!['content'] ?? '',
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
