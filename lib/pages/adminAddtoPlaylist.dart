import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lagoinha_music/pages/login.dart';

class AddtoPlaylist extends StatefulWidget {
  final String document_id;

  const AddtoPlaylist({required this.document_id});

  @override
  State<AddtoPlaylist> createState() => _AddtoPlaylistState();
}

class _AddtoPlaylistState extends State<AddtoPlaylist> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? selectedKey; // Armazena o tom selecionado

  Future<List<String>> _getPlaylistMusicIds() async {
    try {
      DocumentReference cultoRef =
          _firestore.collection('Cultos').doc(widget.document_id);
      DocumentSnapshot cultoDoc = await cultoRef.get();

      if (!cultoDoc.exists) {
        throw Exception('Documento de culto não encontrado');
      }

      List<dynamic> playlist = cultoDoc['playlist'] ?? [];
      return playlist.map((item) => item['music_document'] as String).toList();
    } catch (e) {
      print('Erro ao obter IDs das músicas na playlist: $e');
      return [];
    }
  }

  Future<void> _showKeyDialog(String documentId) async {
    // Reset to default key "C" every time the dialog opens
    setState(() {
      selectedKey = 'C'; // Set default key to "C"
    });

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecione o tom'),
          backgroundColor: Colors.black,
          content: KeySelectorGrid(
            initialKey: selectedKey,
            onSelect: (String key) {
              setState(() {
                selectedKey = key; // Update selected key
              });
            },
          ),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('CANCELAR', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('SALVAR', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _saveToPlaylist(documentId);
                Navigator.of(context).pop(); // Save the song to the playlist
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveToPlaylist(String documentId) async {
    if (selectedKey != null) {
      try {
        DocumentReference cultoRef =
            _firestore.collection('Cultos').doc(widget.document_id);
        DocumentSnapshot cultoDoc = await cultoRef.get();

        if (!cultoDoc.exists) {
          throw Exception('Documento de culto não encontrado');
        }

        await cultoRef.update({
          'playlist': FieldValue.arrayUnion([
            {
              'music_document': documentId,
              'key': selectedKey,
            }
          ])
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color(0xff4465D9),
            content: Text('Música adicionada à playlist com sucesso'),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('Erro ao adicionar música: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Nenhum tom selecionado'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
              )),
        ),
        centerTitle: true,
        title: Text(
          "Adicionar Canção",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          GestureDetector(
              onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => login()),
                  ),
              child: Icon(
                Icons.login,
                color: Colors.white,
              )),
        ],
        foregroundColor: Colors.black,
        backgroundColor: Colors.black,
      ),
      backgroundColor: Color(0xff010101),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(57.0),
              child: Container(
                height: 500,
                child: FutureBuilder<List<String>>(
                  future: _getPlaylistMusicIds(),
                  builder: (context, playlistSnapshot) {
                    if (!playlistSnapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final List<String> playlistMusicIds =
                        playlistSnapshot.data!;

                    return StreamBuilder<QuerySnapshot>(
                      stream:
                          _firestore.collection('music_database').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final List<DocumentSnapshot> documents =
                            snapshot.data!.docs;

                        // Filtrar músicas que já estão na playlist
                        final List<DocumentSnapshot> filteredDocuments =
                            documents
                                .where(
                                    (doc) => !playlistMusicIds.contains(doc.id))
                                .toList();

                        return ListView.builder(
                          padding: EdgeInsets.all(0),
                          itemCount: filteredDocuments.length,
                          itemBuilder: (context, index) {
                            final data = filteredDocuments[index].data()
                                as Map<String, dynamic>;
                            var documentId = filteredDocuments[index].id;

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  child: Expanded(
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      trailing: GestureDetector(
                                        onTap: () async {
                                          await _showKeyDialog(documentId);
                                        },
                                        child: Icon(
                                          Icons.add,
                                          color: Color(0xff4465D9),
                                        ),
                                      ),
                                      title: Text(
                                        data['Author'] ?? 'No title',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        data['Music'] ?? 'No artist',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w200,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Novo Widget para Seleção de Tons com Botões Quadrados
class KeySelectorGrid extends StatefulWidget {
  final Function(String) onSelect;
  final String? initialKey;

  const KeySelectorGrid({required this.onSelect, this.initialKey, Key? key})
      : super(key: key);

  @override
  _KeySelectorGridState createState() => _KeySelectorGridState();
}

class _KeySelectorGridState extends State<KeySelectorGrid> {
  late String selectedKey; // Make it late to initialize in initState

  @override
  void initState() {
    super.initState();
    selectedKey = widget.initialKey ?? 'C'; // Set default to "C"
  }

  @override
  Widget build(BuildContext context) {
    final List<String> keys = [
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

    return SizedBox(
      width: 200, // Specify a width for the grid
      height: 400, // Specify a height for the grid
      child: Center(
        child: GridView.builder(
          shrinkWrap: true, // Allow the grid to be as small as possible
          physics: NeverScrollableScrollPhysics(), // Disable scrolling
          itemCount: keys.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Number of columns in the grid
            mainAxisSpacing: 10.0,
            crossAxisSpacing: 10.0,
          ),
          itemBuilder: (context, index) {
            final key = keys[index];
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedKey = key; // Update the selected key
                });
                widget.onSelect(key);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: key == selectedKey ? Colors.blue : Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    key,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
