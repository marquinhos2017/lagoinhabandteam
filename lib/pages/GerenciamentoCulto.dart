import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/pages/adminAddtoPlaylist.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:lagoinha_music/main.dart';
import 'package:lagoinha_music/pages/adminWorshipTeamSelect2.dart';
import 'package:lagoinha_music/pages/login.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

import 'package:path_provider/path_provider.dart';

class GerenciamentoCulto extends StatefulWidget {
  final String documentId;

  GerenciamentoCulto({required this.documentId});

  @override
  State<GerenciamentoCulto> createState() => _GerenciamentoCultoState();
}

class _GerenciamentoCultoState extends State<GerenciamentoCulto> {
  @override
  void initState() {
    super.initState();
    _fetchMusicianNames();
  }

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

  Future<List<Map<String, dynamic>>> _fetchMusiciansData() async {
    try {
      // Passo 1: Buscar todos os documentos da coleção 'user_culto_instrument'
      final idCulto = widget.documentId;
      final userCultoSnapshot = await _firestore
          .collection('user_culto_instrument')
          .where('idCulto', isEqualTo: idCulto)
          .get();

      // Lista para armazenar os futuros resultados
      final List<Future<Map<String, dynamic>>> futureList =
          userCultoSnapshot.docs.map((userCultoDoc) async {
        final userId = userCultoDoc['idUser'];

        // Passo 2: Buscar o nome do usuário na coleção 'musicos'
        final musicianSnapshot = await _firestore
            .collection('musicos')
            .where('user_id', isEqualTo: userId)
            .limit(1)
            .get();

        final name = musicianSnapshot.docs.isNotEmpty
            ? musicianSnapshot.docs.first.data()['name'] ??
                'Nome não encontrado'
            : 'Nome não encontrado';

        // Passo 3: Obter o instrumento do documento 'user_culto_instrument'
        final instrument =
            userCultoDoc.data()['Instrument'] ?? 'Instrumento não encontrado';

        return {
          'name': name,
          'instrument': instrument,
          'item': userCultoDoc.id,
        };
      }).toList();

      // Passo 4: Aguardar todos os futuros e retornar os resultados
      return Future.wait(futureList);
    } catch (e) {
      // Em caso de erro, retornar uma lista vazia ou lançar a exceção
      print('Erro ao buscar dados: $e');
      return [];
    }
  }

