import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lagoinha_music/main.dart';
import 'package:lagoinha_music/models/culto.dart';
import 'package:lagoinha_music/pages/login.dart';
import 'package:provider/provider.dart';

class MusicianPage extends StatefulWidget {
  const MusicianPage({super.key, required this.id});

  final String id;

  @override
  State<MusicianPage> createState() => _MusicianPageState();
}

class _MusicianPageState extends State<MusicianPage> {
  String musicianName = '';

  @override
  void initState() {
    super.initState();
    // Chama a função para recuperar o nome do músico
    retrieveName(widget.id);
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
            String name = musicianData['name'];
            print('O nome do músico com ID $musicianId é: $name');
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
    /*
    CultosProvider cultosProvider = Provider.of<CultosProvider>(context);
    List<Culto> findCultosForMusician(String musicianName) {
      return cultosProvider.cultos.where((culto) {
        return culto.musicos.any((musician) => musician.name == musicianName);
      }).toList();
    }

    List<Culto> cultosWithMarcos = findCultosForMusician("Marcos Rodrigues");

    for (var culto in cultosWithMarcos) {
      print("Marcos Rodrigues está escalado para: ${culto.nome}");
    }*/

    Future<int> countTotalMusicos() async {
      try {
        QuerySnapshot<Map<String, dynamic>> querySnapshot =
            await FirebaseFirestore.instance.collection('Cultos').get();

        int totalMusicos = 0;
        querySnapshot.docs.forEach((doc) {
          if (doc.data().containsKey('musicos')) {
            List<dynamic>? musicos = doc['musicos'];
            totalMusicos += musicos?.length ?? 0;
          }
        });

        return totalMusicos;
      } catch (e) {
        print('Erro ao contar o número total de músicos: $e');
        return 0;
      }
    }

    return Scaffold(
        backgroundColor: const Color(0xff171717),
        body: Container(
          margin: EdgeInsets.only(top: 100),
          padding: EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    return CircularProgressIndicator();
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
                      ));
                    }

                    final cultos = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: cultos.length,
                      itemBuilder: (context, index) {
                        final culto =
                            cultos[index].data() as Map<String, dynamic>;
                        final musicos;
                        if (culto['musicos'] != null) {
                          musicos = culto['musicos'] as List<dynamic>;
                        } else {
                          musicos = [];
                        }
                        print(musicos);
                        if (musicos
                            .any((musico) => musico['name'] == "Marcos")) {
                          print("Marcos no Culto:  " + culto['nome']);
                          return ListTile(
                            title: Text(
                              culto['nome'],
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        } else {
                          print("Sem Escala");
                        }

                        /* return ListTile(
                          title: Text(
                            culto['nome'] ?? 'Sem escalas',
                            style: TextStyle(color: Colors.white),
                          ),
                          // //subtitle: Column(
                          //    crossAxisAlignment: CrossAxisAlignment.start,
                          //    children: musicos.map((musico) {
                          //       return Text(
                          //           '${musico['name']} - ${musico['instrument']}');
                          //      }).toList(),
                          //    ),
                        );*/
                      },
                    );
                  },
                ),
              ),

              /* SizedBox(
                height: cultosProvider.cultos.length * 60.0,
                child: Container(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.zero,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: cultosWithMarcos.length,
                            itemBuilder: (context, index) {
                              final culto = cultosProvider.cultos[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: GestureDetector(
                                  onTap: () {
                                    //Navigator.pushNamed(
                                    //    context, '/adminCultoForm');
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Color(0xff010101),
                                        borderRadius: BorderRadius.circular(0)),
                                    width: MediaQuery.of(context).size.width,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 30.0, vertical: 12),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                cultosWithMarcos[index].nome,
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                              Text(
                                                "19:30 - 21:00",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w300,
                                                    fontSize: 10),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            children: [Text("14/abr")],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),*/
              /*Expanded(
                child: Container(
                  child: ListView.builder(
                      itemCount: cultosWithMarcos.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(cultosWithMarcos[index].nome),
                        );
                      }),
                ),
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Go back!"),
                ),
              ),*/
            ],
          ),
        ));
  }

  @override
  void dispose() {
    // Certifique-se de cancelar qualquer assinatura ou callback ao desmontar o widget
    super.dispose();
  }
}
