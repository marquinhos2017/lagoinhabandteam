import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/pages/login.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class BoolStringPair {
  bool booleanValue;
  String stringValue;

  BoolStringPair(this.booleanValue, this.stringValue);
}

class MusicianPage extends StatefulWidget {
  const MusicianPage({super.key, required this.id});

  final String id;

  @override
  State<MusicianPage> createState() => _MusicianPageState();
}

class _MusicianPageState extends State<MusicianPage> {
  String mesIdEspecifico = "";
  bool _buttonClicked = false;
  Map<int, BoolStringPair> checkedItems = {};

  void onCheckboxChanged(int index, bool value, String docId) {
    setState(() {
      checkedItems[index] = BoolStringPair(value, docId);
    });
  }

  @override
  void initState() {
    super.initState();

    // Atualiza o estado do botão clicado em tempo real
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

    // Adiciona um listener para 'ver_formulario' do músico
    _firestore.collection('musicos').doc(widget.id).snapshots().listen((doc) {
      if (doc.exists) {
        setState(() {
          verFormulario = doc['ver_formulario'] ?? false;
        });
      } else {
        setState(() {
          verFormulario = false;
        });
      }
    });

    verificarVerFormulario();
  }

  Future<void> encontrarDocumentos(String userID) async {
    try {
      // Faz a consulta no Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Cultos')
          .where('musicos', arrayContains: userID)
          .get();

      // Itera sobre os documentos encontrados
      querySnapshot.docs.forEach((doc) {
        // Aqui você pode acessar os dados de cada documento
        Object? data = doc.data();
        print('ID do documento: ${doc.id}');
        print('Dados do documento: $data');
      });
    } catch (e) {
      print('Erro ao encontrar documentos: $e');
    }
  }

  Future<Map<String, dynamic>> fetchData(String musicianId) async {
    try {
      // Espera pelo menos 2 segundos antes de retornar os dados
      await Future.delayed(Duration(seconds: 2));

      // Busca os cultos
      QuerySnapshot cultosSnapshot =
          await FirebaseFirestore.instance.collection('Cultos').get();

      // Busca o nome do músico
      DocumentSnapshot musicianSnapshot = await FirebaseFirestore.instance
          .collection('musicos')
          .doc(musicianId)
          .get();

      if (!musicianSnapshot.exists) {
        throw Exception('O músico com ID $musicianId não foi encontrado.');
      }

      Map<String, dynamic> musicianData =
          musicianSnapshot.data() as Map<String, dynamic>;
      if (!musicianData.containsKey('name')) {
        throw Exception(
            'O campo "name" não foi encontrado no documento do músico.');
      }

      return {
        'musicianName': musicianData['name'],
        'cultos': cultosSnapshot.docs,
      };
    } catch (e) {
      throw Exception('Erro ao recuperar os dados: $e');
    }
  }

  bool verFormulario = false;