  Future<void> _removeMusician(int userId, String idCulto, String id) async {
    try {
      await _firestore.collection('Cultos').doc(idCulto).update({
        'musicos': FieldValue.arrayRemove([
          {'user_id': userId}
        ])
      });

      final documentRef =
          _firestore.collection('user_culto_instrument').doc(id);

      // Apaga o documento
      await documentRef.delete();

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

        for (var doc in userInstrumentSnapshot.docs) {
          final instrument = doc.data()['Instrument'] as String;
          instruments.add(instrument);
        }
      }

      return instruments.toList();
    } catch (e) {
      print('Erro ao buscar instrumentos: $e');
      return [];
    }
  }

  List<String> _musicianNames = [];
  bool _isLoading = true;
  String _errorMessage = '';

  Future<void> _fetchMusicianNames() async {
    try {
      // Passo 1: Obter todos os documentos de user_culto_instrument
      final userCultoSnapshot =
          await _firestore.collection('user_culto_instrument').get();

      if (userCultoSnapshot.docs.isEmpty) {
        setState(() {
          _musicianNames = [];
          _isLoading = false;
        });
        return;
      }

      // Passo 2: Criar uma lista de user_id a partir dos documentos
      final userIds =
          userCultoSnapshot.docs.map((doc) => doc['user_id'] as int).toSet();
      print(userIds);

      if (userIds.isEmpty) {
        setState(() {
          _musicianNames = [];
          _isLoading = false;
        });
        return;
      }

      // Passo 3: Buscar os nomes dos músicos usando os user_id
      final musicianSnapshots = await Future.wait(userIds.map((userId) =>
          _firestore
              .collection('musicos')
              .where('user_id', isEqualTo: userId)
              .get()));

      // Extrair nomes dos músicos
      final musicianNames = <String>{};
      for (final snapshot in musicianSnapshots) {
        for (final doc in snapshot.docs) {
          final name = doc['name'] as String?;
          if (name != null) {
            musicianNames.add(name);
          }
        }
      }

      // Atualizar o estado com os nomes dos músicos
      setState(() {
        _musicianNames = musicianNames.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao buscar dados: $e';
        _isLoading = false;
      });
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

            final instruments = futureSnapshot.data ?? [];

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
                  if (!instruments.contains('MD'))
                    _buildInstrumentButton(context, "MD"),
                  if (!instruments.contains('Ministro'))
                    _buildInstrumentButton(context, "Ministro"),
                  if (!instruments.contains('BV 1'))
                    _buildInstrumentButton(context, "BV 1"),
                  if (!instruments.contains('BV 2'))
                    _buildInstrumentButton(context, "BV 2"),
                  if (!instruments.contains('BV 3'))
                    _buildInstrumentButton(context, "BV 3"),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInstrumentButton(BuildContext context, String instrument) {
    print(instrument);
    String instrumenta = instrument;
    String a = "";
    if (instrumenta == "Piano") {
      a = "keyboard.png";
    }
    if (instrumenta == "Guitarra") {
      a = "guitarra.png";
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(60)),
        /* boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(
                60, 0, 0, 0), // Sombra alaranjada com 50% de opacidade
            blurRadius: 15,
            offset: Offset(0, 10), // Deslocamento da sombra
          ),
        ],,*/
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
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
        child: Container(
          margin: EdgeInsets.only(right: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image(height: 100, image: AssetImage("assets/" + a)),
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
          future: _fetchMusiciansData(),
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
                      style: TextStyle(color: Colors.black, fontSize: 12)),
                ),
              );
            }

            final musicoList = futureSnapshot.data!;

            return Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 1)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
                child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: musicoList.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      if (index >= musicoList.length) {
                        return SizedBox(); // Or another widget to handle empty cases
                      }

                      final musico = musicoList[index];
                      final name = musico['name'] ?? 'Nome não disponível';
                      final instrument =
                          musico['instrument'] ?? 'Instrumento não disponível';
                      final id = musico['item'] ?? 'Instrumento não disponível';

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          child: Column(
                            children: [
                              GestureDetector(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Dismissible(
                                        key: UniqueKey(), // Ensure a unique key
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          color: Colors.red,
                                          alignment: Alignment.centerRight,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 20),
                                          child: Icon(Icons.delete,
                                              color: Colors.black),
                                        ),
                                        onDismissed: (direction) async {
                                          if (_isProcessing || !mounted) return;

                                          setState(() {
                                            _isProcessing = true;
                                          });

                                          // Ensure we're working with the correct list
                                          final musicoToRemove =
                                              musicoList[index];
                                          final userId =
                                              musicoToRemove['user_id']
                                                      as int? ??
                                                  0;
                                          final idCulto = widget.documentId;

                                          // Perform removal operation
                                          print("Removing $id");

                                          // Assuming you want to also remove the item from the list
                                          // (You should do this only after successfully removing from the database)
                                          // setState(() {
                                          //   musicoList.removeAt(index);
                                          // });

                                          // Remove from Firestore
                                          // await _removeMusician(userId, id);

                                          setState(() {
                                            _isProcessing = false;
                                          });
                                        },
                                        child: ClipRect(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              if (instrument == "Piano")
                                                Container(
                                                  margin: EdgeInsets.only(
                                                      right: 24),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    child: Image(
                                                        height: 50,
                                                        image: AssetImage(
                                                            "assets/" +
                                                                "keyboard.png")),
                                                  ),
                                                ),
                                              if (instrument == "Guitarra")
                                                Container(
                                                  margin: EdgeInsets.only(
                                                      right: 24),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    child: Image(
                                                        height: 50,
                                                        image: AssetImage(
                                                            "assets/" +
                                                                "guitarra.png")),
                                                  ),
                                                ),
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Container(
                                                    margin: EdgeInsets.only(
                                                        right: 2),
                                                    child: Text(
                                                      instrument,
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xff558FFF),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  /*  Container(
                                                    margin: EdgeInsets.only(
                                                        right: 20),
                                                    child: Text(
                                                      instrument,
                                                      style: TextStyle(
                                                        color: Color(0xff558FFF),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),*/
                                                  IconButton(
                                                    icon: Icon(Icons.delete,
                                                        color: Colors.red),
                                                    onPressed: () async {
                                                      if (_isProcessing ||
                                                          !mounted) return;

                                                      setState(() {
                                                        _isProcessing = true;
                                                      });

                                                      final musicoToRemove =
                                                          musicoList[index];
                                                      final userId =
                                                          musicoToRemove[
                                                                      'user_id']
                                                                  as int? ??
                                                              0;
                                                      final idCulto =
                                                          widget.documentId;

                                                      // Perform removal operation
                                                      print("Removing $id");

                                                      // Remove from Firestore
                                                      await _removeMusician(
                                                          userId, idCulto, id);

                                                      // Update local list after successful Firestore operation
                                                      setState(() {
                                                        musicoList
                                                            .removeAt(index);
                                                        _isProcessing = false;
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
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
      backgroundColor: Colors.white,
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
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Playlist",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
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
                                      // width: MediaQuery.of(context).size.width,
                                      width: 46,
                                      // margin:
                                      //       EdgeInsets.only(top: 24, bottom: 16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.black,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(0.0),
                                        child: Center(
                                          child: Text(
                                            "+",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 24),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
                                                    return Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                              color:
                                                                  Colors.white),
                                                    );
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

                                                  return Dismissible(
                                                    key:
                                                        UniqueKey(), // Cada item deve ter uma chave única
                                                    direction: DismissDirection
                                                        .endToStart, // Define a direção do arrasto
                                                    background: Container(
                                                      color: Colors.red,
                                                      alignment:
                                                          Alignment.centerRight,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 20),
                                                      child: Icon(Icons.delete,
                                                          color: Colors.white),
                                                    ),
                                                    onDismissed:
                                                        (direction) async {
                                                      // Remove o item da playlist e do Firestore
                                                      await _removeItemFromPlaylist(
                                                          context,
                                                          index,
                                                          widget.documentId,
                                                          musicDocumentId);
                                                    },
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Text(
                                                                  musica,
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .black,
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                                SizedBox(
                                                                  width: 16,
                                                                ),
                                                                Container(
                                                                  color: Colors
                                                                      .black,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                    child: Text(
                                                                      key, // Aqui você pode mostrar o tom da música
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white,
                                                                          fontSize:
                                                                              12),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            Text(
                                                              author,
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ],
                                                        ),
                                                        PopupMenuButton<String>(
                                                          color: Colors.black,
                                                          iconColor:
                                                              Colors.black,
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
                                                              // Remover item ao clicar na opção "Deletar Canção"
                                                              await _removeItemFromPlaylist(
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
                                                            PopupMenuItem<
                                                                String>(
                                                              value: 'update',
                                                              child: Text(
                                                                'Alterar Link do Vídeo',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        8),
                                                              ),
                                                            ),
                                                            PopupMenuItem<
                                                                String>(
                                                              value: 'delete',
                                                              child: Text(
                                                                'Deletar Canção',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        8),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    )
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
                            ),
                            /*  GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UploadPage(culto: widget.documentId),
                                  ),
                                );
                              },
                              child: Text(
                                "asd",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CultoEspecificoPage(
                                        cultoEspecifico: widget.documentId),
                                  ),
                                );
                              },
                              child: Text(
                                "asdswq",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),*/
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    Container(
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
                            Text(
                              "Arquivos",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 24),
                            Container(
                              height: 100,
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('arquivos')
                                    .where('culto_especifico',
                                        isEqualTo: widget.documentId)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return Center(
                                        child:
                                            Text('Erro ao carregar arquivos.'));
                                  }
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  }

                                  final arquivos = snapshot.data!.docs;

                                  if (arquivos.isEmpty) {
                                    return Center(
                                        child:
                                            Text('Nenhum arquivo encontrado.'));
                                  }

                                  return ListView.builder(
                                    itemCount: arquivos.length,
                                    itemBuilder: (context, index) {
                                      var arquivoData = arquivos[index].data()
                                          as Map<String, dynamic>;
                                      var arquivoUrl =
                                          arquivoData['arquivo_url'] ?? '';
                                      var name =
                                          arquivoData['nome_arquivo'] ?? '';

                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          GestureDetector(
                                            onTap: () async {
                                              if (arquivoUrl.isNotEmpty) {
                                                // Baixar o arquivo quando o ícone é clicado
                                                await _downloadFile(
                                                    arquivoUrl, name);
                                              }
                                            },
                                            child: Row(
                                              children: [
                                                Icon(Icons.file_present),
                                                SizedBox(width: 12),
                                                Text(name,
                                                    style: TextStyle(
                                                        color: Colors.black)),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.download,
                                                    color: Colors.black),
                                                onPressed: () async {
                                                  // Confirmar exclusão
                                                  bool confirmar =
                                                      await showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        title: Text(
                                                            'Excluir Arquivo'),
                                                        content: Text(
                                                            'Tem certeza de que deseja excluir o arquivo "$name"?'),
                                                        actions: [
                                                          TextButton(
                                                            child: Text(
                                                                'Cancelar'),
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(false);
                                                            },
                                                          ),
                                                          TextButton(
                                                            child:
                                                                Text('Excluir'),
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(true);
                                                            },
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );

                                                  if (confirmar) {
                                                    try {
                                                      // Excluir o arquivo do Firebase Storage
                                                      if (arquivoUrl
                                                          .isNotEmpty) {
                                                        Reference
                                                            storageReference =
                                                            FirebaseStorage
                                                                .instance
                                                                .refFromURL(
                                                                    arquivoUrl);
                                                        await storageReference
                                                            .delete();
                                                      }

                                                      // Excluir o documento do Firestore
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection(
                                                              'arquivos')
                                                          .doc(arquivos[index]
                                                              .id)
                                                          .delete();

                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                              SnackBar(
                                                        content: Text(
                                                            'Arquivo excluído com sucesso!'),
                                                      ));
                                                    } catch (e) {
                                                      // Tratar possíveis erros
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                              SnackBar(
                                                        content: Text(
                                                            'Erro ao excluir o arquivo: $e'),
                                                      ));
                                                    }
                                                  }
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () async {
                                                  // Confirmar exclusão
                                                  bool confirmar =
                                                      await showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        title: Text(
                                                            'Excluir Arquivo'),
                                                        content: Text(
                                                            'Tem certeza de que deseja excluir o arquivo "$name"?'),
                                                        actions: [
                                                          TextButton(
                                                            child: Text(
                                                                'Cancelar'),
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(false);
                                                            },
                                                          ),
                                                          TextButton(
                                                            child:
                                                                Text('Excluir'),
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(true);
                                                            },
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );

                                                  if (confirmar) {
                                                    try {
                                                      // Excluir o arquivo do Firebase Storage
                                                      if (arquivoUrl
                                                          .isNotEmpty) {
                                                        Reference
                                                            storageReference =
                                                            FirebaseStorage
                                                                .instance
                                                                .refFromURL(
                                                                    arquivoUrl);
                                                        await storageReference
                                                            .delete();
                                                      }

                                                      // Excluir o documento do Firestore
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection(
                                                              'arquivos')
                                                          .doc(arquivos[index]
                                                              .id)
                                                          .delete();

                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                              SnackBar(
                                                        content: Text(
                                                            'Arquivo excluído com sucesso!'),
                                                      ));
                                                    } catch (e) {
                                                      // Tratar possíveis erros
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                              SnackBar(
                                                        content: Text(
                                                            'Erro ao excluir o arquivo: $e'),
                                                      ));
                                                    }
                                                  }
                                                },
                                              )
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UploadPage(culto: widget.documentId),
                                  ),
                                ).then((value) {
                                  setState(() {});
                                });
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                margin: EdgeInsets.only(),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.black,
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
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      child: Text(
                        "Arquivos",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Container(
                      height: 300,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('arquivos')
                            .where('culto_especifico',
                                isEqualTo: widget.documentId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Erro ao carregar arquivos.'));
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          final arquivos = snapshot.data!.docs;

                          if (arquivos.isEmpty) {
                            return Center(
                                child: Text('Nenhum arquivo encontrado.'));
                          }

                          return ListView.builder(
                            itemCount: arquivos.length,
                            itemBuilder: (context, index) {
                              var arquivoData = arquivos[index].data()
                                  as Map<String, dynamic>;
                              var arquivoUrl = arquivoData['arquivo_url'] ?? '';
                              var cultoEspecifico =
                                  arquivoData['culto_especifico'] ?? '';

                              return ListTile(
                                title: Text(
                                  'Arquivo ${index + 1}',
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(cultoEspecifico),
                                onTap: () {
                                  //     _baixarArquivo(context, arquivoUrl,
                                  //       'arquivo_${index + 1}.ext'); // Substitua ".ext" pela extensão apropriada
                                },
                              );
                            },
                          );
                        },
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

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      // Solicita permissão para acessar o armazenamento (necessário no Android)
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Permissão para acessar o armazenamento negada');
        }
      }

      // Obtém o diretório correto para salvar o arquivo
      final directory = Platform.isIOS
          ? await getApplicationDocumentsDirectory()
          : await getExternalStorageDirectory();

      if (directory == null) {
        throw Exception('Falha ao obter o diretório de armazenamento');
      }

      // Caminho completo para salvar o arquivo
      final filePath = '${directory.path}/$fileName';

      // Faz o download do arquivo
      Dio dio = Dio();
      await dio.download(url, filePath, onReceiveProgress: (received, total) {
        if (total != -1) {
          print((received / total * 100).toStringAsFixed(0) + "%");
        }
      });

      print('Arquivo salvo em: $filePath');
    } catch (e) {
      print('Erro ao baixar o arquivo: $e');
    }
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

class UploadPage extends StatefulWidget {
  final String culto;

  UploadPage({required this.culto});

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? _file;
  bool _uploading = false;
  double _progress = 0;
  String? _downloadURL;
  String? _cultoEspecifico;

  @override
  void initState() {
    super.initState();
    _cultoEspecifico = widget.culto;
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        _file = File(result.files.single.path!);
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_file == null || _cultoEspecifico == null || _cultoEspecifico!.isEmpty)
      return;

    setState(() {
      _uploading = true;
    });

    String fileName = _file!.path.split('/').last;
    Reference storageRef =
        FirebaseStorage.instance.ref().child('uploads/$fileName');

    UploadTask uploadTask = storageRef.putFile(_file!);

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      setState(() {
        _progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
      });
    });

    try {
      await uploadTask;

      // Obter a URL de download
      String downloadURL = await storageRef.getDownloadURL();
      setState(() {
        _downloadURL = downloadURL;
      });

      // Salvar a URL do arquivo, o culto_especifico, e o nome do arquivo no Firestore
      await _firestore.collection('arquivos').add({
        'arquivo_url': downloadURL,
        'culto_especifico': _cultoEspecifico,
        'nome_arquivo': fileName, // Salvando o nome do arquivo
        'created_at':
            Timestamp.now(), // Campo opcional para armazenar a data de criação
      });

      print('File uploaded and saved to Firestore: $downloadURL');
    } catch (e) {
      print('Upload failed: $e');
    }

    setState(() {
      _uploading = false;
      _progress = 0;
      _file = null;
      _cultoEspecifico = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload and Save to Firestore'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_file != null)
              Text('Selected file: ${_file!.path.split('/').last}'),
            SizedBox(height: 20),
            TextField(
              onChanged: (value) {
                setState(() {
                  _cultoEspecifico = widget.culto;
                });
              },
              decoration: InputDecoration(
                labelText: 'Culto Específico',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickFile,
              child: Text('Pick File'),
            ),
            SizedBox(height: 20),
            _uploading
                ? Column(
                    children: [
                      LinearProgressIndicator(value: _progress / 100),
                      SizedBox(height: 20),
                      Text('${_progress.toStringAsFixed(2)}% uploaded'),
                    ],
                  )
                : ElevatedButton(
                    onPressed: _uploadFile,
                    child: Text('Upload and Save'),
                  ),
            SizedBox(height: 20),
            if (_downloadURL != null)
              Column(
                children: [
                  Text('Download URL:'),
                  GestureDetector(
                    onTap: () {
                      // Código para abrir a URL
                    },
                    child: Text(
                      _downloadURL!,
                      style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class CultoEspecificoPage extends StatelessWidget {
  final String cultoEspecifico;

  CultoEspecificoPage({required this.cultoEspecifico});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Arquivos do Culto Específico'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('arquivos')
            .where('culto_especifico', isEqualTo: cultoEspecifico)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar arquivos.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final arquivos = snapshot.data!.docs;

          if (arquivos.isEmpty) {
            return Center(child: Text('Nenhum arquivo encontrado.'));
          }

          return ListView.builder(
            itemCount: arquivos.length,
            itemBuilder: (context, index) {
              var arquivoData = arquivos[index].data() as Map<String, dynamic>;
              var arquivoUrl = arquivoData['arquivo_url'] ?? '';
              var cultoEspecifico = arquivoData['culto_especifico'] ?? '';

              return ListTile(
                title: Text('Arquivo ${index + 1}'),
                subtitle: Text(cultoEspecifico),
                onTap: () {
                  _baixarArquivo(context, arquivoUrl,
                      'arquivo_${index + 1}.ext'); // Substitua ".ext" pela extensão apropriada
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _baixarArquivo(
      BuildContext context, String url, String fileName) async {
    try {
      // Obter o diretório para salvar o arquivo
      Directory dir =
          await getApplicationDocumentsDirectory(); // Usado para iOS e Android

      // Configurar o caminho do arquivo
      String filePath = path.join(dir.path, fileName);

      // Fazer o download do arquivo
      Dio dio = Dio();
      await dio.download(url, filePath);

      // Mostrar uma mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Download concluído: $filePath'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao baixar arquivo: $e'),
      ));
    }
  }
}
