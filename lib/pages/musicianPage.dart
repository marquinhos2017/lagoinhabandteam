import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/pages/login.dart';

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
      DocumentSnapshot docSnapshot =
          await _firestore.collection('musicos').doc(musicoId).get();
      print(docSnapshot['ver_formulario']);

      if (docSnapshot.exists) {
        setState(() {
          verFormulario = docSnapshot['ver_formulario'] ?? false;
        });
      } else {
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
      await _firestore.collection('musicos').doc(widget.id).update({
        'ver_formulario': false,
      });
      print('Campo "ver_formulario" atualizado com sucesso para true.');
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
    String mesIdEspecifico = "L2H8yWusQTqqV6zASU10";

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
      body: Column(
        children: [
          Text(
            widget.id,
            style: TextStyle(color: Colors.white),
          ),
          Container(
            child: Text(
              '$verFormulario',
              style: TextStyle(color: Colors.white),
            ),
          ),
          if (verFormulario)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('Form_Mes_Cultos')
                    .where('mes_id', isEqualTo: mesIdEspecifico)
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

                      print("Mostrando" + culto.id);

                      return CheckboxListTile(
                        title: Text('Culto: ${culto['culto']}'),
                        subtitle: Text(
                            'Horário: ${culto['horario']}, Data: ${culto['data']}'),
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
                return musicos.any((musico) => musico['name'] == musicianName);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          String musicoId = widget.id; // Substitua pelo ID do músico logado
          salvarDados(musicoId);
        },
        child: Icon(Icons.save),
      ),
    );
  }
}
