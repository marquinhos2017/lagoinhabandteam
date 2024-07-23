import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleDetailsMusician extends StatefulWidget {
  final String id;
  final List<DocumentSnapshot> documents;
  final int currentIndex;
  final List<List<Map<String, dynamic>>> musics;

  const ScheduleDetailsMusician({
    required this.id,
    required this.documents,
    required this.currentIndex,
    required this.musics,
  });

  @override
  State<ScheduleDetailsMusician> createState() =>
      _ScheduleDetailsMusicianState();
}

class _ScheduleDetailsMusicianState extends State<ScheduleDetailsMusician> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _navigateToDocument(int index) {
    setState(() {
      currentIndex = index;
      isLoading = true;
    });
    //  _loadInitialData(widget.documents[index].id);
  }

  late int currentIndex;
  List<Map<String, dynamic>> musicos = [];
  String selectedMenu = 'Musicas';
  Map<String, dynamic>? cultoData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.currentIndex;

    //_loadInitialData();
  }

  Future<void> _loadInitialData([String? cultoId]) async {
    try {
      Map<String, dynamic> fetchedCultoData =
          await _getCultoData(cultoId ?? widget.id);
      setState(() {
        cultoData = fetchedCultoData;
        musicos = List<Map<String, dynamic>>.from(cultoData?['musicos'] ?? []);
        isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar dados iniciais: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _getCultoData(String cultoId) async {
    try {
      DocumentSnapshot cultoSnapshot =
          await _firestore.collection('Cultos').doc(cultoId).get();

      if (!cultoSnapshot.exists) {
        throw Exception('Culto não encontrado');
      }

      Map<String, dynamic> cultoData =
          cultoSnapshot.data() as Map<String, dynamic>;

      List<dynamic> playlist = cultoData['playlist'] ?? [];
      List<Map<String, dynamic>> loadedMusicas = [];
      List<Map<String, dynamic>> loadedMusicos = [];

      for (var item in playlist) {
        String musicDocumentId = item['music_document'];
        DocumentSnapshot musicSnapshot = await _firestore
            .collection('music_database')
            .doc(musicDocumentId)
            .get();

        if (musicSnapshot.exists) {
          loadedMusicas.add(musicSnapshot.data() as Map<String, dynamic>);
        } else {
          print('Música com ID $musicDocumentId não encontrada');
        }
      }

      cultoData['musicas'] = loadedMusicas;

      List<dynamic> musicosIds = cultoData['musicos'] ?? [];

      for (var item in musicosIds) {
        int userId = item['user_id'];
        QuerySnapshot userSnapshot = await _firestore
            .collection('musicos')
            .where('user_id', isEqualTo: userId)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          loadedMusicos
              .add(userSnapshot.docs.first.data() as Map<String, dynamic>);
        } else {
          print('Usuário com ID $userId não encontrado');
        }
      }

      cultoData['musicos'] = loadedMusicos;

      return cultoData;
    } catch (e) {
      print('Erro ao buscar dados do culto: $e');
      throw e;
    }
  }

  Widget _buildContent() {
    switch (selectedMenu) {
      case 'Musicas':

        // Acessa as músicas do culto atual utilizando o currentIndex
        List<Map<String, dynamic>> musicasAtuais = widget.musics[currentIndex];

        return ListView(
          children: musicasAtuais
              .map((musica) => ListTile(
                    title: Text(musica['Music'] ?? 'Título desconhecido'),
                    subtitle: Text(musica['Author'] ?? 'Autor desconhecido'),
                  ))
              .toList(),
        );
      case 'Ordem':
        return ListView(
          children: musicos
              .map((musico) => ListTile(
                    title: Text(musico['name'] ?? 'Nome desconhecido'),
                    subtitle: Text('ID: ${musico['user_id']}'),
                  ))
              .toList(),
        );
      case 'Ensaio':
        return Column(
          children: [
            Text('Ensaio Selecionado:'),
            ListTile(
              title: Text('Ensaio 1'),
            ),
            ListTile(
              title: Text('Ensaio 2'),
            ),
            ListTile(
              title: Text('Ensaio 3'),
            ),
          ],
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<DocumentSnapshot> documentsAll = widget.documents;
    final List<List<Map<String, dynamic>>> musicsAll = widget.musics;
    print(documentsAll[currentIndex]['nome']);
    print(musicsAll[currentIndex]);
    final id = documentsAll[currentIndex].id;

    return Scaffold(
      appBar: AppBar(
        title: Text("Service Details"),
        backgroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Color(0xff6B8E41)),
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 70),
                Text(
                  "Lagoinha Faro",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  documentsAll[currentIndex]['nome'] ?? 'Nome desconhecido',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      style: IconButton.styleFrom(
                          backgroundColor: Color(0xff81AC4C)),
                      icon: Icon(Icons.arrow_left, color: Colors.white),
                      onPressed: () {
                        if (currentIndex > 0) {
                          _navigateToDocument(currentIndex - 1);
                        } else {
                          print("Não há documento anterior.");
                        }
                      },
                    ),
                    IconButton(
                      style: IconButton.styleFrom(
                          backgroundColor: Color(0xff81AC4C)),
                      icon: Icon(Icons.arrow_right, color: Colors.white),
                      onPressed: () {
                        if (currentIndex < widget.documents.length - 1) {
                          _navigateToDocument(currentIndex + 1);
                        } else {
                          print("Não há documento seguinte.");
                        }
                      },
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Text(
                      documentsAll[currentIndex]['date'] != null
                          ? DateFormat('dd/MM/yyyy').format(
                              (documentsAll[currentIndex]['date'] as Timestamp)
                                  .toDate())
                          : 'Data desconhecida',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            color: Color(0xffEEEEEE),
            child: Container(
              child: Row(
                children: [
                  _buildMenuButton('Musicas'),
                  _buildMenuButton('Ordem'),
                  _buildMenuButton('Ensaio'),
                ],
              ),
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildMenuButton(String menu) {
    bool isSelected = selectedMenu == menu;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMenu = menu;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 10),
              child: Text(
                menu,
                style: TextStyle(
                    color: isSelected ? Colors.black : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ),
            if (isSelected)
              Container(
                margin: EdgeInsets.only(top: 4),
                height: 2,
                width: 60,
                color: Color(0xff81AC4C),
              ),
            if (!isSelected)
              Container(
                margin: EdgeInsets.only(top: 4),
                height: 2,
                width: 60,
                color: Colors.transparent,
              ),
          ],
        ),
      ),
    );
  }
}
