import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lagoinha_music/pages/SongDetailsPage.dart';

class AddSongPage extends StatefulWidget {
  late String document_id;
  late String title;

  AddSongPage({required this.document_id, required this.title});

  @override
  _AddSongPageState createState() => _AddSongPageState();
}

class _AddSongPageState extends State<AddSongPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  Future<void> _saveSong() async {
    final firestore = FirebaseFirestore.instance;

    // Adiciona a nova música
    await firestore.collection('songs').add({
      'title': widget.title,
      'content': _contentController.text,
      'SongId': widget.document_id
    });

    // Limpa os campos
    _titleController.clear();
    _contentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cifra ' + widget.title),
      ),
      body: Column(
        children: [
          // Seção para adicionar novas cifras
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: 'Título da Música',
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _contentController,
                            decoration: InputDecoration(
                              labelText: 'Cifra',
                            ),
                            maxLines: null, // Permite múltiplas linhas de texto
                            keyboardType: TextInputType.multiline,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _saveSong,
                            child: Text('Salvar Música'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Seção para listar todas as cifras salvas
          Container(
            height: MediaQuery.of(context).size.height *
                0.4, // Ajuste a altura conforme necessário
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('songs').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar músicas'));
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Nenhuma música encontrada'));
                }

                final songs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index].data() as Map<String, dynamic>;
                    final title = song['title'] ?? 'Sem título';
                    final content = song['content'] ?? '';

                    return ListTile(
                      title: Text(title),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SongDetailPage(
                              title: title,
                              content: content,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
