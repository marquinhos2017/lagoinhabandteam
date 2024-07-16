import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddtoPlaylist extends StatefulWidget {
  final String document_id;
  const AddtoPlaylist({required this.document_id});

  @override
  State<AddtoPlaylist> createState() => _AddtoPlaylistState();
}

class _AddtoPlaylistState extends State<AddtoPlaylist> {
  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    return Scaffold(
      backgroundColor: Color(0xff010101),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: 80, left: 0, bottom: 20),
              child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                  )),
            ),
            Center(
              child: Text(
                "Add to Playlist",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(57.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: false,
                    child: Column(
                      children: [
                        Text(
                          "Song",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 10, bottom: 32),
                          height: 50,
                          decoration: BoxDecoration(
                              color: Color(0xff191919),
                              borderRadius: BorderRadius.circular(24)),
                        ),
                        Text(
                          "Singer",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 10, bottom: 32),
                          height: 50,
                          decoration: BoxDecoration(
                              color: Color(0xff191919),
                              borderRadius: BorderRadius.circular(24)),
                        ),
                        Text(
                          "Tone",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 10, bottom: 32),
                          height: 50,
                          decoration: BoxDecoration(
                              color: Color(0xff191919),
                              borderRadius: BorderRadius.circular(24)),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            margin: EdgeInsets.only(top: 24, bottom: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Color(0xff4465D9),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(0.0),
                              child: Center(
                                child: Text(
                                  "+",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 24),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 500,
                    child: StreamBuilder<QuerySnapshot>(
                        stream:
                            _firestore.collection('music_database').snapshots(),
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
                              final data = documents[index].data()
                                  as Map<String, dynamic>;
                              var documentId = documents[index];
                              print(documentId.id);
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 270,
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      trailing: GestureDetector(
                                          onTap: () async {
                                            try {
                                              DocumentReference cultoRef =
                                                  _firestore
                                                      .collection('Cultos')
                                                      .doc(widget.document_id);
                                              DocumentSnapshot cultoDoc =
                                                  await cultoRef.get();

                                              if (!cultoDoc.exists) {
                                                throw Exception(
                                                    'Documento de culto não encontrado');
                                              }

                                              await cultoRef.update({
                                                'playlist':
                                                    FieldValue.arrayUnion([
                                                  {
                                                    'music_document':
                                                        documentId.id
                                                  }
                                                ])
                                              });

                                              print(
                                                  'Musico adicionado com sucesso');
                                            } catch (e) {
                                              print(
                                                  'Erro ao adicionar músico: $e');
                                            }
                                          },
                                          child: Text("adicionar")),
                                      title: Text(
                                        data['Author'] ?? 'No title',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text(
                                        data['Music'] ?? 'No artist',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w200),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
