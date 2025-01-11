import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importe o pacote intl

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart'; //For creating the SMTP Server

// Esse

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
      final entryId = DateTime.now().millisecondsSinceEpoch.toString();

      // Adiciona a nova entrada ao array de músicos
      await cultoRef.update({
        'musicos': FieldValue.arrayUnion([
          {
            'id': entryId, // Identificador único
            'user_id': userId,
            'instrument': instrument
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

      // Busca o usuário pelo campo 'idUser'
      QuerySnapshot userSnapshot = await _firestore
          .collection('musicos')
          .where('user_id', isEqualTo: userId)
          .limit(1) // Limita a consulta para retornar no máximo um usuário
          .get();

      if (userSnapshot.docs.isEmpty) {
        throw Exception('Usuário não encontrado');
      }

      // Recupera o e-mail do primeiro usuário encontrado
      String userEmail = userSnapshot.docs.first['email'];
      print("Email Encontrado");
      print(userEmail);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Músico adicionado!'),
            backgroundColor: Color(0xff4465D9),
          ),
        );
      }

      final smtpServer =
          gmail("marcosrodriguescorreiajc@gmail.com", "dpec dpql isvc wkau");

      final message = Message()
        ..from = Address("marcosrodriguescorreiajc@gmail.com")
        ..recipients.add(userEmail) // Aqui está o e-mail do usuário
        ..subject = 'Você acabou de ser escalado'
        ..html = '''
        <!doctype html>
        <html>
        <head>
          <title>Escala de Culto</title>
        </head>
        <body>
          <p>Olá, tudo bem?</p>
          <p>Você acabou de ser escalado para o Culto no dia $date, Horário: $horario, no instrumento: $instrument.</p>
          <p>Para que você possa visualizar suas escalas, baixe o aplicativo de acordo com seu smartphone.</p>
          <footer>© 2024 Lake Music Todos os Direitos Reservados</footer>
        </body>
        </html>
    '''
        ..text = 'Você foi escalado para o culto...';

      // await send(message, smtpServer); // Envia o e-mail

      print('E-mail configurado mas nao enviado para $userEmail');
    } catch (error) {
      print('Erro ao adicionar músico: $error');
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
      backgroundColor: Colors.white,
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
                            color: Colors.black,
                          )),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      "Função: " + widget.instrument,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      "Escolha uma pessoa",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
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
                        color: Colors.white,
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
                                        var alwaysIncludedIds = [
                                          100,
                                          131,
                                          133,
                                          187
                                        ];
                                        var isAlwaysIncluded = alwaysIncludedIds
                                            .contains(musicoId);

                                        return isMd ||
                                            isAlwaysIncluded ||
                                            !musicosAtuais.any((musicoAtual) =>
                                                musicoAtual['user_id'] ==
                                                musicoId);
                                      }).toList();

                                      return ListView.builder(
                                        physics: ClampingScrollPhysics(),
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
                                                  title: Text(
                                                    nomeMusico,
                                                  ),
                                                  subtitle: Text(
                                                      'Erro ao verificar disponibilidade.'),
                                                );
                                              }

                                              bool disponivel =
                                                  disponibilidadeSnapshot
                                                          .data ??
                                                      false;

                                              bool sendEmail =
                                                  false; // Variável para controlar o envio de e-mail

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
                                                        await showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return Dialog(
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                          ),
                                                          backgroundColor: Colors
                                                              .white, // Fundo branco
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(20.0),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              children: [
                                                                // Ícone principal
                                                                Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    shape: BoxShape
                                                                        .circle,
                                                                    color: disponivel
                                                                        ? Colors.blue[
                                                                            50]
                                                                        : Colors
                                                                            .red[50], // Fundo azul claro ou vermelho claro
                                                                  ),
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          16),
                                                                  child: Icon(
                                                                    disponivel
                                                                        ? Icons
                                                                            .check_circle
                                                                        : Icons
                                                                            .error,
                                                                    size: 48,
                                                                    color: disponivel
                                                                        ? Colors
                                                                            .blue
                                                                        : Colors
                                                                            .red,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    height: 16),
                                                                // Título
                                                                Text(
                                                                  mensagem,
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .black, // Texto preto
                                                                    fontSize:
                                                                        18,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    height: 16),
                                                                // Opções
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceEvenly,
                                                                  children: [
                                                                    // Botão de Cancelar
                                                                    ElevatedButton
                                                                        .icon(
                                                                      onPressed: () => Navigator.pop(
                                                                          context,
                                                                          false),
                                                                      icon: Icon(
                                                                          Icons
                                                                              .cancel,
                                                                          color:
                                                                              Colors.black),
                                                                      label: Text(
                                                                          'Cancelar'),
                                                                      style: ElevatedButton
                                                                          .styleFrom(
                                                                        backgroundColor:
                                                                            Colors.white, // Fundo branco
                                                                        foregroundColor:
                                                                            Colors.black, // Texto preto
                                                                        shape:
                                                                            RoundedRectangleBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(12),
                                                                          side:
                                                                              BorderSide(color: Colors.black), // Borda preta
                                                                        ),
                                                                        padding: EdgeInsets.symmetric(
                                                                            horizontal:
                                                                                16,
                                                                            vertical:
                                                                                10),
                                                                      ),
                                                                    ),
                                                                    // Botão de OK/Adicionar
                                                                    ElevatedButton
                                                                        .icon(
                                                                      onPressed: () => Navigator.pop(
                                                                          context,
                                                                          true),
                                                                      icon: Icon(
                                                                          Icons
                                                                              .add,
                                                                          color:
                                                                              Colors.white),
                                                                      label: Text(disponivel
                                                                          ? 'OK'
                                                                          : 'Adicionar'),
                                                                      style: ElevatedButton
                                                                          .styleFrom(
                                                                        backgroundColor:
                                                                            Colors.blue, // Fundo azul
                                                                        foregroundColor:
                                                                            Colors.white, // Texto branco
                                                                        shape:
                                                                            RoundedRectangleBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(12),
                                                                        ),
                                                                        padding: EdgeInsets.symmetric(
                                                                            horizontal:
                                                                                16,
                                                                            vertical:
                                                                                10),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    );

                                                    if (resposta == true) {
                                                      if (!mounted) return;

                                                      await adicionarMusico(
                                                          widget.document_id,
                                                          musicoId,
                                                          widget.instrument);
                                                      print("iniciando");

                                                      // Aguarda o fechamento do SnackBar
                                                      await Future.delayed(
                                                          Duration(seconds: 3));
                                                      print("Acabando");
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        color:
                                                            Color(0xffebebeb),
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    24)),
                                                        border: Border.all(
                                                            width: 1,
                                                            color: Color(
                                                                0xffebebeb))),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
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
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                          Icon(
                                                            disponivel
                                                                ? Icons
                                                                    .confirmation_num
                                                                : Icons.error,
                                                            color: disponivel
                                                                ? Colors.green
                                                                : Colors.black,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
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