  Future<void> verificarVerFormulario() async {
    String musicoId =
        widget.id; // Substitua pelo ID do seu documento específico
    print(musicoId);

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('musicos')
          .where('user_id', isEqualTo: int.parse(musicoId))
          .get();

      print("Query: ");
      print(querySnapshot);

      if (querySnapshot.docs.isNotEmpty) {
        // Se encontrou um documento com o user_id especificado
        setState(() {
          verFormulario = querySnapshot.docs.first['ver_formulario'] ?? false;
          mesIdEspecifico = querySnapshot.docs.first['doc_formulario'];
          print("Formulario Ativo " + mesIdEspecifico);
        });
      } else {
        // Se não encontrou nenhum documento com o user_id especificado
        setState(() {
          verFormulario = false;
        });
      }
    } catch (e) {
      setState(() {
        verFormulario = false;
      });
      print('Erro ao verificar ver_formulario: $e');
    }
  }

  // Função para salvar os dados no Firestore
  Future<void> salvarDados(String musicoId) async {
    print(musicoId);
    checkedItems.forEach((id, pair) {
      if (pair.booleanValue) {
        // Salvar dados no Firestore
        _firestore.collection('Form_Voluntario_Culto').add({
          'disponibilidade_culto': pair.stringValue,
          'musico_id': widget.id,
          'disponivel': pair.booleanValue,
        }).then((value) {
          print('Dados salvos com sucesso para culto: $id');
        }).catchError((error) {
          print('Erro ao salvar dados para culto: $id, $error');
        });
      }
    });
    try {
      await _firestore
          .collection('musicos')
          .where('user_id',
              isEqualTo: int.parse(widget.id)) // Filtra pelo user_id desejado
          .get()
          .then((querySnapshot) {
        if (querySnapshot.size > 0) {
          querySnapshot.docs.forEach((doc) async {
            await doc.reference.update({
              'ver_formulario': false,
            });
          });
        } else {
          print('Nenhum documento encontrado com user_id ${widget.id}');
        }
      });
      print('Documento atualizado com sucesso!');
    } catch (e) {
      print('Erro ao atualizar campo: $e');
    }
    setState(() {
      verFormulario = false;
    });
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    print("User_id: " + widget.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Lagoinha Worship Faro",
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
            ),
          ),
        ],
        foregroundColor: Colors.black,
        backgroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xff171717),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 23),
                  width: 154,
                  height: 154,
                  decoration: BoxDecoration(
                    color: Color(0xff0A7AFF),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('Cultos')
                              .where('musicos', arrayContains: {
                            'user_id': int.parse(widget.id)
                          }).snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            }

                            int count = snapshot.data?.docs.length ?? 0;

                            return Text(
                              '$count',
                              style: TextStyle(
                                  fontSize: 86,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w200),
                            );
                          },
                        ),
                        Container(
                          width: 70,
                          child: Text(
                            "Cultos Escalados Esse mês  ",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 16),
                  width: 166,
                  child: Text(
                    "Bem vindo ",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Visibility(
              visible: !verFormulario,
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 32),
                    color: Color(0xff171717),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Closest Service",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xff0A7AFF),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            "View all",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10),
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    height: 200,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Cultos')
                          .where('musicos', arrayContains: {
                        'user_id': int.parse(widget.id)
                      }).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        List<DocumentSnapshot> docs = snapshot.data!.docs;

                        return Container(
                          child: ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              Map<String, dynamic> data =
                                  docs[index].data() as Map<String, dynamic>;
                              print(data);
                              final List<dynamic> playlist = data['playlist'];
                              print("Printando: ");
                              print(playlist);

                              DateTime? dataDocumento;
                              try {
                                dataDocumento = data?['date']?.toDate();
                              } catch (e) {
                                print('Erro ao converter data: $e');
                                dataDocumento = null;
                              }

                              return Container(
                                margin: EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                    color: Color(0xff010101),
                                    borderRadius: BorderRadius.circular(24)),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 30.0, vertical: 12),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_month,
                                                color: Colors.white,
                                              ),
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    DateFormat('dd/MM/yyyy')
                                                        .format(dataDocumento!),
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        data['nome'],
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w300,
                                                            fontSize: 10),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Container(
                                            height: 30,
                                            width: 280,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: playlist.length,
                                              itemBuilder: (context, idx) {
                                                final musicDocumentId =
                                                    playlist[idx]
                                                            ['music_document']
                                                        as String;

                                                return FutureBuilder<
                                                    DocumentSnapshot>(
                                                  future: FirebaseFirestore
                                                      .instance
                                                      .collection(
                                                          'music_database')
                                                      .doc(musicDocumentId)
                                                      .get(),
                                                  builder:
                                                      (context, musicSnapshot) {
                                                    if (musicSnapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return Center(
                                                          child:
                                                              CircularProgressIndicator());
                                                    }

                                                    if (musicSnapshot
                                                        .hasError) {
                                                      return Text(
                                                          'Erro ao carregar música');
                                                    }

                                                    if (!musicSnapshot
                                                            .hasData ||
                                                        !musicSnapshot
                                                            .data!.exists) {
                                                      return Text(
                                                          'Música não encontrada');
                                                    }

                                                    final musicData =
                                                        musicSnapshot.data!
                                                                .data()
                                                            as Map<String,
                                                                dynamic>;
                                                    final nomeMusica = musicData[
                                                            'Music'] ??
                                                        'Nome da Música Desconhecido';

                                                    return Container(
                                                      margin: EdgeInsets.only(
                                                          right: 8),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Color(0xff0075FF),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(24),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                    24.0,
                                                                vertical: 6),
                                                        child: Text(
                                                          nomeMusica,
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 12),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                          SizedBox(
                                            height: 28,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            //  Text(
            //widget.id, // ID do Usuario
            // style: TextStyle(color: Colors.white),
            //  ),

            //Container( Mostra o valor do ver Formulario
            //child: Text(
            // '$verFormulario',
            // style: TextStyle(color: Colors.white),
            //),
            //),
            if (verFormulario)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('Form_Mes_Cultos')
                      .where('mes_id', isEqualTo: mesIdEspecifico)
                      .orderBy(
                        'data',
                      )
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Erro: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final cultos = snapshot.data!.docs;
                    // print(verFormulario);

                    if (cultos.isEmpty) {
                      return Center(child: Text('Nenhum culto encontrado.'));
                    }

                    return ListView.builder(
                      itemCount: cultos.length,
                      itemBuilder: (context, index) {
                        var culto = cultos[index];

                        print(culto['data']);

                        String nomeDocumento =
                            culto?['culto'] ?? 'Nome do Culto Indisponível';
                        DateTime? dataDocumento;
                        try {
                          dataDocumento = culto?['data']?.toDate();
                        } catch (e) {
                          print('Erro ao converter data: $e');
                          dataDocumento = null;
                        }

                        print("Mostrando" + culto.id);

                        return CheckboxListTile(
                          title: Text(
                            'Culto: ${culto['culto']}',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: dataDocumento != null
                              ? Text(
                                  DateFormat('dd/MM/yyyy')
                                          .format(dataDocumento!) +
                                      " -  ${culto['horario']}",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w300,
                                      fontSize: 10),
                                )
                              : Text('Data Indisponível'),
                          value: checkedItems[index]?.booleanValue ?? false,
                          onChanged: (bool? value) {
                            onCheckboxChanged(index, value ?? false, culto.id);
                          },
                        );
                      },
                    );
                  },
                ),
              )
            else
              Center(
                child: Text('Você não tem permissão para ver os cultos.'),
              ),
            FutureBuilder<Map<String, dynamic>>(
              future: fetchData(widget.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return Center(
                    child: Text(
                      'Nenhum dado encontrado',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final musicianName = snapshot.data!['musicianName'];
                final cultos =
                    snapshot.data!['cultos'] as List<QueryDocumentSnapshot>;

                // Filtra os cultos para verificar se o músico está escalado
                final cultosEscalados = cultos.where((culto) {
                  final cultoData = culto.data() as Map<String, dynamic>;
                  final musicos = cultoData['musicos'] != null
                      ? cultoData['musicos'] as List<dynamic>
                      : [];
                  return musicos
                      .any((musico) => musico['name'] == musicianName);
                }).toList();

                // Verifica se o músico está escalado em algum culto
                if (cultosEscalados.isEmpty) {
                  return Center(
                    child: Text(
                      'Você não está escalado para nenhum culto.',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Container(
                    margin: EdgeInsets.only(top: 0),
                    padding: EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 12),
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
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: cultosEscalados.length,
                            itemBuilder: (context, index) {
                              final culto = cultosEscalados[index].data()
                                  as Map<String, dynamic>;
                              return Container(
                                margin: EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                    color: Color(0xff010101),
                                    borderRadius: BorderRadius.circular(0)),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 30.0, vertical: 12),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            culto['nome'],
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
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
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Visibility(
        visible:
            verFormulario, // Mostra apenas se shouldShowFab for true e não estiver salvo
        child: FloatingActionButton(
          onPressed: () {
            String musicoId = widget.id; // Substitua pelo ID do músico logado
            salvarDados(musicoId);
          },
          child: Icon(Icons.save),
        ),
      ),
    );
  }
}
