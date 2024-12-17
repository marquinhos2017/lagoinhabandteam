import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/pages/AddLetraPage.dart';
import 'package:lagoinha_music/pages/AddSongPage.dart';
import 'package:lagoinha_music/pages/MusicDataBase/AddTimestampsPage.dart';
import 'package:lagoinha_music/pages/MusicDataBase/BPMSelectionPage.dart';
import 'package:lagoinha_music/pages/MusicDataBase/ViewTimestampsPage.dart';
import 'package:lagoinha_music/pages/MusicianPage/VerLetra.dart';
import 'package:lagoinha_music/pages/VerCifra.dart';

class Bibliotecamusical extends StatefulWidget {
  const Bibliotecamusical({super.key});

  @override
  State<Bibliotecamusical> createState() => _MainMusicDataBaseState();
}

class _MainMusicDataBaseState extends State<Bibliotecamusical> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> _checkIfTimestampsExist(String documentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('lrcs')
          .where('lyrics_id', isEqualTo: documentId)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Erro ao verificar se os timestamps existem: $e");
      return false;
    }
  }

  Future<bool> _checkIfChordExists(String documentId) async {
    try {
      // Realiza a consulta com base no campo SongId
      final querySnapshot = await FirebaseFirestore.instance
          .collection('songs')
          .where('SongId', isEqualTo: documentId)
          .get();

      // Retorna true se algum documento for encontrado, senão false
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      // Captura qualquer erro, como se a coleção não existir
      print('Erro ao verificar se o campo SongId existe: $e');
      return false;
    }
  }

  Future<bool> _checkbpm(String documentId) async {
    try {
      // Obtém o documento específico pelo documentId
      final documentSnapshot = await FirebaseFirestore.instance
          .collection('music_database')
          .doc(documentId)
          .get();

      // Verifica se o documento existe e se o campo 'bpm' está presente
      if (documentSnapshot.exists) {
        return documentSnapshot.data()?.containsKey('bpm') ?? false;
      } else {
        // Documento não encontrado
        return false;
      }
    } catch (e) {
      print('Erro ao verificar o campo bpm: $e');
      return false;
    }
  }

  Future<bool> _checkIfLetraExists(String documentId) async {
    try {
      // Obter o documento usando o documentId
      final docSnapshot =
          await _firestore.collection('music_database').doc(documentId).get();

      // Verificar se o documento existe e se o campo 'letra' não está vazio
      if (docSnapshot.exists &&
          docSnapshot.data()!.containsKey('letra') &&
          docSnapshot['letra'].isNotEmpty) {
        return true;
      }
    } catch (e) {
      print("Erro ao verificar se a letra existe: $e");
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        title: Text(
          "Banco de Cançōes",
          style: TextStyle(color: Colors.black),
        ),
      ),
      backgroundColor: Colors.white,
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
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
                            child: Expanded(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                trailing: ElevatedButton(
                                  style: ButtonStyle(
                                    elevation: WidgetStateProperty.all(0),
                                    foregroundColor: WidgetStateProperty.all(
                                        Colors.transparent),
                                    backgroundColor: WidgetStateProperty.all(
                                        Colors.transparent),
                                  ),
                                  onPressed: () async {
                                    bool chordExists =
                                        await _checkIfChordExists(document.id);
                                    bool letraExists =
                                        await _checkIfLetraExists(document.id);
                                    bool timestampsExist =
                                        await _checkIfTimestampsExist(
                                            document.id);

                                    bool bpmexist =
                                        await _checkbpm(document.id);
                                    print(
                                        "Existe BPM?: " + bpmexist.toString());
                                    print("Existe chord?: " +
                                        chordExists.toString());

                                    showModalBottomSheet(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Container(
                                          padding: EdgeInsets.all(16.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              if (bpmexist)
                                                ListTile(
                                                  leading: Icon(Icons.search),
                                                  title: Text('Alterar BPM'),
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            BPMSelectorPage(
                                                          documentId:
                                                              document.id,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                )
                                              else
                                                ListTile(
                                                  leading: Icon(Icons.add),
                                                  title: Text('Adicionar BPM'),
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            BPMSelectorPage(
                                                          documentId:
                                                              document.id,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
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
                                                              document.id,
                                                          isAdmin: true,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                )
                                              else
                                                ListTile(
                                                  leading: Icon(Icons.add),
                                                  title:
                                                      Text('Adicionar Cifra'),
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
                                              if (!letraExists)
                                                ListTile(
                                                  leading: Icon(Icons.add),
                                                  title: Text(
                                                      'Letra indisponivel'),
                                                  onTap: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                        content: Column(
                                                          children: [
                                                            Text(
                                                                "Indisponivel"),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                )
                                              else
                                                ListTile(
                                                  leading: Icon(
                                                      Icons.remove_red_eye),
                                                  title: Text('Ver Letra'),
                                                  onTap: () {
                                                    print(document.id);
                                                    Navigator.pop(context);
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            Verletra(
                                                          isAdmin: false,
                                                          documentId:
                                                              document.id,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              if (timestampsExist)
                                                ListTile(
                                                  leading: Icon(Icons.add),
                                                  title: Text(
                                                      'Adicionar Timestamps e Letras'),
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            AddTimestampsPage(
                                                          title: data['Music'],
                                                          document_id:
                                                              document.id,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              if (!timestampsExist)
                                                ListTile(
                                                  leading: Icon(Icons.add),
                                                  title: Text(
                                                      'Adicionar Timestamps e Letras'),
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            AddTimestampsPage(
                                                          title: data['Music'],
                                                          document_id:
                                                              document.id,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                )
                                              else
                                                ListTile(
                                                  leading: Icon(
                                                      Icons.remove_red_eye),
                                                  title: Text(
                                                      'Ver Timestamps e Letras'),
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            ViewTimestampsPage(
                                                          documentId:
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
                                    Icons.more_vert,
                                    color: Color.fromARGB(255, 27, 27, 27),
                                  ),
                                ),
                                title: Text(
                                  data['Music'] ?? 'No artist',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  data['Author'] ?? 'No title',
                                  style: TextStyle(
                                    color: Colors.black,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
