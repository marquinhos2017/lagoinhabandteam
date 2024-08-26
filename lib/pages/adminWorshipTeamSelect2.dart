import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importe o pacote intl

extension StringCasingExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.toCapitalized())
      .join(' ');
}

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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    obterDataDocumento(widget.document_id).then((value) {
      if (mounted) {
        setState(() {
          if (value != null) {
            date = value['data'];
            horario = value['horario'];
          }
          isLoading = false; // Dados carregados
        });
      }
    });
  }

  Future<void> adicionarMusico(
      String cultoId, int userId, String instrument) async {
    try {
      DocumentReference cultoRef = _firestore.collection('Cultos').doc(cultoId);
      DocumentSnapshot cultoDoc = await cultoRef.get();

      if (!cultoDoc.exists) {
        throw Exception('Documento de culto não encontrado');
      }

      // Cria uma identificação única para cada entrada no array
      final entryId = DateTime.now()
          .millisecondsSinceEpoch
          .toString(); // Exemplo de ID único usando timestamp

      // Adiciona a nova entrada ao array de músicos
      await cultoRef.update({
        'musicos': FieldValue.arrayUnion([
          {
            'id': entryId, // Identificador único
            'user_id': userId,
            'instrument':
                instrument // Se você quer armazenar o instrumento aqui também
          }
        ])
      }).then((_) {
        print('Músico adicionado com sucesso ao culto.');
      }).catchError((error) {
        print('Erro ao adicionar músico ao culto: $error');
        throw Exception('Erro ao adicionar músico ao culto.');
      });

      CollectionReference userCultoInstrument =
          _firestore.collection('user_culto_instrument');
      await userCultoInstrument.add({
        'idCulto': cultoId,
        'idUser': userId,
        'Instrument': instrument,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Músico adicionado!'),
            backgroundColor: Color(0xff4465D9),
          ),
        );
      }

      Navigator.pop(context, true); // Indica que algo mudou
    } catch (e) {
      print('Erro ao adicionar músico: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar músico: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  Future<Map<String, String>?> obterDataDocumento(String documentId) async {
    try {
      DocumentSnapshot documentSnapshot =
          await _firestore.collection('Cultos').doc(documentId).get();

      if (documentSnapshot.exists) {
        var data =
            DateFormat('dd-MM-yyyy').format(documentSnapshot['date'].toDate());
        var horario = documentSnapshot['horario'];
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
    return Scaffold(
      backgroundColor: Color(0xff010101),
      body: isLoading
          ? Center(
              child:
                  CircularProgressIndicator()) // Exibe o carregamento até que os dados estejam prontos
          : Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Container(
                      margin: EdgeInsets.only(top: 60, bottom: 40),
                      child: GestureDetector(
                          onTap: () => Navigator.pop(context, false),
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
                                    return Center(
                                        child: CircularProgressIndicator());
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
                                  var musicosAtuais =
                                      List<Map<String, dynamic>>.from(
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
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        );
                                      }

                                      var musicosDisponiveis = snapshot
                                          .data!.docs
                                          .where((musicoDoc) {
                                        var musicoData = musicoDoc.data()
                                            as Map<String, dynamic>;
                                        var musicoId = musicoData['user_id'];

                                        // Verifica se o músico é "md" ou está na lista de IDs específicos
                                        var isMd = musicoData['role'] == 'md';
                                        var alwaysIncludedIds = [100, 102];
                                        var isAlwaysIncluded = alwaysIncludedIds
                                            .contains(musicoId);

                                        return isMd ||
                                            isAlwaysIncluded ||
                                            !musicosAtuais.any((musicoAtual) =>
                                                musicoAtual['user_id'] ==
                                                musicoId);
                                      }).toList();

                                      return ListView.builder(
                                        itemCount: musicosDisponiveis.length,
                                        padding: EdgeInsets.zero,
                                        itemBuilder: (context, index) {
                                          var data = musicosDisponiveis[index];
                                          var musicos = data.data()
                                              as Map<String, dynamic>;
                                          var musicoId = musicos['user_id'];
                                          var nomeMusico = musicos['name'];
                                          var isMd = musicos['role'] == 'md';

                                          return FutureBuilder<bool>(
                                            future: (date != null &&
                                                    horario != null)
                                                ? verificaDisponibilidade(
                                                    date!,
                                                    horario!,
                                                    musicoId.toString())
                                                : Future.value(
                                                    false), // or handle the null case appropriately
                                            builder: (context,
                                                disponibilidadeSnapshot) {
                                              if (disponibilidadeSnapshot
                                                      .connectionState ==
                                                  ConnectionState.waiting) {
                                                return Container(); // Não exibe nada enquanto verifica disponibilidade
                                              }

                                              if (disponibilidadeSnapshot
                                                  .hasError) {
                                                return ListTile(
                                                  title: Text(nomeMusico),
                                                  subtitle: Text(
                                                      'Erro ao verificar disponibilidade.'),
                                                );
                                              }

                                              bool disponivel =
                                                  disponibilidadeSnapshot
                                                          .data ??
                                                      false;

                                              return Container(
                                                padding: EdgeInsets.all(8),
                                                child: GestureDetector(
                                                  onTap: () async {
                                                    if (!mounted) return;

                                                    String mensagem;
                                                    if (disponivel || isMd) {
                                                      mensagem =
                                                          "Quer convidar $nomeMusico para ser o ${widget.instrument}?";
                                                    } else {
                                                      mensagem =
                                                          "$nomeMusico está indisponível. Quer convidar mesmo assim?";
                                                    }

                                                    bool? resposta =
                                                        await showDialog<bool>(
                                                      context: context,
                                                      builder: (BuildContext
                                                              context) =>
                                                          AlertDialog(
                                                        backgroundColor:
                                                            Color(0xff171717),
                                                        title: Text(
                                                          mensagem,
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 16),
                                                        ),
                                                        actions: <Widget>[
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context,
                                                                    true),
                                                            child: Text(disponivel
                                                                ? 'OK'
                                                                : 'Adicionar'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context,
                                                                    false),
                                                            child:
                                                                Text('Cancel'),
                                                          ),
                                                        ],
                                                      ),
                                                    );

                                                    if (resposta == true) {
                                                      if (!mounted) return;

                                                      await adicionarMusico(
                                                          widget.document_id,
                                                          musicoId,
                                                          widget.instrument);

                                                      // Aguarda o fechamento do SnackBar
                                                      await Future.delayed(
                                                          Duration(seconds: 1));

                                                      if (!mounted) return;

                                                      Navigator.pop(context,
                                                          true); // Retorna o resultado para a página anterior
                                                    }
                                                  },
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        nomeMusico
                                                            .toString()
                                                            .toCapitalized(),
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      Icon(
                                                        disponivel
                                                            ? Icons
                                                                .confirmation_num
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
