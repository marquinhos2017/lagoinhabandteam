import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class ScheduleDetailsMusician extends StatefulWidget {
  final String id;
  const ScheduleDetailsMusician({required this.id});

  @override
  State<ScheduleDetailsMusician> createState() =>
      _ScheduleDetailsMusicianState();
}

class _ScheduleDetailsMusicianState extends State<ScheduleDetailsMusician> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> musicos = [];
  String selectedMenu = 'Musicas';
  List<Map<String, dynamic>> musicas = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      Map<String, dynamic> cultoData = await _getCultoData(widget.id);
      setState(() {
        musicas = List<Map<String, dynamic>>.from(cultoData['musicas']);
      });
    } catch (e) {
      print('Erro ao carregar dados iniciais: $e');
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

      List<dynamic> playlist = cultoData['playlist'];
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

      List<dynamic> musicosIds = cultoData['musicos'];

      for (var item in musicosIds) {
        int userId = item['user_id'];
        QuerySnapshot userSnapshot = await _firestore
            .collection('musicos')
            .where('user_id', isEqualTo: userId)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          loadedMusicos
              .add(userSnapshot.docs.first.data() as Map<String, dynamic>);
          musicos = loadedMusicos;
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Detalhes do Culto"),
        backgroundColor: Color(0xff6B8E41),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
          future: _getCultoData(widget.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return Center(child: Text('Nenhum dado disponível'));
            }

            Map<String, dynamic> cultoData = snapshot.data!;
            List<Map<String, dynamic>> fetchedMusicas =
                List<Map<String, dynamic>>.from(cultoData['musicas']);

            DateTime? dataDocumento;
            try {
              dataDocumento = cultoData?['date']?.toDate();
            } catch (e) {
              print('Erro ao converter data: $e');
              dataDocumento = null;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        cultoData['nome'],
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_left, color: Colors.white),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_right, color: Colors.white),
                            onPressed: () {},
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(dataDocumento!),
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
              ],
            );
          }),
    );
  }

  Widget _buildMenuButton(String menu) {
    bool isSelected = selectedMenu == menu;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMenu = menu;
          if (menu == 'Musicas') {
            // Atualiza as músicas se 'Musicas' for selecionado
            _loadInitialData();
          }
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
