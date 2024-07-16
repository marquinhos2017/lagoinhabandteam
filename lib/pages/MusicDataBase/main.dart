import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MainMusicDataBase extends StatefulWidget {
  const MainMusicDataBase({super.key});

  @override
  State<MainMusicDataBase> createState() => _MainMusicDataBaseState();
}

class _MainMusicDataBaseState extends State<MainMusicDataBase> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Music Library"),
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: 45, bottom: 45),
              child: Text(
                "Music Library",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Container(
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
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 330,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  height: 65,
                                  width: 65,
                                  color: Colors.white,
                                  child: Icon(Icons.music_note_sharp),
                                ),
                                trailing: Icon(
                                  Icons.more_vert_rounded,
                                  color: Colors.white,
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
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
