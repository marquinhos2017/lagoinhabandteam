import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/pages/MusicianPage/ScheduleDetailsMusician.dart';
import 'package:lagoinha_music/pages/login.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class BoolStringPair {
  bool booleanValue;
  String stringValue;

  BoolStringPair(this.booleanValue, this.stringValue);
}

class MusicianPageCopy extends StatefulWidget {
  const MusicianPageCopy({super.key, required this.id});

  final String id;

  @override
  State<MusicianPageCopy> createState() => _MusicianPageCopyState();
}

class _MusicianPageCopyState extends State<MusicianPageCopy> {
  int cultosCount = 0; // Variável para armazenar a contagem de cultos
  String mesIdEspecifico = "";
  bool _buttonClicked = false;
  Map<int, BoolStringPair> checkedItems = {};

  Future<String> loadInstrumentForDocument(
      String userId, String cultoId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('user_culto_instrument')
          .where('idUser', isEqualTo: int.parse(widget.id))
          .where('idCulto', isEqualTo: cultoId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first['Instrument'] ??
            'Instrumento Desconhecido';
      } else {
        return 'Instrumento Desconhecido';
      }
    } catch (e) {
      print('Erro ao carregar instrumento: $e');
      return 'Instrumento Desconhecido';
    }
  }

  void onCheckboxChanged(int index, bool value, String docId) {
    setState(() {
      checkedItems[index] = BoolStringPair(value, docId);
    });
  }

  late int count;

  @override
  void initState() {
    super.initState();
    print("ID do usuario");

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
    contarCultosDoUsuario();

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
      await Future.delayed(Duration(seconds: 1));

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

  Future<void> contarCultosDoUsuario() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Cultos')
          .where('musicos',
              arrayContains: {'user_id': int.parse(widget.id)}).get();

      setState(() {
        cultosCount = querySnapshot.size; // Armazena a contagem de cultos
      });
    } catch (e) {
      print('Erro ao contar cultos: $e');
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "My Schedule",
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
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [],
            ),
            Visibility(
              visible: !verFormulario,
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "CONFIRMADO ",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                              color: Color(0xff4465D9),
                              borderRadius: BorderRadius.circular(100)),
                          child: Center(
                            child: Text(
                              cultosCount.toString(),
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 600,
                    margin: EdgeInsets.only(top: 16),
                    child: FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('Cultos')
                          .orderBy("date")
                          .where('musicos', arrayContains: {
                        'user_id': int.parse(widget.id)
                      }).get(), // Obtendo todos os documentos uma vez
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Erro: ${snapshot.error}'));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                              child: Text('Nenhum culto encontrado.'));
                        }

                        List<DocumentSnapshot> docs = snapshot.data!.docs;

                        // Lista para armazenar todas as músicas de todos os cultos
                        List<List<Map<String, dynamic>>> allMusicDataList =
                            List.generate(docs.length, (_) => []);

                        // Função para carregar as músicas de um culto específico
                        Future<void> loadMusicsForDocument(int docIndex) async {
                          final doc = docs[docIndex];
                          final data = doc.data() as Map<String, dynamic>;
                          final playlist = data['playlist'] as List<dynamic>?;

                          if (playlist != null) {
                            List<Future<DocumentSnapshot>> musicFutures =
                                playlist.map((song) {
                              String musicDocumentId =
                                  song['music_document'] as String;
                              return FirebaseFirestore.instance
                                  .collection('music_database')
                                  .doc(musicDocumentId)
                                  .get();
                            }).toList();

                            List<DocumentSnapshot> musicSnapshots =
                                await Future.wait(musicFutures);
                            List<Map<String, dynamic>> musicDataList =
                                musicSnapshots.map((musicSnapshot) {
                              if (musicSnapshot.exists) {
                                Map<String, dynamic> musicData = musicSnapshot
                                    .data() as Map<String, dynamic>;
                                musicData['document_id'] =
                                    musicSnapshot.id; // Adiciona o documentId
                                return musicData;
                              } else {
                                return {
                                  'Music': 'Música Desconhecida',
                                  'Author': 'Autor Desconhecido',
                                  'document_id':
                                      '', // Adiciona um campo vazio se o documento não existir
                                };
                              }
                            }).toList();

                            allMusicDataList[docIndex] = musicDataList;
                          }
                        }

                        // Carregar as músicas para todos os documentos
                        Future<void> loadAllMusics() async {
                          for (int i = 0; i < docs.length; i++) {
                            await loadMusicsForDocument(i);
                          }
                        }

                        return FutureBuilder<void>(
                          future: loadAllMusics(),
                          builder: (context, musicSnapshot) {
                            if (musicSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (musicSnapshot.hasError) {
                              return Center(
                                  child: Text('Erro ao carregar músicas'));
                            }

                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                Map<String, dynamic> data =
                                    docs[index].data() as Map<String, dynamic>;
                                String idDocument = docs[index].id;

                                DateTime? dataDocumento;
                                try {
                                  dataDocumento =
                                      (data['date'] as Timestamp?)?.toDate();
                                } catch (e) {
                                  print('Erro ao converter data: $e');
                                  dataDocumento = null;
                                }

                                return FutureBuilder<String>(
                                    future: loadInstrumentForDocument(
                                        widget.id, idDocument),
                                    builder: (context, instrumentSnapshot) {
                                      String instrumentText =
                                          'Instrumento Desconhecido';
                                      if (instrumentSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      }

                                      if (instrumentSnapshot.hasData) {
                                        instrumentText =
                                            instrumentSnapshot.data!;
                                      } else if (instrumentSnapshot.hasError) {
                                        print(
                                            'Erro ao carregar instrumento: ${instrumentSnapshot.error}');
                                      }

                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ScheduleDetailsMusician(
                                                documents: docs,
                                                id: idDocument,
                                                currentIndex: index,
                                                musics: allMusicDataList,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Container(
                                            margin: EdgeInsets.only(bottom: 15),
                                            decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: Colors
                                                        .black, // Cor da borda
                                                    width:
                                                        0.25, // Largura da borda
                                                  ),
                                                ),
                                                color: Color(0xff171717),
                                                borderRadius:
                                                    BorderRadius.circular(5)),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(24.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        DateFormat('MMM d')
                                                            .format(
                                                                dataDocumento!),
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 14),
                                                      ),
                                                      Text(
                                                          "-" + data['horario'],
                                                          style: TextStyle(
                                                              color: Color(
                                                                  0xff4465D9),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14))
                                                    ],
                                                  ),
                                                  Container(
                                                    margin: EdgeInsets.only(
                                                        top: 7, bottom: 14),
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          data['nome'],
                                                          style: TextStyle(
                                                              color: Color(
                                                                  0xffB5B5B5),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Row(children: [
                                                    Container(
                                                      height: 30,
                                                      width: 30,
                                                      decoration: BoxDecoration(
                                                          border: Border.all(
                                                            color: Color(
                                                                0xff4465D9),
                                                            width: 2,
                                                          ),
                                                          color:
                                                              Color(0xffD9D9D9),
                                                          shape:
                                                              BoxShape.circle),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5.0),
                                                      child: Text(
                                                        instrumentText,
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w300),
                                                      ),
                                                    ),
                                                  ]),
                                                  /*Text(
                                              'Músicas:',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            allMusicDataList[index].isNotEmpty
                                                ? ListView.builder(
                                                    shrinkWrap: true,
                                                    physics:
                                                        NeverScrollableScrollPhysics(),
                                                    itemCount:
                                                        allMusicDataList[index]
                                                            .length,
                                                    itemBuilder:
                                                        (context, playlistIndex) {
                                                      final song =
                                                          allMusicDataList[index]
                                                              [playlistIndex];
                                                      final musica =
                                                          song['Music'] ??
                                                              'Música Desconhecida';
                                                      final autor =
                                                          song['Author'] ??
                                                              'Autor Desconhecido';
                                                                            
                                                      return Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              '$musica',
                                                              style: TextStyle(
                                                                  color:
                                                                      Colors.white,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              '$autor',
                                                              style: TextStyle(
                                                                  color:
                                                                      Colors.white,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  )
                                                : Text(
                                                    'Nenhuma música encontrada',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12),
                                                  ),*/
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    });
                              },
                            );
                          },
                        );
                      },
                    ),
                  )
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
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
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
                              : Text(
                                  'Data Indisponível',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w300,
                                      fontSize: 10),
                                ),
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
              /*Center(
                child: Text('Ver Formulario desativado'),
              ),*/
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
                                  color: Colors.black,
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
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(0)),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14),
                                            ),
                                            Text(
                                              "19:30 - 21:00",
                                              style: TextStyle(
                                                  color: Colors.black,
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
