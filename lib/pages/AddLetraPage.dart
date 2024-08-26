import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lagoinha_music/pages/SongDetailsPage.dart';

class AddLetraPage extends StatefulWidget {
  late String document_id;
  late String title;

  AddLetraPage({required this.document_id, required this.title});

  @override
  _AddSongPageState createState() => _AddSongPageState();
}

class _AddSongPageState extends State<AddLetraPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  Future<void> _saveSong() async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Atualiza o documento existente com o ID fornecido
      await firestore
          .collection('music_database')
          .doc(widget.document_id)
          .update({
        'letra':
            _contentController.text, // Adiciona o conteúdo ao campo 'letra'
      });

      // Limpa os campos
      _titleController.clear();
      _contentController.clear();

      // Mostra uma mensagem de sucesso (opcional)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Letra adicionada com sucesso!')),
      );
      Navigator.pop(context);
    } catch (e) {
      // Mostra uma mensagem de erro se algo der errado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar letra: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Letra ' + widget.title),
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
                              labelText: 'Letra',
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
            height: MediaQuery.of(context).size.height * 0.4,
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
