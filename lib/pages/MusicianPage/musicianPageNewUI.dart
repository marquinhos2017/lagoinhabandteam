import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/pages/MusicianPage/ScheduleDetailsMusician.dart';
import 'package:lagoinha_music/pages/login.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class BoolStringPair {
  bool booleanValue;
  String stringValue;

  BoolStringPair(this.booleanValue, this.stringValue);
}

class MusicianPageNewUI extends StatefulWidget {
  const MusicianPageNewUI({super.key, required this.id});

  final String id;

  @override
  State<MusicianPageNewUI> createState() => _MusicianPageNewUIState();
}

class _MusicianPageNewUIState extends State<MusicianPageNewUI> {
  int _selectedIndex = -1; // No card is selected initially
  int _currentIndex = 0;
  late PageController _pageController;

  int cultosCount = 0; // Variável para armazenar a contagem de cultos
  String mesIdEspecifico = "";
  bool _buttonClicked = false;
  Map<int, BoolStringPair> checkedItems = {};

  Future<String> loadInstrumentForDocument(
      String userId, String cultoId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('user_culto_instrument')
          .where('idUser', isEqualTo: int.parse(widget.id))
          .where('idCulto', isEqualTo: cultoId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first['Instrument'] ??
            'Instrumento Desconhecido';
      } else {
        return 'Instrumento Desconhecido';
      }
    } catch (e) {
      print('Erro ao carregar instrumento: $e');
      return 'Instrumento Desconhecido';
    }
  }

  void onCheckboxChanged(int index, bool value, String docId) {
    setState(() {
      checkedItems[index] = BoolStringPair(value, docId);
    });
  }

  late int count;

  @override
  void initState() {
    super.initState();
    print("ID do usuario");
    _pageController = PageController(initialPage: _currentIndex);

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
    contarCultosDoUsuario();

    verificarVerFormulario();
  }

  Future<void> encontrarDocumentos(String userID) async {
    try {
      // Faz a consulta no Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Cultos')
          .where('musicos', arrayContains: userID)
          .get();

      // Itera sobre os documentos encontrados
      querySnapshot.docs.forEach((doc) {
        // Aqui você pode acessar os dados de cada documento
        Object? data = doc.data();
        print('ID do documento: ${doc.id}');
        print('Dados do documento: $data');
      });
    } catch (e) {
      print('Erro ao encontrar documentos: $e');
    }
  }

  Future<Map<String, dynamic>> fetchData(String musicianId) async {
    try {
      // Espera pelo menos 2 segundos antes de retornar os dados
      await Future.delayed(Duration(seconds: 1));

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
      QuerySnapshot querySnapshot = await _firestore
          .collection('musicos')
          .where('user_id', isEqualTo: int.parse(musicoId))
          .get();

      print("Query: ");
      print(querySnapshot);

      if (querySnapshot.docs.isNotEmpty) {
        // Se encontrou um documento com o user_id especificado
        setState(() {
          verFormulario = querySnapshot.docs.first['ver_formulario'] ?? false;
          mesIdEspecifico = querySnapshot.docs.first['doc_formulario'];
          print("Formulario Ativo " + mesIdEspecifico);
        });
      } else {
        // Se não encontrou nenhum documento com o user_id especificado
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

  Future<void> contarCultosDoUsuario() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Cultos')
          .where('musicos',
              arrayContains: {'user_id': int.parse(widget.id)}).get();

      setState(() {
        cultosCount = querySnapshot.size; // Armazena a contagem de cultos
      });
    } catch (e) {
      print('Erro ao contar cultos: $e');
    }
  }

  void onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void onNavBarTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Função para salvar os dados no Firestore
  Future<void> salvarDados(String musicoId) async {
    print(musicoId);
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
      await _firestore
          .collection('musicos')
          .where('user_id',
              isEqualTo: int.parse(widget.id)) // Filtra pelo user_id desejado
          .get()
          .then((querySnapshot) {
        if (querySnapshot.size > 0) {
          querySnapshot.docs.forEach((doc) async {
            await doc.reference.update({
              'ver_formulario': false,
            });
          });
        } else {
          print('Nenhum documento encontrado com user_id ${widget.id}');
        }
      });
      print('Documento atualizado com sucesso!');
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
    print("User_id: " + widget.id);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Home"),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: onPageChanged,
            physics: NeverScrollableScrollPhysics(),
            children: [
              SingleChildScrollView(
                // physics: NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                    ),
                    Visibility(
                      visible: !verFormulario,
                      child: Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sexta-Feira, 05 de Agosto',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xffD9D9D9),
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Text('Bom dia, Nicole!',
                                          style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (context) {
                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              ListTile(
                                                leading: Icon(Icons.abc),
                                                title: Text('Editar Perfil'),
                                                onTap: () {
                                                  // Ação para Opção 1

                                                  Navigator.pop(context);
                                                },
                                              ),
                                              ListTile(
                                                leading: Icon(Icons.logout),
                                                title: Text('Sair'),
                                                onTap: () {
                                                  // Ação para Opção 2
                                                  Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            login()),
                                                  );
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: Container(
                                      width: 50, // Largura do ícone
                                      height: 50, // Altura do ícone
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color.fromARGB(
                                                60,
                                                0,
                                                0,
                                                0), // Sombra alaranjada com 50% de opacidade
                                            blurRadius: 15,
                                            offset: Offset(0,
                                                10), // Deslocamento da sombra
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        // Pode adicionar uma imagem ou ícone dentro do CircleAvatar
                                        backgroundImage: AssetImage(
                                            'assets/profile.png'), // Substitua pelo caminho da sua imagem
                                        // Ou use um ícone ao invés de uma imagem
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                "NESSA SEMANA ",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              height: 200,
                              margin: EdgeInsets.only(top: 20),
                              child: FutureBuilder<QuerySnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('Cultos')
                                    .orderBy("date")
                                    .where('musicos', arrayContains: {
                                  'user_id': int.parse(widget.id)
                                }).get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  }

                                  if (snapshot.hasError) {
                                    return Center(
                                        child: Text('Erro: ${snapshot.error}'));
                                  }

                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return Center(
                                        child:
                                            Text('Nenhum culto encontrado.'));
                                  }

                                  List<DocumentSnapshot> docs =
                                      snapshot.data!.docs;

                                  // Obtém o intervalo da semana atual
                                  DateTime now = DateTime.now();
                                  DateTime startOfWeek = now.subtract(
                                      Duration(days: now.weekday - 1));
                                  DateTime endOfWeek =
                                      startOfWeek.add(Duration(days: 6));

                                  // Filtra os documentos para obter apenas os cultos desta semana
                                  List<DocumentSnapshot> weeklyDocs =
                                      docs.where((doc) {
                                    DateTime cultoDate =
                                        (doc['date'] as Timestamp).toDate();
                                    return cultoDate.isAfter(startOfWeek
                                            .subtract(Duration(seconds: 1))) &&
                                        cultoDate.isBefore(
                                            endOfWeek.add(Duration(days: 1)));
                                  }).toList();

                                  if (weeklyDocs.isEmpty) {
                                    return Center(
                                        child:
                                            Text('Nenhum culto nesta semana.'));
                                  }

                                  // Lista para armazenar todas as músicas de todos os cultos
                                  List<List<Map<String, dynamic>>>
                                      allMusicDataList = List.generate(
                                          weeklyDocs.length, (_) => []);

                                  // Função para carregar as músicas de um culto específico
                                  Future<void> loadMusicsForDocument(
                                      int docIndex) async {
                                    final doc = weeklyDocs[docIndex];
                                    print("Doc: " + doc.id);
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final playlist =
                                        data['playlist'] as List<dynamic>?;

                                    if (playlist != null) {
                                      List<Future<DocumentSnapshot>>
                                          musicFutures = playlist.map((song) {
                                        String musicDocumentId =
                                            song['music_document'] as String;
                                        return FirebaseFirestore.instance
                                            .collection('music_database')
                                            .doc(musicDocumentId)
                                            .get();
                                      }).toList();

                                      List<DocumentSnapshot> musicSnapshots =
                                          await Future.wait(musicFutures);
                                      List<Map<String, dynamic>> musicDataList =
                                          musicSnapshots.map((musicSnapshot) {
                                        if (musicSnapshot.exists) {
                                          Map<String, dynamic> musicData =
                                              musicSnapshot.data()
                                                  as Map<String, dynamic>;
                                          musicData['document_id'] =
                                              musicSnapshot
                                                  .id; // Adiciona o documentId

                                          // Encontra o item correspondente no playlist para adicionar a key e link
                                          var song = playlist.firstWhere(
                                            (song) =>
                                                song['music_document'] ==
                                                musicSnapshot.id,
                                            orElse: () => null,
                                          );

                                          if (song != null) {
                                            musicData['key'] = song[
                                                'key']; // Adiciona o campo key
                                            musicData['link'] = song['link'] ??
                                                'Link não disponível'; // Adiciona o campo link
                                          } else {
                                            // Caso não encontre a música no playlist, define valores padrão para key e link
                                            musicData['key'] =
                                                'Key Desconhecida';
                                            musicData['link'] =
                                                'Link não disponível';
                                          }

                                          return musicData;
                                        } else {
                                          return {
                                            'Music': 'Música Desconhecida',
                                            'Author': 'Autor Desconhecido',
                                            'key': 'Key Desconhecida',
                                            'link':
                                                'Link não disponível', // Adiciona o campo link
                                            'document_id':
                                                '', // Adiciona um campo vazio se o documento não existir
                                          };
                                        }
                                      }).toList();

                                      allMusicDataList[docIndex] =
                                          musicDataList;
                                    }
                                  }

                                  // Carregar as músicas para todos os documentos
                                  Future<void> loadAllMusics() async {
                                    for (int i = 0;
                                        i < weeklyDocs.length;
                                        i++) {
                                      await loadMusicsForDocument(i);
                                    }
                                  }

                                  return FutureBuilder<void>(
                                    future: loadAllMusics(),
                                    builder: (context, musicSnapshot) {
                                      if (musicSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      }

                                      if (musicSnapshot.hasError) {
                                        return Center(
                                            child: Text(
                                                'Erro ao carregar músicas'));
                                      }

                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: List.generate(
                                              weeklyDocs.length, (index) {
                                            bool isSelected =
                                                _selectedIndex == index;
                                            DocumentSnapshot doc =
                                                weeklyDocs[index];
                                            Map<String, dynamic> data = doc
                                                .data() as Map<String, dynamic>;
                                            DateTime cultoDate =
                                                (data['date'] as Timestamp)
                                                    .toDate();

                                            String Horario = (data['horario']);

                                            return FutureBuilder<String>(
                                                future:
                                                    loadInstrumentForDocument(
                                                        widget.id, doc.id),
                                                builder: (context,
                                                    instrumentSnapshot) {
                                                  String instrumentText =
                                                      'Instrumento Desconhecido';
                                                  if (instrumentSnapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return Center(
                                                        child:
                                                            CircularProgressIndicator());
                                                  }

                                                  if (instrumentSnapshot
                                                      .hasData) {
                                                    instrumentText =
                                                        instrumentSnapshot
                                                            .data!;
                                                  } else if (instrumentSnapshot
                                                      .hasError) {
                                                    print(
                                                        'Erro ao carregar instrumento: ${instrumentSnapshot.error}');
                                                  }

                                                  return GestureDetector(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        PageRouteBuilder(
                                                          pageBuilder: (context,
                                                                  animation,
                                                                  secondaryAnimation) =>
                                                              ScheduleDetailsMusician(
                                                            documents:
                                                                weeklyDocs,
                                                            id: doc.id,
                                                            currentIndex: index,
                                                            musics:
                                                                allMusicDataList,
                                                          ),
                                                          transitionsBuilder:
                                                              (context,
                                                                  animation,
                                                                  secondaryAnimation,
                                                                  child) {
                                                            const begin = Offset(
                                                                1.0,
                                                                0.0); // Início do movimento (fora da tela, à direita)
                                                            const end = Offset
                                                                .zero; // Fim do movimento (posição final)
                                                            const curve = Curves
                                                                .easeInOut;

                                                            var tween = Tween(
                                                                    begin:
                                                                        begin,
                                                                    end: end)
                                                                .chain(CurveTween(
                                                                    curve:
                                                                        curve));
                                                            var offsetAnimation =
                                                                animation.drive(
                                                                    tween);

                                                            return SlideTransition(
                                                              position:
                                                                  offsetAnimation,
                                                              child: child,
                                                            );
                                                          },
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      margin:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 24.0),
                                                      width:
                                                          300, // Ajusta a largura se selecionado
                                                      height:
                                                          160, // Ajusta a altura se selecionado
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        gradient:
                                                            LinearGradient(
                                                          colors: [
                                                            Color.fromARGB(
                                                                255, 0, 0, 0),
                                                            Color(0xff000000),
                                                          ],
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Color(
                                                                0xff000000),
                                                            blurRadius: 24,
                                                            offset:
                                                                Offset(16, 8),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(24.0),
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .start,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  data['nome'] ??
                                                                      'Culto',
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        20,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  instrumentText,
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                    fontSize:
                                                                        10,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            Text(
                                                              Horario +
                                                                  " " +
                                                                  DateFormat(
                                                                          'MMM d, EEEE')
                                                                      .format(
                                                                          cultoDate),
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                });
                                          }),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0, vertical: 0),
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "CONFIRMADO ",
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                              color: Color(0xff000000),
                                              borderRadius:
                                                  BorderRadius.circular(100)),
                                          child: Center(
                                            child: Text(
                                              cultosCount.toString(),
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                height: 400,
                                margin: EdgeInsets.only(bottom: 100),
                                child: FutureBuilder<QuerySnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('Cultos')
                                      .orderBy("date")
                                      .where('musicos', arrayContains: {
                                    'user_id': int.parse(widget.id)
                                  }).get(), // Obtendo todos os documentos uma vez
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                          child: CircularProgressIndicator());
                                    }

                                    if (snapshot.hasError) {
                                      return Center(
                                          child:
                                              Text('Erro: ${snapshot.error}'));
                                    }

                                    if (!snapshot.hasData ||
                                        snapshot.data!.docs.isEmpty) {
                                      return Center(
                                          child:
                                              Text('Nenhum culto encontrado.'));
                                    }

                                    List<DocumentSnapshot> docs =
                                        snapshot.data!.docs;

                                    // Lista para armazenar todas as músicas de todos os cultos
                                    List<List<Map<String, dynamic>>>
                                        allMusicDataList =
                                        List.generate(docs.length, (_) => []);

                                    // Função para carregar as músicas de um culto específico
                                    Future<void> loadMusicsForDocument(
                                        int docIndex) async {
                                      final doc = docs[docIndex];
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      final playlist =
                                          data['playlist'] as List<dynamic>?;
                                      print(playlist);

                                      if (playlist != null) {
                                        List<Future<DocumentSnapshot>>
                                            musicFutures = playlist.map((song) {
                                          String musicDocumentId =
                                              song['music_document'] as String;
                                          return FirebaseFirestore.instance
                                              .collection('music_database')
                                              .doc(musicDocumentId)
                                              .get();
                                        }).toList();

                                        List<DocumentSnapshot> musicSnapshots =
                                            await Future.wait(musicFutures);
                                        List<Map<String, dynamic>>
                                            musicDataList =
                                            musicSnapshots.map((musicSnapshot) {
                                          if (musicSnapshot.exists) {
                                            Map<String, dynamic> musicData =
                                                musicSnapshot.data()
                                                    as Map<String, dynamic>;
                                            musicData['document_id'] =
                                                musicSnapshot
                                                    .id; // Adiciona o documentId

                                            // Encontra o item correspondente no playlist para adicionar a key e link
                                            var song = playlist.firstWhere(
                                              (song) =>
                                                  song['music_document'] ==
                                                  musicSnapshot.id,
                                              orElse: () => null,
                                            );

                                            if (song != null) {
                                              musicData['key'] = song[
                                                  'key']; // Adiciona o campo key
                                              musicData['link'] = song[
                                                      'link'] ??
                                                  'Link não disponível'; // Adiciona o campo link
                                            } else {
                                              // Caso não encontre a música no playlist, define valores padrão para key e link
                                              musicData['key'] =
                                                  'Key Desconhecida';
                                              musicData['link'] =
                                                  'Link não disponível';
                                            }

                                            return musicData;
                                          } else {
                                            return {
                                              'Music': 'Música Desconhecida',
                                              'Author': 'Autor Desconhecido',
                                              'key': 'Key Desconhecida',
                                              'link':
                                                  'Link não disponível', // Adiciona o campo link
                                              'document_id':
                                                  '', // Adiciona um campo vazio se o documento não existir
                                            };
                                          }
                                        }).toList();

                                        allMusicDataList[docIndex] =
                                            musicDataList;
                                      }
                                    }

                                    // Carregar as músicas para todos os documentos
                                    Future<void> loadAllMusics() async {
                                      for (int i = 0; i < docs.length; i++) {
                                        await loadMusicsForDocument(i);
                                      }
                                    }

                                    return FutureBuilder<void>(
                                      future: loadAllMusics(),
                                      builder: (context, musicSnapshot) {
                                        if (musicSnapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Center(
                                              child:
                                                  CircularProgressIndicator());
                                        }

                                        if (musicSnapshot.hasError) {
                                          return Center(
                                              child: Text(
                                                  'Erro ao carregar músicas'));
                                        }

                                        return Container(
                                          margin: EdgeInsets.only(bottom: 120),
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            itemCount: docs.length,
                                            itemBuilder: (context, index) {
                                              Map<String, dynamic> data =
                                                  docs[index].data()
                                                      as Map<String, dynamic>;
                                              String idDocument =
                                                  docs[index].id;

                                              DateTime? dataDocumento;
                                              try {
                                                dataDocumento =
                                                    (data['date'] as Timestamp?)
                                                        ?.toDate();
                                              } catch (e) {
                                                print(
                                                    'Erro ao converter data: $e');
                                                dataDocumento = null;
                                              }

                                              return FutureBuilder<String>(
                                                  future:
                                                      loadInstrumentForDocument(
                                                          widget.id,
                                                          idDocument),
                                                  builder: (context,
                                                      instrumentSnapshot) {
                                                    String instrumentText =
                                                        'Instrumento Desconhecido';
                                                    if (instrumentSnapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return Center(
                                                          child:
                                                              CircularProgressIndicator());
                                                    }

                                                    if (instrumentSnapshot
                                                        .hasData) {
                                                      instrumentText =
                                                          instrumentSnapshot
                                                              .data!;
                                                    } else if (instrumentSnapshot
                                                        .hasError) {
                                                      print(
                                                          'Erro ao carregar instrumento: ${instrumentSnapshot.error}');
                                                    }

                                                    return GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          PageRouteBuilder(
                                                            pageBuilder: (context,
                                                                    animation,
                                                                    secondaryAnimation) =>
                                                                ScheduleDetailsMusician(
                                                              documents: docs,
                                                              id: idDocument,
                                                              currentIndex:
                                                                  index,
                                                              musics:
                                                                  allMusicDataList,
                                                            ),
                                                            transitionsBuilder:
                                                                (context,
                                                                    animation,
                                                                    secondaryAnimation,
                                                                    child) {
                                                              const begin = Offset(
                                                                  1.0,
                                                                  0.0); // Início do movimento (fora da tela, à direita)
                                                              const end = Offset
                                                                  .zero; // Fim do movimento (posição final)
                                                              const curve =
                                                                  Curves
                                                                      .easeInOut;

                                                              var tween = Tween(
                                                                      begin:
                                                                          begin,
                                                                      end: end)
                                                                  .chain(CurveTween(
                                                                      curve:
                                                                          curve));
                                                              var offsetAnimation =
                                                                  animation
                                                                      .drive(
                                                                          tween);

                                                              return SlideTransition(
                                                                position:
                                                                    offsetAnimation,
                                                                child: child,
                                                              );
                                                            },
                                                          ),
                                                        );
                                                      },
                                                      child: Column(
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: Container(
                                                              margin: EdgeInsets
                                                                  .only(
                                                                      bottom:
                                                                          12),
                                                              child: Row(
                                                                children: [
                                                                  Container(
                                                                    height: 78,
                                                                    width: 72,
                                                                    decoration: BoxDecoration(
                                                                        color: Colors
                                                                            .black,
                                                                        borderRadius:
                                                                            BorderRadius.circular(12)),
                                                                    margin: EdgeInsets.only(
                                                                        right:
                                                                            12),
                                                                    child:
                                                                        ClipRRect(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              12),
                                                                      child: Image
                                                                          .asset(
                                                                        data['nome'] ==
                                                                                "Culto da Fé"
                                                                            ? "assets/hq720.jpg"
                                                                            : "assets/hq720 (1).jpg", // URL da imagem
                                                                        fit: BoxFit
                                                                            .cover, // Ajusta a imagem para cobrir o container
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Column(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceAround,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Column(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.start,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Text(
                                                                            data['nome'],
                                                                            style:
                                                                                TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                                                          ),
                                                                          Text(
                                                                            instrumentText,
                                                                            style:
                                                                                TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      Text(
                                                                        "Noite, " +
                                                                            DateFormat('MMM d').format(dataDocumento!),
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                10,
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                      ),
                                                                    ],
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  });
                                            },
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (verFormulario)
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('Form_Mes_Cultos')
                              .where('mes_id', isEqualTo: mesIdEspecifico)
                              .orderBy(
                                'data',
                              )
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                  child: Text('Erro: ${snapshot.error}'));
                            }

                            if (!snapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }

                            final cultos = snapshot.data!.docs;
                            // print(verFormulario);

                            if (cultos.isEmpty) {
                              return Center(
                                  child: Text('Nenhum culto encontrado.'));
                            }

                            return ListView.builder(
                              itemCount: cultos.length,
                              itemBuilder: (context, index) {
                                var culto = cultos[index];

                                print(culto['data']);

                                String nomeDocumento = culto?['culto'] ??
                                    'Nome do Culto Indisponível';
                                DateTime? dataDocumento;
                                try {
                                  dataDocumento = culto?['data']?.toDate();
                                } catch (e) {
                                  print('Erro ao converter data: $e');
                                  dataDocumento = null;
                                }

                                print("Mostrando" + culto.id);

                                return CheckboxListTile(
                                  title: Text(
                                    'Culto: ${culto['culto']}',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  subtitle: dataDocumento != null
                                      ? Text(
                                          DateFormat('dd/MM/yyyy')
                                                  .format(dataDocumento!) +
                                              " -  ${culto['horario']}",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w300,
                                              fontSize: 10),
                                        )
                                      : Text(
                                          'Data Indisponível',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w300,
                                              fontSize: 10),
                                        ),
                                  value: checkedItems[index]?.booleanValue ??
                                      false,
                                  onChanged: (bool? value) {
                                    onCheckboxChanged(
                                        index, value ?? false, culto.id);
                                  },
                                );
                              },
                            );
                          },
                        ),
                      )
                    else
                      /*Center(
                    child: Text('Ver Formulario desativado'),
                  ),*/
                      FutureBuilder<Map<String, dynamic>>(
                        future: fetchData(widget.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Erro: ${snapshot.error}'));
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
                          final cultos = snapshot.data!['cultos']
                              as List<QueryDocumentSnapshot>;

                          // Filtra os cultos para verificar se o músico está escalado
                          final cultosEscalados = cultos.where((culto) {
                            final cultoData =
                                culto.data() as Map<String, dynamic>;
                            final musicos = cultoData['musicos'] != null
                                ? cultoData['musicos'] as List<dynamic>
                                : [];
                            return musicos.any(
                                (musico) => musico['name'] == musicianName);
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
                              padding: EdgeInsets.all(0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(bottom: 0),
                                    child: Text(
                                      "Cultos Escalados",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    height: 300,
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: cultosEscalados.length,
                                      itemBuilder: (context, index) {
                                        final culto = cultosEscalados[index]
                                            .data() as Map<String, dynamic>;
                                        return Container(
                                          margin: EdgeInsets.only(bottom: 10),
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(0)),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 30.0,
                                                        vertical: 0),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      culto['nome'],
                                                      style: TextStyle(
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14),
                                                    ),
                                                    Text(
                                                      "19:30 - 21:00",
                                                      style: TextStyle(
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.w300,
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
              ),
            ],
          ),
          /*Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BottomNavBar(
                currentIndex: _currentIndex,
                onTap: onNavBarTapped,
              ),
            ),
          ),*/
        ],
      ),
      floatingActionButton: Visibility(
        visible:
            verFormulario, // Mostra apenas se shouldShowFab for true e não estiver salvo
        child: FloatingActionButton(
          onPressed: () {
            String musicoId = widget.id; // Substitua pelo ID do músico logado
            salvarDados(musicoId);
          },
          child: Icon(Icons.save),
        ),
      ),
    );
  }
}

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      height: 95.0,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          AnimatedAlign(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: currentIndex == 0
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 46.0, right: 50.0, bottom: 6.0),
              child: Container(
                width: 80,
                height: 10,
                decoration: BoxDecoration(
                  color: Color(0xff000000),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          BottomNavigationBar(
            onTap: onTap,
            items: [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home), label: '', tooltip: "Home"),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: '',
              ),
            ],
            backgroundColor: Colors.transparent,
            selectedItemColor: Color(0xff000000),
            unselectedItemColor: Colors.grey,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            elevation: 0,
            enableFeedback: false,
            type: BottomNavigationBarType.fixed,
          ),
        ],
      ),
    );
  }
}
