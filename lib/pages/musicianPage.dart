import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/pages/login.dart';

class MusicianPage extends StatefulWidget {
  const MusicianPage({super.key, required this.id});

  final String id;

  @override
  State<MusicianPage> createState() => _MusicianPageState();
}

class _MusicianPageState extends State<MusicianPage> {
  bool _buttonClicked = false;
  String musicianName = '';

  @override
  void initState() {
    super.initState();
    // Chama a função para recuperar o nome do músico
    retrieveName(widget.id);

    FirebaseFirestore.instance
        .collection('clicks')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((data) {
      if (data.docs.isNotEmpty) {
        setState(() {
          _buttonClicked = data.docs.first['clicked'];
        });
      }
    });
  }

  void retrieveName(String musicianId) async {
    try {
      DocumentSnapshot musicianSnapshot = await FirebaseFirestore.instance
          .collection('musicos')
          .doc(musicianId)
          .get();

      if (musicianSnapshot.exists) {
        // Verifica se o retorno de data() é um mapa válido
        if (musicianSnapshot.data() is Map<String, dynamic>) {
          // Converte o retorno para um mapa
          Map<String, dynamic> musicianData =
              musicianSnapshot.data() as Map<String, dynamic>;

          // Verifica se a chave 'name' existe no mapa
          if (musicianData.containsKey('name')) {
            setState(() {
              musicianName = musicianData['name'];
            });
            print('O nome do músico com ID $musicianId é: $musicianName');
          } else {
            print(
                'O campo "name" não foi encontrado no documento do músico com ID $musicianId.');
          }
        } else {
          print(
              'Os dados retornados não puderam ser convertidos para um mapa.');
        }
      } else {
        print('O músico com ID $musicianId não foi encontrado.');
      }
    } catch (e) {
      print('Erro ao recuperar o nome do músico: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff171717),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(top: 100),
          padding: EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('clicks')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var docs = snapshot.data?.docs;
                  if (docs!.isEmpty) {
                    return Center(child: Text('Aguardando clique...'));
                  }

                  var clicked = docs[0]['clicked'];
                  return Center(
                    child: Text(
                      clicked ? 'Botão clicado!' : 'Aguardando clique...',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
              Container(
                margin: EdgeInsets.only(top: 20, bottom: 0),
                child: GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => login()),
                        ),
                    child: Icon(
                      Icons.login,
                      color: Colors.white,
                    )),
              ),
              Center(
                child: Text(
                  'Aguardando notificações...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('musicos')
                    .doc(widget.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData) {
                    return Text('Nome do músico não encontrado');
                  }
                  var musicianData =
                      snapshot.data!.data() as Map<String, dynamic>?;

                  if (musicianData == null ||
                      !musicianData.containsKey('name')) {
                    return Text('Nome do músico não encontrado');
                  }
                  String musicianName = musicianData['name'];

                  return Text(
                    'Ola, $musicianName',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  );
                },
              ),
              Container(
                margin: EdgeInsets.only(bottom: 40),
                child: Text(
                  "Cultos Escalados",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                height: 200,
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('Cultos').get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Erro: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      print("Nenhum Culto Encontrado");
                      return Center(
                        child: Text(
                          'Nenhum culto encontrado',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final cultos = snapshot.data!.docs;

                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('musicos')
                          .doc(widget.id)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Erro: ${snapshot.error}'));
                        }

                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Center(
                              child: Text('Nome do músico não encontrado'));
                        }

                        var musicianData =
                            snapshot.data!.data() as Map<String, dynamic>?;

                        if (musicianData == null ||
                            !musicianData.containsKey('name')) {
                          return Center(
                              child: Text('Nome do músico não encontrado'));
                        }

                        String musicianName = musicianData['name'];

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: cultos.length,
                          itemBuilder: (context, index) {
                            final culto =
                                cultos[index].data() as Map<String, dynamic>;
                            final musicos = culto['musicos'] != null
                                ? culto['musicos'] as List<dynamic>
                                : [];

                            if (musicos.any(
                                (musico) => musico['name'] == musicianName)) {
                              print(musicianName +
                                  " no Culto:  " +
                                  culto['nome']);
                              return ListTile(
                                title: Text(
                                  culto['nome'],
                                  style: TextStyle(
                                      color: const Color.fromARGB(
                                          255, 205, 182, 182)),
                                ),
                              );
                            } else {
                              print("Sem Escala");
                              return SizedBox
                                  .shrink(); // Retornar um widget vazio se o músico não estiver no culto
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
