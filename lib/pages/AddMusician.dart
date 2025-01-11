import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importe o pacote intl

class MusicianSelect22 extends StatefulWidget {
  final String document_id;
  final String instrument;

  MusicianSelect22({required this.document_id, required this.instrument});

  @override
  State<MusicianSelect22> createState() => _MusicianSelect2State();
}

class _MusicianSelect2State extends State<MusicianSelect22> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<Map<String, dynamic>>? _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    try {
      DocumentSnapshot cultoDoc =
          await _firestore.collection('Cultos').doc(widget.document_id).get();

      if (!cultoDoc.exists) {
        throw Exception('Documento de culto não encontrado');
      }

      var cultoData = cultoDoc.data() as Map<String, dynamic>;
      String date = DateFormat('dd-MM-yyyy').format(cultoData['date'].toDate());
      String horario = cultoData['horario'];

      QuerySnapshot musicosSnapshot =
          await _firestore.collection('musicos').get();
      List<Map<String, dynamic>> musicosDisponiveis = musicosSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      return {
        'date': date,
        'horario': horario,
        'musicos': musicosDisponiveis,
        'musicosAtuais':
            List<Map<String, dynamic>>.from(cultoData['musicos'] ?? []),
      };
    } catch (e) {
      print('Erro ao buscar dados: $e');
      throw e;
    }
  }

  Future<void> adicionarMusico(
      String cultoId, String musicoId, String instrument) async {
    try {
      DocumentReference cultoRef = _firestore.collection('Cultos').doc(cultoId);
      await cultoRef.update({
        'musicos': FieldValue.arrayUnion([
          {'user_id': musicoId}
        ])
      });

      CollectionReference userCultoInstrument =
          _firestore.collection('user_culto_instrument');
      await userCultoInstrument.add({
        'idCulto': cultoId,
        'idUser': musicoId,
        'Instrument': instrument,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Músico adicionado!'),
          backgroundColor: Color(0xff4465D9),
        ),
      );

      Navigator.pop(context, true);
      Navigator.pop(context);
    } catch (e) {
      print('Erro ao adicionar músico: $e');
    }
  }

  Future<bool> verificaDisponibilidade(
      String date, String horario, String musicoId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('Form_Voluntario_Culto')
          .where('musico_id', isEqualTo: musicoId)
          .get();

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

          if (dataCulto == date && horarioCulto == horario) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      print('Erro ao verificar disponibilidade: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff010101),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar dados',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Text(
                'Nenhum dado encontrado',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          var data = snapshot.data!;
          var date = data['date'] as String;
          var horario = data['horario'] as String;
          var musicosDisponiveis =
              data['musicos'] as List<Map<String, dynamic>>;
          var musicosAtuais =
              data['musicosAtuais'] as List<Map<String, dynamic>>;

          var musicosDisponiveisFiltrados = musicosDisponiveis.where((musico) {
            var musicoId = musico['user_id'];
            return !musicosAtuais
                .any((musicoAtual) => musicoAtual['user_id'] == musicoId);
          }).toList();

          return ListView.builder(
            itemCount: musicosDisponiveisFiltrados.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              var musico = musicosDisponiveisFiltrados[index];
              var musicoId = musico['user_id'];
              var nomeMusico = musico['name'];

              return FutureBuilder<bool>(
                future:
                    verificaDisponibilidade(date, horario, musicoId.toString()),
                builder: (context, disponibilidadeSnapshot) {
                  if (disponibilidadeSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return ListTile(
                      title: Text(nomeMusico),
                      subtitle: Text('Verificando disponibilidade...'),
                    );
                  }

                  if (disponibilidadeSnapshot.hasError) {
                    return ListTile(
                      title: Text(nomeMusico),
                      subtitle: Text('Erro ao verificar disponibilidade.'),
                    );
                  }

                  bool disponivel = disponibilidadeSnapshot.data ?? false;

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

                        bool? resposta = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            backgroundColor: Color(0xff171717),
                            title: Text(
                              mensagem,
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(disponivel ? 'OK' : 'Adicionar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel'),
                              ),
                            ],
                          ),
                        );

                        if (resposta == true) {
                          await adicionarMusico(
                            widget.document_id,
                            musicoId,
                            widget.instrument,
                          );
                          Navigator.pop(context);

                          // Aguarda o fechamento do SnackBar
                          await Future.delayed(Duration(seconds: 1));
                          Navigator.pop(context);

                          if (!mounted) return;

                          Navigator.pop(context, true);
                          Navigator.pop(context);
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            nomeMusico,
                            style: TextStyle(color: Colors.white),
                          ),
                          Icon(
                            disponivel ? Icons.confirmation_num : Icons.error,
                            color: disponivel ? Colors.green : Colors.red,
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
      ),
    );
  }
}
