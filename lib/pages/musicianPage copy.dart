import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/pages/ScheduleDetailsMusician.dart';
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
  String mesIdEspecifico = "";
  bool _buttonClicked = false;
  Map<int, BoolStringPair> checkedItems = {};

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
      backgroundColor: Color.fromARGB(255, 225, 225, 225),
      appBar: AppBar(
        title: Text(
          "My Schedule",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => login()),
            ),
            child: Icon(
              Icons.login,
              color: Colors.black,
            ),
          ),
        ],
        foregroundColor: Colors.white,
        backgroundColor: Colors.white,
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
                          "CONFIRMED ",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                              color: Color(0xff81AC4C),
                              borderRadius: BorderRadius.circular(100)),
                          child: Center(
                            child: Text(
                              "3",
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
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Cultos')
                          .orderBy("date")
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
                            //physics: NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              Map<String, dynamic> data =
                                  docs[index].data() as Map<String, dynamic>;
                              print(data);
                              String idDocument = docs[index].id;

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
                                            )),
                                  );
                                },
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 15),
                                  decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.black, // Cor da borda
                                          width: 0.25, // Largura da borda
                                        ),
                                      ),
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(5)),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 18.0, vertical: 0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                print("ID do Culto: " +
                                                    idDocument);
                                              },
                                              child: Container(
                                                margin:
                                                    EdgeInsets.only(top: 18),
                                                child: Row(
                                                  children: [
                                                    Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          DateFormat('MMM d')
                                                              .format(
                                                                  dataDocumento!),
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14),
                                                        ),
                                                        Container(
                                                          margin:
                                                              EdgeInsets.only(
                                                                  top: 7,
                                                                  bottom: 14),
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
                                                                    fontSize:
                                                                        14),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Row(children: [
                                                          Container(
                                                            height: 30,
                                                            width: 30,
                                                            decoration: BoxDecoration(
                                                                color: Color(
                                                                    0xffD9D9D9),
                                                                shape: BoxShape
                                                                    .circle),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(5.0),
                                                            child: Text(
                                                              "Banda",
                                                              style: TextStyle(
                                                                  color: Color(
                                                                      0xffB5B5B5),
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                        ])
                                                      ],
                                                    ),
                                                  ],
                                                ),
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
                                      color: Colors.black,
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
