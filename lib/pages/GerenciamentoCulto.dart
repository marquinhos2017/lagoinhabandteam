import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/pages/adminAddtoPlaylist.dart';
import 'package:provider/provider.dart';
import 'package:lagoinha_music/main.dart';
import 'package:lagoinha_music/pages/adminWorshipTeamSelect2.dart';
import 'package:lagoinha_music/pages/login.dart';

class GerenciamentoCulto extends StatefulWidget {
  final String documentId;

  GerenciamentoCulto({required this.documentId});

  @override
  State<GerenciamentoCulto> createState() => _GerenciamentoCultoState();
}

class _GerenciamentoCultoState extends State<GerenciamentoCulto> {
  String? selectedKey; // Armazena o tom selecionado
  Future<void> _showKeyDialog(String documentId) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecione o tom'),
          backgroundColor: Colors.black,
          content: CircularKeySelector(
            initialKey: selectedKey,
            onSelect: (String key) {
              setState(() {
                selectedKey = key;
              });
            },
          ),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('CANCELAR', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('SALVAR', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo
                _saveToPlaylist(documentId); // Salva a música na playlist
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateKeyInPlaylist(
      int index, String musicDocumentId, String newKey) async {
    try {
      DocumentReference cultoRef =
          _firestore.collection('Cultos').doc(widget.documentId);
      DocumentSnapshot cultoDoc = await cultoRef.get();

      if (!cultoDoc.exists) {
        throw Exception('Documento de culto não encontrado');
      }

      List<dynamic> playlist = cultoDoc['playlist'] ?? [];
      playlist[index]['key'] = newKey;

      await cultoRef.update({'playlist': playlist});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color(0xff4465D9),
          content: Text('Tom atualizado com sucesso'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Erro ao atualizar o tom: $e');
    }
  }

  Future<void> _showUpdateKeyDialog(
      BuildContext context, int index, String currentKey) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Atualizar tom'),
          backgroundColor: Colors.black,
          content: CircularKeySelector(
            initialKey: currentKey,
            onSelect: (String newKey) {
              setState(() {
                selectedKey = newKey;
              });
            },
          ),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('CANCELAR', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('SALVAR', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo
                _updateKeyInPlaylist(
                    index, widget.documentId, selectedKey!); // Atualiza o tom
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveToPlaylist(String documentId) async {
    if (selectedKey != null) {
      try {
        DocumentReference cultoRef =
            _firestore.collection('Cultos').doc(widget.documentId);
        DocumentSnapshot cultoDoc = await cultoRef.get();

        if (!cultoDoc.exists) {
          throw Exception('Documento de culto não encontrado');
        }

        await cultoRef.update({
          'playlist': FieldValue.arrayUnion([
            {
              'music_document': documentId,
              'key': selectedKey,
            }
          ])
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color(0xff4465D9),
            content: Text('Música adicionada à playlist com sucesso'),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('Erro ao adicionar música: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Nenhum tom selecionado'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  late bool _isProcessing = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> _findDocumentId(
      String collectionPath, String fieldName, String value) async {
    try {
      final querySnapshot = await _firestore
          .collection(collectionPath)
          .where(fieldName, isEqualTo: value)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first.id : null;
    } catch (e) {
      print('Erro ao buscar documento: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMusiciansData(
      List<Map<String, dynamic>> musicians) async {
    return Future.wait(
      musicians.map((musician) async {
        final userId = musician['user_id'];
        final idCulto = widget.documentId;

        final results = await Future.wait([
          _firestore
              .collection('musicos')
              .where('user_id', isEqualTo: userId)
              .get()
              .then(
                (snapshot) => snapshot.docs.isNotEmpty
                    ? snapshot.docs.first.data() as Map<String, dynamic>
                    : {},
              ),
          _firestore
              .collection('user_culto_instrument')
              .where('idUser', isEqualTo: userId)
              .where('idCulto', isEqualTo: idCulto)
              .get()
              .then(
                (snapshot) => snapshot.docs.isNotEmpty
                    ? snapshot.docs.first.data() as Map<String, dynamic>
                    : {},
              ),
        ]);

        return {
          'name': results[0]['name'] ?? 'Nome não encontrado',
          'instrument':
              results[1]['Instrument'] ?? 'Instrumento não encontrado',
        };
      }).toList(),
    );
  }

  Future<void> _removeMusician(int userId, String idCulto) async {
    try {
      await _firestore.collection('Cultos').doc(idCulto).update({
        'musicos': FieldValue.arrayRemove([
          {'user_id': userId}
        ])
      });

      final userCultoQuery = await _firestore
          .collection('user_culto_instrument')
          .where('idUser', isEqualTo: userId)
          .where('idCulto', isEqualTo: idCulto)
          .get();

      if (userCultoQuery.docs.isNotEmpty) {
        await userCultoQuery.docs.first.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Músico e documento de instrumento removidos com sucesso')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover músico: $e')),
      );
      print('Erro ao remover músico: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<List<String>> _fetchInstrumentsForCulto(
      List<Map<String, dynamic>> musicians) async {
    try {
      final instruments = <String>{};

      for (var musician in musicians) {
        final userId = musician['user_id'];
        final userInstrumentSnapshot = await _firestore
            .collection('user_culto_instrument')
            .where('idUser', isEqualTo: userId)
            .where('idCulto', isEqualTo: widget.documentId)
            .get();

        if (userInstrumentSnapshot.docs.isNotEmpty) {
          final instrument =
              userInstrumentSnapshot.docs.first.data()['Instrument'] as String;
          instruments.add(instrument);
        }
      }

      return instruments.toList();
    } catch (e) {
      print('Erro ao buscar instrumentos: $e');
      return [];
    }
  }

  Widget _buildInstrumentButtons(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          _firestore.collection('Cultos').doc(widget.documentId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erro: ${snapshot.error}',
                style: TextStyle(color: Colors.white)),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
              child:
                  Text('No data found', style: TextStyle(color: Colors.white)));
        }

        final cultoData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final musicos =
            List<Map<String, dynamic>>.from(cultoData['musicos'] ?? []);

        return FutureBuilder<List<String>>(
          future: _fetchInstrumentsForCulto(musicos),
          builder: (context, futureSnapshot) {
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (futureSnapshot.hasError) {
              return Center(
                child: Text('Erro: ${futureSnapshot.error}',
                    style: TextStyle(color: Colors.white)),
              );
            }

            if (!futureSnapshot.hasData || futureSnapshot.data!.isEmpty) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildInstrumentButton(context, "Piano"),
                    _buildInstrumentButton(context, "Guitarra"),
                    _buildInstrumentButton(context, "Bateria"),
                    _buildInstrumentButton(context, "Violão"),
                    _buildInstrumentButton(context, "Baixo"),
                  ],
                ),
              );
            }

            final instruments = futureSnapshot.data!;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (!instruments.contains('Piano'))
                    _buildInstrumentButton(context, "Piano"),
                  if (!instruments.contains('Guitarra'))
                    _buildInstrumentButton(context, "Guitarra"),
                  if (!instruments.contains('Bateria'))
                    _buildInstrumentButton(context, "Bateria"),
                  if (!instruments.contains('Violão'))
                    _buildInstrumentButton(context, "Violão"),
                  if (!instruments.contains('Baixo'))
                    _buildInstrumentButton(context, "Baixo"),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInstrumentButton(BuildContext context, String instrument) {
    return Container(
      margin: EdgeInsets.only(right: 24),
      width: 75,
      decoration: BoxDecoration(
        color: Color(0xff4465D9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MusicianSelect2(
              document_id: widget.documentId,
              instrument: instrument,
            ),
          ),
        ).then((result) {
          if (result == true) {
            setState(() {}); // Atualiza a página se algo mudou
          }
        }),
        child: Text(
          instrument,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMusicianList() {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          _firestore.collection('Cultos').doc(widget.documentId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erro: ${snapshot.error}',
                style: TextStyle(color: Colors.white)),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Text('No data found', style: TextStyle(color: Colors.white)),
          );
        }

        final cultoData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final musicos =
            List<Map<String, dynamic>>.from(cultoData['musicos'] ?? []);

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchMusiciansData(musicos),
          builder: (context, futureSnapshot) {
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (futureSnapshot.hasError) {
              return Center(
                child: Text('Erro: ${futureSnapshot.error}',
                    style: TextStyle(color: Colors.white)),
              );
            }

            if (!futureSnapshot.hasData || futureSnapshot.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                      'Clique no Botao acima para adicionar instrumentistas', // Significa que esta faltando todos os instrumentos
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              );
            }

            final musicoList = futureSnapshot.data!;

            return Container(
              color: Color(0xff171717),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 2),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: musicoList.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final musico = musicoList[index];
                    final name = musico['name'] ?? 'Nome não disponível';
                    final instrument =
                        musico['instrument'] ?? 'Instrumento não disponível';

                    return Container(
                      child: Column(
                        children: [
                          GestureDetector(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(right: 20),
                                      child: Text(
                                        instrument,
                                        style: TextStyle(
                                            color: Color(0xff558FFF),
                                            fontSize: 12),
                                      ),
                                    ),
                                    IconButton(
                                      icon:
                                          Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        if (_isProcessing || !mounted) return;

                                        setState(() {
                                          _isProcessing = true;
                                        });

                                        final musicoToRemove = musicos[index];
                                        final userId = musicoToRemove['user_id']
                                                as int? ??
                                            0; // Garantir que user_id é um inteiro
                                        final idCulto = widget.documentId;

                                        // Remover o músico da lista local
                                        setState(() {
                                          musicos.removeAt(index);
                                        });

                                        // Remover o músico do Firestore
                                        await _removeMusician(userId, idCulto);

                                        setState(() {
                                          _isProcessing = false;
                                        });
                                      },
                                    ),
                                  ],
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print(widget.documentId);
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final cultosProvider = Provider.of<CultosProvider>(context);

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Gerenciamento",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {}); // Atualiza a página
            },
          ),
          IconButton(
            icon: Icon(Icons.login, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => login()),
            ),
          ),
        ],
        backgroundColor: Colors.black,
      ),
      backgroundColor: Color(0xff010101),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          child: Text(
                            "Band",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        _buildInstrumentButtons(context),
                        SizedBox(
                          height: 20,
                        ),
                        _buildMusicianList(),
                      ],
                    ),
                    SizedBox(
                      height: 42,
                    ),
                    Container(
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
                              child: Text(
                                "Playlist",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(top: 0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          /*
                                          Expanded(
                                            child: Text(
                                              "Name",
                                              style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              "Singer",
                                              style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              "Tone",
                                              style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              "Açōes",
                                              style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12),
                                            ),
                                          ),*/
                                        ],
                                      ),
                                    ),
                                    Visibility(
                                        visible: false,
                                        child: Column(
                                          children: [
                                            Container(
                                              margin: EdgeInsets.only(top: 12),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      "Te Exaltamos",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      "Bethel",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      "C",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(top: 12),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      "Pra Sempre",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      "Kari Jobe",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      "F",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        )),
                                    Container(
                                      child: FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('Cultos')
                                            .doc(widget.documentId)
                                            .get(),
                                        builder: (context, cultoSnapshot) {
                                          if (cultoSnapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }

                                          if (cultoSnapshot.hasError) {
                                            return Center(
                                                child: Text(
                                                    'Erro ao carregar os dados do culto'));
                                          }

                                          if (!cultoSnapshot.hasData ||
                                              !cultoSnapshot.data!.exists) {
                                            return Center(
                                                child: Text(
                                                    'Nenhum documento de culto encontrado'));
                                          }

                                          final cultoData = cultoSnapshot.data!
                                              .data() as Map<String, dynamic>;

                                          final List<dynamic> playlist =
                                              cultoData['playlist'] ?? [];

                                          return ListView.builder(
                                            padding: EdgeInsets.zero,
                                            shrinkWrap:
                                                true, // Ajusta o tamanho da ListView para o conteúdo
                                            physics:
                                                NeverScrollableScrollPhysics(), // Desativa o scroll interno
                                            itemCount: playlist.length,
                                            itemBuilder: (context, index) {
                                              final musicDocumentId =
                                                  playlist[index]
                                                          ['music_document']
                                                      as String;
                                              final key = playlist[index]
                                                      ['key'] ??
                                                  'key Desconhecido';

                                              final link =
                                                  playlist[index]['link'] ?? '';

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
                                                  if (!mounted) {
                                                    return SizedBox.shrink();
                                                  }
                                                  if (musicSnapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return CircularProgressIndicator();
                                                  }

                                                  if (musicSnapshot.hasError) {
                                                    return Text(
                                                        'Erro ao carregar música');
                                                  }

                                                  if (!musicSnapshot.hasData ||
                                                      !musicSnapshot
                                                          .data!.exists) {
                                                    return Text(
                                                        'Música não encontrada');
                                                  }

                                                  final musicData =
                                                      musicSnapshot.data!.data()
                                                          as Map<String,
                                                              dynamic>;
                                                  final musica =
                                                      musicData['Music'] ??
                                                          'Música Desconhecida';
                                                  final author =
                                                      musicData['Author'] ??
                                                          'Autor Desconhecido';

                                                  return Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          musica,
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
                                                          author,
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ),
                                                      Text(
                                                        key, // Aqui você pode mostrar o tom da música
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      PopupMenuButton<String>(
                                                        color: Colors.black,
                                                        iconColor: Colors.white,
                                                        onSelected: (String
                                                            value) async {
                                                          if (value ==
                                                              'update') {
                                                            _showUpdateLinkDialog(
                                                                context,
                                                                index,
                                                                link); // Passa o índice para o método
                                                          } else if (value ==
                                                              'delete') {
                                                            _removeItemFromPlaylist(
                                                                context,
                                                                index,
                                                                widget
                                                                    .documentId,
                                                                musicDocumentId);
                                                          }
                                                        },
                                                        itemBuilder:
                                                            (BuildContext
                                                                    context) =>
                                                                [
                                                          PopupMenuItem<String>(
                                                            value: 'update',
                                                            child: Text(
                                                              'Alterar Link do Vídeo',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 8),
                                                            ),
                                                          ),
                                                          PopupMenuItem<String>(
                                                            value: 'delete',
                                                            child: Text(
                                                              'Deletar Canção',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 8),
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ]),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddtoPlaylist(
                                      document_id: widget.documentId,
                                    ),
                                  ),
                                ).then((value) {
                                  // Após retornar da tela de adicionar música, você pode atualizar a página
                                  setState(() {});
                                  // Ou atualizar de acordo com a necessidade do seu fluxo
                                });
                                ;
                                //Navigator.pushNamed(
                                //    context, '/adminCultoForm');

                                //Navigator.pushNamed(
                                //    context, '/adminCultoForm');
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                margin: EdgeInsets.only(top: 24, bottom: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Color(0xff4465D9),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(0.0),
                                  child: Center(
                                    child: Text(
                                      "+",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 24),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateLinkDialog(BuildContext context, int index, String link) {
    final TextEditingController _linkController = TextEditingController();
    _linkController.text = link; // Carrega o link atual no TextField

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Link Youtube'),
          content: TextField(
            controller: _linkController,
            decoration: InputDecoration(
              labelText: 'Link',
              hintText: 'Cole aqui o link do youtube',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                String newLink = _linkController.text;
                if (newLink.isNotEmpty) {
                  await _updatePlaylistLink(index, newLink);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Atualizar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updatePlaylistLink(int index, String newLink) async {
    try {
      DocumentReference documentRef = FirebaseFirestore.instance
          .collection('Cultos')
          .doc(widget.documentId);

      // Obtenha o documento
      DocumentSnapshot doc = await documentRef.get();

      if (doc.exists) {
        // Obtenha o array de playlists
        List<dynamic> playlist = doc['playlist'] ?? [];

        // Verifique se o índice está dentro dos limites
        if (index >= 0 && index < playlist.length) {
          // Atualize o campo 'link' do item específico no array
          playlist[index]['link'] = newLink;

          // Atualize o documento com o novo array
          await documentRef.update({
            'playlist': playlist,
          });

          setState(() {
            // Atualize o estado local se necessário
          });

          print('Link atualizado com sucesso.');
        } else {
          print('Índice fora dos limites.');
        }
      } else {
        print('Documento não encontrado.');
      }
    } catch (e) {
      print('Erro ao atualizar o link: $e');
    }
  }

  // Função para remover um item da playlist
  Future<void> _removeItemFromPlaylist(BuildContext context, int index,
      String documentId, String musicDocumentId) async {
    try {
      // Obtém o documento atual da coleção 'Cultos'
      DocumentSnapshot cultoSnapshot = await FirebaseFirestore.instance
          .collection('Cultos')
          .doc(documentId)
          .get();

      if (cultoSnapshot.exists) {
        // Obtém os dados do documento
        Map<String, dynamic> cultoData =
            cultoSnapshot.data() as Map<String, dynamic>;
        List<dynamic> playlist = cultoData['playlist'] ?? [];

        // Remove o item da lista com base no índice
        playlist.removeAt(index);

        // Atualiza o documento com a nova lista de playlist
        await FirebaseFirestore.instance
            .collection('Cultos')
            .doc(documentId)
            .update({'playlist': playlist});

        // Atualiza a UI se necessário
        setState(() {});
      }
    } catch (e) {
      // Lida com erros
      print('Erro ao remover item da playlist: $e');
    }
  }
}

class CircularKeySelector extends StatefulWidget {
  final Function(String) onSelect;
  final String? initialKey;

  const CircularKeySelector({required this.onSelect, this.initialKey, Key? key})
      : super(key: key);

  @override
  _CircularKeySelectorState createState() => _CircularKeySelectorState();
}

class _CircularKeySelectorState extends State<CircularKeySelector> {
  final List<String> keys = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B'
  ];
  String? selectedKey;
  double currentAngle = 0.0;
  Offset? currentOffset;

  @override
  void initState() {
    super.initState();
    selectedKey = widget.initialKey;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          currentOffset = details.localPosition;
          _updateSelectedKey();
        });
      },
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: CirclePainter(keys, selectedKey, currentAngle),
            ),
            Center(
              child: Text(
                selectedKey ?? 'Selecione o tom',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateSelectedKey() {
    if (currentOffset != null) {
      final center = Offset(100, 100);
      final dx = currentOffset!.dx - center.dx;
      final dy = currentOffset!.dy - center.dy;
      final angle =
          atan2(dy, dx) + pi / 2; // Ajusta o ângulo para começar no topo
      final distance = sqrt(dx * dx + dy * dy);

      if (distance < 80) {
        // Garante que o movimento está dentro do círculo
        final index = ((angle / (2 * pi) * keys.length).floor() % keys.length);
        setState(() {
          selectedKey = keys[index];
          currentAngle = -angle; // Rotaciona o círculo para a posição do dedo
        });
        widget
            .onSelect(selectedKey!); // Atualiza o tom selecionado no widget pai
      }
    }
  }
}

class CirclePainter extends CustomPainter {
  final List<String> keys;
  final String? selectedKey;
  final double rotationAngle;

  CirclePainter(this.keys, this.selectedKey, this.rotationAngle);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Paint selectedPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final double radius = size.width / 2;
    final double circleRadius = radius - 20;
    final double centerX = radius;
    final double centerY = radius;

    canvas.translate(centerX, centerY);
    canvas.rotate(rotationAngle);

    for (int i = 0; i < keys.length; i++) {
      final angle = 2 * pi * i / keys.length;
      final offset = Offset(
        cos(angle) * circleRadius,
        sin(angle) * circleRadius,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: keys[i],
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final textOffset = Offset(
        offset.dx - textPainter.width / 2,
        offset.dy - textPainter.height / 2,
      );

      textPainter.paint(canvas, textOffset);
    }

    if (selectedKey != null) {
      final selectedIndex = keys.indexOf(selectedKey!);
      final selectedAngle = 2 * pi * selectedIndex / keys.length;
      final selectedOffset = Offset(
        cos(selectedAngle) * circleRadius,
        sin(selectedAngle) * circleRadius,
      );

      canvas.drawCircle(selectedOffset, 10, selectedPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
