import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/pages/AddSongPage.dart';
import 'package:lagoinha_music/pages/VerCifra.dart';

class MainMusicDataBase extends StatefulWidget {
  const MainMusicDataBase({super.key});

  @override
  State<MainMusicDataBase> createState() => _MainMusicDataBaseState();
}

class _MainMusicDataBaseState extends State<MainMusicDataBase> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> _checkIfChordExists(String documentId) async {
    final querySnapshot = await _firestore
        .collection('songs')
        .where('SongId', isEqualTo: documentId)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        title: Text(
          "Banco de Cançōes",
          style: TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: 0, bottom: 12),
              child: Text(
                "Cançōes",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              height: 600,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('music_database').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final List<DocumentSnapshot> documents = snapshot.data!.docs;
                  return ListView.builder(
                    padding: EdgeInsets.all(0),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final data =
                          documents[index].data() as Map<String, dynamic>;
                      final DocumentSnapshot document = documents[index];
                      print(document.id);

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 320,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                height: 65,
                                width: 65,
                                color: Colors.white,
                                child: Icon(Icons.music_note_sharp),
                              ),
                              trailing: ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(
                                      Colors.transparent),
                                ),
                                onPressed: () async {
                                  bool chordExists =
                                      await _checkIfChordExists(document.id);
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (BuildContext context) {
                                      print("Existe $chordExists");
                                      return Container(
                                        padding: EdgeInsets.all(16.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            if (chordExists)
                                              ListTile(
                                                leading: Icon(Icons.search),
                                                title: Text('Ver Cifra'),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          VerCifra(
                                                              documentId:
                                                                  document.id),
                                                    ),
                                                  );
                                                },
                                              )
                                            else
                                              ListTile(
                                                leading: Icon(Icons.add),
                                                title: Text('Adicionar Cifra'),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          AddSongPage(
                                                        title: data['Music'],
                                                        document_id:
                                                            document.id,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Icon(
                                  Icons.more_horiz,
                                  color: Colors.white,
                                ),
                              ),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
