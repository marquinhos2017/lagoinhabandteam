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

  Future<void> _showKeyDialog(String documentId) async {
    String? selectedKey;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Selecione o tom'),
              content: DropdownButton<String>(
                value: selectedKey,
                items: <String>[
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
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(color: Colors.black),
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    selectedKey = value;
                  });
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('CANCELAR'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('OK'),
                  onPressed: () async {
                    if (selectedKey != null) {
                      try {
                        DocumentReference cultoRef = _firestore
                            .collection('Cultos')
                            .doc(widget.document_id);
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
                            content: Text(
                                'Música adicionada à playlist com sucesso'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        print('Erro ao adicionar música: $e');
                      }

                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
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
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('music_database').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final List<DocumentSnapshot> documents =
                        snapshot.data!.docs;
                    return ListView.builder(
                      padding: EdgeInsets.all(0),
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        final data =
                            documents[index].data() as Map<String, dynamic>;
                        var documentId = documents[index].id;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 270,
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
                          ],
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
