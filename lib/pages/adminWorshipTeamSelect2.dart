import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/main.dart';
import 'package:lagoinha_music/models/culto.dart';
import 'package:lagoinha_music/models/musician.dart';
import 'package:lagoinha_music/models/musico.dart';
import 'package:lagoinha_music/pages/adminCultoForm.dart';
import 'package:lagoinha_music/pages/adminCultoForm2.dart';
import 'package:lagoinha_music/pages/userMain.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Importe o pacote intl

class MusicianSelect2 extends StatefulWidget {
  final String document_id;
  final String instrument;

  MusicianSelect2({required this.document_id, required this.instrument});

  @override
  State<MusicianSelect2> createState() => _MusicianSelect2State();
}

class _MusicianSelect2State extends State<MusicianSelect2> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? date;
  String? horario;

  @override
  void initState() {
    super.initState();
    obterDataDocumento(widget.document_id).then((value) {
      setState(() {
        if (value != null) {
          date = value['data'];
          horario = value['horario'];
        }
      });
    });
  }

  void adicionarMusico(String cultoId, int userId, String instrument) async {
    try {
      DocumentReference cultoRef = _firestore.collection('Cultos').doc(cultoId);
      DocumentSnapshot cultoDoc = await cultoRef.get();

      if (!cultoDoc.exists) {
        throw Exception('Documento de culto não encontrado');
      }

      await cultoRef.update({
        'musicos': FieldValue.arrayUnion([
          {'user_id': userId}
        ])
      });

      // Obtém uma referência para a coleção 'user_culto_instrument'
      CollectionReference userCultoInstrument =
          FirebaseFirestore.instance.collection('user_culto_instrument');

      // Adiciona um novo documento com os campos especificados
      await userCultoInstrument.add({
        'idCulto': cultoId,
        'idUser': userId,
        'Instrument': instrument,
      });

      print('Documento adicionado com sucesso!');
      print('Musico adicionado com sucesso');
    } catch (e) {
      print('Erro ao adicionar músico: $e');
    }
  }

  Future<bool> verificaDisponibilidade(
      String date, String horario, String musicoId) async {
    try {
      // Consultar a coleção Form_Voluntario_Culto
      QuerySnapshot querySnapshot = await _firestore
          .collection('Form_Voluntario_Culto')
          .where('musico_id', isEqualTo: musicoId)
          .get();

      // Verificar cada documento se a disponibilidade_culto corresponde à data desejada
      for (var doc in querySnapshot.docs) {
        var disponibilidadeCultoId = doc['disponibilidade_culto'];

        DocumentSnapshot formMesCultosDoc = await _firestore
            .collection('Form_Mes_Cultos')
            .doc(disponibilidadeCultoId)
            .get();

        if (formMesCultosDoc.exists) {
          var dataCulto = DateFormat('dd-MM-yyyy')
              .format(formMesCultosDoc['data'].toDate());
          var horarioCulto = formMesCultosDoc['horario'];

          // Comparar a data do culto com a data e horário desejados
          if (dataCulto == date && horarioCulto == horario) {
            return true; // Se encontrou um documento disponível para a data e horário desejado
          }
        }
      }

      return false; // Se nenhum documento foi encontrado para a data e horário desejado
    } catch (e) {
      print('Erro ao verificar disponibilidade: $e');
      return false;
    }
  }

  Future<Map<String, String>?> obterDataDocumento(String documentId) async {
    try {
      DocumentSnapshot documentSnapshot =
          await _firestore.collection('Cultos').doc(documentId).get();

      if (documentSnapshot.exists) {
        var data =
            DateFormat('dd-MM-yyyy').format(documentSnapshot['date'].toDate());
        var horario = documentSnapshot[
            'horario']; // Assumindo que 'horario' é o campo de horário
        return {'data': data, 'horario': horario};
      } else {
        return null;
      }
    } catch (e) {
      print('Erro ao buscar documento: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    CultosProvider cultosProvider = Provider.of<CultosProvider>(context);

    void addMarcos(int id) {
      cultosProvider.cultos[id].musicos.add(Musician(
          color: "grey",
          instrument: "guitar",
          name: "Marcos Rodrigues",
          password: "08041999",
          tipo: "user"));
    }

    return Scaffold(
      backgroundColor: Color(0xff010101),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Container(
                margin: EdgeInsets.only(top: 60, bottom: 40),
                child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                    )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                widget.instrument,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                margin: EdgeInsets.only(top: 2),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Color(0xff171717),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('Cultos')
                              .doc(widget.document_id)
                              .snapshots(),
                          builder: (context, cultoSnapshot) {
                            if (cultoSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (!cultoSnapshot.hasData ||
                                !cultoSnapshot.data!.exists) {
                              return Center(
                                child: Text(
                                  'Dados do culto não encontrados',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }

                            var cultoData = cultoSnapshot.data!.data()
                                as Map<String, dynamic>;
                            var musicosAtuais = List<Map<String, dynamic>>.from(
                                cultoData['musicos'] ?? []);

                            return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('musicos')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                }

                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return Center(
                                    child: Text(
                                      'Nenhum Músico cadastrado',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                }

                                var musicosDisponiveis =
                                    snapshot.data!.docs.where((musicoDoc) {
                                  var musicoData =
                                      musicoDoc.data() as Map<String, dynamic>;
                                  var musicoId = musicoData['user_id'];
                                  // Verifica se o músico já está adicionado no culto
                                  return !musicosAtuais.any((musicoAtual) =>
                                      musicoAtual['user_id'] == musicoId);
                                }).toList();

                                return ListView.builder(
                                  itemCount: musicosDisponiveis.length,
                                  padding: EdgeInsets.zero,
                                  itemBuilder: (context, index) {
                                    var data = musicosDisponiveis[index];
                                    var musicos =
                                        data.data() as Map<String, dynamic>;
                                    var musicoId = musicos['user_id'];
                                    var nomeMusico = musicos['name'];

                                    return FutureBuilder<bool>(
                                      future: verificaDisponibilidade(
                                          date!, horario!, musicoId.toString()),
                                      builder:
                                          (context, disponibilidadeSnapshot) {
                                        if (disponibilidadeSnapshot
                                                .connectionState ==
                                            ConnectionState.waiting) {
                                          return ListTile(
                                            title: Text(nomeMusico),
                                            subtitle: Text(
                                                'Verificando disponibilidade...'),
                                          );
                                        }

                                        if (disponibilidadeSnapshot.hasError) {
                                          return ListTile(
                                            title: Text(nomeMusico),
                                            subtitle: Text(
                                                'Erro ao verificar disponibilidade.'),
                                          );
                                        }

                                        bool disponivel =
                                            disponibilidadeSnapshot.data ??
                                                false;

                                        return Container(
                                          padding: EdgeInsets.all(8),
                                          child: GestureDetector(
                                            onTap: () async {
                                              if (!mounted) return;

                                              String mensagem;
                                              if (disponivel) {
                                                mensagem =
                                                    "Quer convidar $nomeMusico para ser o ${widget.instrument}?";
                                              } else {
                                                mensagem =
                                                    "$nomeMusico está indisponível. Quer convidar mesmo assim?";
                                              }

                                              bool? resposta =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder:
                                                    (BuildContext context) =>
                                                        AlertDialog(
                                                  backgroundColor:
                                                      Color(0xff171717),
                                                  title: Text(
                                                    mensagem,
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child: Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      child: Text(disponivel
                                                          ? 'OK'
                                                          : 'Adicionar $nomeMusico na ${widget.instrument}'),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (resposta == true) {
                                                adicionarMusico(
                                                    widget.document_id,
                                                    musicoId,
                                                    widget.instrument);
                                                if (!mounted) return;

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Músico adicionado!'),
                                                    backgroundColor:
                                                        Color(0xff4465D9),
                                                  ),
                                                );

                                                Navigator.pop(context);

                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          adminCultoForm2(
                                                            document_id: widget
                                                                .document_id,
                                                          )),
                                                );

                                                // Atualiza a tela atual
                                                setState(() {});
                                              }
                                            },
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  nomeMusico,
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                Icon(
                                                  disponivel
                                                      ? Icons.confirmation_num
                                                      : Icons.error,
                                                  color: disponivel
                                                      ? Colors.green
                                                      : Colors.red,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
