import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleDetailsMusician extends StatefulWidget {
  final String id;
  final List<DocumentSnapshot> documents;
  final int currentIndex;

  const ScheduleDetailsMusician(
      {required this.id, required this.documents, required this.currentIndex});

  @override
  State<ScheduleDetailsMusician> createState() =>
      _ScheduleDetailsMusicianState();
}

class _ScheduleDetailsMusicianState extends State<ScheduleDetailsMusician> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late int currentIndex;

  void _navigateToDocument(int index, String idDoc) {
    setState(() {
      currentIndex = index;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleDetailsMusician(
          id: idDoc,
          documents: widget.documents,
          currentIndex: index,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> musicos = [];
  String selectedMenu = 'Musicas';
  List<Map<String, dynamic>> musicas = [];
  Map<String, dynamic>? cultoData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    print(widget.currentIndex);
    currentIndex = widget.currentIndex;
    print(currentIndex);
  }

  Future<void> _loadInitialData() async {
    try {
      Map<String, dynamic> fetchedCultoData = await _getCultoData(widget.id);
      setState(() {
        cultoData = fetchedCultoData;
        musicas = List<Map<String, dynamic>>.from(cultoData?['musicas'] ?? []);
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
    if (cultoData == null) {
      return Center(child: Text('Nenhum dado disponível'));
    }

    switch (selectedMenu) {
      case 'Musicas':
        return ListView(
          children: musicas
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
    final id = documentsAll[currentIndex].id;
    print(id);

    print(documentsAll);

    return Scaffold(
      appBar: AppBar(
        title: Text("Detalhes do Culto"),
        backgroundColor: Color(0xff6B8E41),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cultoData != null) ...[
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: Color(0xff6B8E41)),
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 40),
                        Text(
                          "Lagoinha Faro",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          documentsAll![currentIndex]['nome'] ??
                              'Nome desconhecido',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_left, color: Colors.white),
                              onPressed: () {
                                currentIndex > 0
                                    ? _navigateToDocument(currentIndex - 1, id)
                                    : () {
                                        print(" Current Index: $currentIndex");
                                        print("Tamanho da Lista: ");
                                        print(widget.documents.length);
                                      };
                              },
                            ),
                            IconButton(
                              icon:
                                  Icon(Icons.arrow_right, color: Colors.white),
                              onPressed: () {
                                currentIndex < widget.documents.length - 1
                                    ? _navigateToDocument(currentIndex + 1, id)
                                    : () {
                                        print(" Current Index: $currentIndex");
                                        print("Tamanho da Lista: ");
                                        print(widget.documents.length);
                                      };
                              },
                            ),
                            Text(
                              documentsAll![currentIndex]['date'] != null
                                  ? DateFormat('dd/MM/yyyy').format(
                                      (documentsAll![currentIndex]['date']
                                              as Timestamp)
                                          .toDate())
                                  : 'Data desconhecida',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          cultoData!['horarios'] ?? 'Horários desconhecidos',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMenuButton('Musicas'),
                      _buildMenuButton('Ordem'),
                      _buildMenuButton('Ensaio'),
                    ],
                  ),
                  Expanded(child: _buildContent()),
                ] else if (isLoading) ...[
                  Center(child: CircularProgressIndicator()),
                ] else ...[
                  Center(child: Text('Nenhum dado disponível')),
                ],
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
      child: Column(
        children: [
          Text(
            menu,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected)
            Container(
              margin: EdgeInsets.only(top: 4),
              height: 2,
              width: 60,
              color: Colors.blue,
            ),
        ],
      ),
    );
  }
}
