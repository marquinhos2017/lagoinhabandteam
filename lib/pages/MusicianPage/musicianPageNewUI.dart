import 'package:cloud_firestore/cloud_firestore.dart';

//ESSE

import 'package:flutter/material.dart';
import 'package:lagoinha_music/main.dart';
import 'package:lagoinha_music/pages/MusicDataBase/BibliotecaMusical.dart';
import 'package:lagoinha_music/pages/MusicianPage/EditProfilePage.dart';
import 'package:lagoinha_music/pages/MusicianPage/ScheduleDetailsMusician.dart';
import 'package:lagoinha_music/pages/MusicianPage/afinador.dart';
import 'package:lagoinha_music/pages/login.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:flutter/material.dart';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:pitchupdart/instrument_type.dart';
import 'package:pitchupdart/pitch_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<QueryDocumentSnapshot> cultosDaSemana = [];

  // Função para calcular o início e fim da semana atual
  DateTime getStartOfWeek() {
    DateTime now = DateTime.now();
    return now.subtract(Duration(days: now.weekday));
  }

  DateTime getEndOfWeek() {
    DateTime startOfWeek = getStartOfWeek();
    return startOfWeek.add(Duration(days: 6));
  }

  Future<void> _logout(BuildContext context) async {
    // Remove os dados do usuário do SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Remove todos os dados armazenados

    // Retorna para a página de login
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const login()),
      (Route<dynamic> route) => false,
    );
  }

  // Função para buscar cultos da semana
  Future<void> fetchCultos(int userId) async {
    DateTime startOfWeek = getStartOfWeek();

    DateTime endOfWeek = getEndOfWeek();

    // Formatar as datas para Timestamp
    Timestamp startTimestamp = Timestamp.fromDate(startOfWeek);
    Timestamp endTimestamp = Timestamp.fromDate(endOfWeek);

    // Realizando a consulta no Firestore
    var querySnapshot = await FirebaseFirestore.instance
        .collection('Cultos')
        .where('date', isGreaterThanOrEqualTo: startTimestamp)
        .where('date', isLessThanOrEqualTo: endTimestamp)
        .get();
    print("Query");
    print(querySnapshot.docs);

    // Filtrando os cultos que contêm o user_id no array de músicos
    List<QueryDocumentSnapshot> filteredCultos =
        querySnapshot.docs.where((doc) {
      List<dynamic> musicos = doc['musicos'];
      return musicos.any((musico) => musico['user_id'] == userId);
    }).toList();
    print("Filtrdo");
    print(filteredCultos);

    setState(() {
      cultosDaSemana =
          filteredCultos; // Atualiza o estado com os cultos filtrados
    });
    print("Da Semna");
    print(cultosDaSemana);
  }

  String photoo = "";
  late Stream<QuerySnapshot> _userProfileStream;
  int _selectedIndex = -1; // No card is selected initially
  int _currentIndex = 0;
  late PageController _pageController;
  String avatar = "";

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

  String? musicianName;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    int userId = int.parse(widget.id); // Substitua pelo ID do usuário logado
    fetchCultos(userId); // Chama a função para buscar os cultos da semana
    print("asdasdasdasdasad");
    print(cultosDaSemana);

    _userProfileStream = FirebaseFirestore.instance
        .collection('musicos')
        .where('user_id',
            isEqualTo: int.parse(
                widget.id)) // Ajuste para o tipo correto se necessário
        .snapshots();
    _fetchUserProfile();
    print(widget.id);
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
    _fetchMusicianByUsrId();
  }

  Future<void> _navigateAndReload() async {
    // Navega para a página de edição e aguarda o retorno
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditProfilePage(
                userId: widget.id,
              )),
    );

    // Verifica se o resultado foi 'true' (se a página de edição retornou algo)
    if (result == true) {
      // Chama a função que carrega novamente os dados
      _reloadData();
    }
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(userId: widget.id),
      ),
    );

    // Verifique se o widget ainda está montado antes de chamar _loadUserProfile
    if (mounted && result == true) {
      print("retornou");
      _fetchUserProfile();
    }
  }

  Future<void> _reloadData() async {
    setState(() {
      isLoading = true; // Mostrar um indicador de carregamento se necessário
    });

    try {
      // Aqui você pode chamar as funções que recarregam os dados
      await _fetchMusicianByUsrId(); // Função que busca os dados do Firestore
      await contarCultosDoUsuario(); // Recarregar as contagens de cultos, por exemplo

      setState(() {
        isLoading = false; // Desativar o indicador de carregamento
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        // Tratar erros de carregamento se necessário
        errorMessage = 'Erro ao recarregar os dados: $e';
      });
    }
  }

  Future<void> _fetchMusicianByUsrId() async {
    try {
      // Busca o documento do músico no Firestore onde o campo usr_id é igual ao widget.id
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('musicos')
          .where('user_id', isEqualTo: int.parse(widget.id))
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Tratamento de erro caso nenhum documento seja encontrado
        setState(() {
          errorMessage =
              'Nenhum músico com usr_id ${widget.id} foi encontrado.';
          isLoading = false;
        });
      } else {
        // Extrai o campo "nome" do primeiro documento encontrado
        setState(() {
          musicianName = querySnapshot.docs.first['name'];
          avatar = querySnapshot.docs.first['photoUrl'];
          print(musicianName);
          isLoading = false;
        });
      }
    } catch (e) {
      // Tratamento de erros de exceções
      setState(() {
        errorMessage = 'Erro ao buscar os dados: $e';
        isLoading = false;
      });
    }
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
      Future<void> _fetchMusicianByUsrId() async {
        try {
          // Busca o documento do músico no Firestore onde o campo usr_id é igual ao widget.id
          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection('musicos')
              .where('usr_id', isEqualTo: widget.id)
              .get();

          if (querySnapshot.docs.isEmpty) {
            // Tratamento de erro caso nenhum documento seja encontrado
            setState(() {
              errorMessage =
                  'Nenhum músico com usr_id ${widget.id} foi encontrado.';
              isLoading = false;
            });
          } else {
            // Extrai o campo "nome" do primeiro documento encontrado
            setState(() {
              musicianName = querySnapshot.docs.first['nome'];
              isLoading = false;
            });
          }
        } catch (e) {
          // Tratamento de erros de exceções
          setState(() {
            errorMessage = 'Erro ao buscar os dados: $e';
            isLoading = false;
          });
        }
      }

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
          print("Juan");
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
          .get(); // Obtém todos os documentos da coleção Cultos

      // Filtra os documentos localmente
      int count = querySnapshot.docs.where((doc) {
        List<dynamic> musicos = doc['musicos'];
        return musicos
            .any((musico) => musico['user_id'] == int.parse(widget.id));
      }).length;

      setState(() {
        cultosCount = count; // Armazena a contagem de cultos
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

  Future<Map<String, dynamic>> _fetchUserProfile() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('musicos')
        .where('user_id', isEqualTo: int.parse(widget.id))
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot userDoc = querySnapshot.docs.first;
      return userDoc.data() as Map<String, dynamic>;
    } else {
      return {}; // Ou algum valor padrão
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenha a data atual
    DateTime now = DateTime.now();
    int getDayOfYear(DateTime date) {
      int dayOfYear = 0;
      for (int i = 1; i < date.month; i++) {
        dayOfYear += DateTime(date.year, i + 1, 0).day;
      }
      dayOfYear += date.day;
      return dayOfYear;
    }

    List<String> verses = [
      "Cantai ao Senhor um cântico novo, cantai ao Senhor, todas as terras. - Salmos 96:1",
      "Louvem-no com o som da trombeta; louvem-no com a lira e a harpa. - Salmos 150:3",
      "Bendirei o Senhor em todo tempo, o seu louvor estará sempre nos meus lábios. - Salmos 34:1",
      // Adicione mais 97 versículos...
    ];

    String getDailyVerse() {
      int dayOfYear = getDayOfYear(DateTime.now());
      int verseIndex = dayOfYear %
          verses.length; // Para garantir que esteja no intervalo da lista
      return verses[verseIndex];
    }

    // Formate a data usando DateFormat
    String formattedDate = DateFormat('EEEE, dd MMMM', 'pt_BR').format(now);

    final userId = Provider.of<AuthProvider>(context).userId;
    print("User_id: " + widget.id);
    if (widget.id == null) {
      return Center(
          child:
              CircularProgressIndicator()); // Ou qualquer outro indicador de carregamento
    }
// Definindo um número de notificações fictício
    int notificationCount = 4;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 20,
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
                          children: [
                            /*
                            Container(
                              height: 200,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: cultosDaSemana.map((document) {
                                  // Supondo que cada documento tenha campos como 'nome' e 'data'
                                  final data =
                                      document.data() as Map<String, dynamic>;
                                  final nome =
                                      data['nome'] ?? 'Nome não disponível';
                                  final dataCulto =
                                      data['date']?.toDate() ?? DateTime.now();

                                  final horarioCulto = data['horario'];

                                  return GestureDetector(
                                    child: ListTile(
                                      title: Text(nome),
                                      subtitle: Text(dataCulto.toString()),
                                      trailing: Text(horarioCulto),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),*/
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xffD9D9D9),
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        isLoading
                                            ? 'Carregando...' // Exibe enquanto carrega
                                            : errorMessage ??
                                                'Bom dia, ${musicianName?.toCapitalized() ?? 'Músico'}',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(
                                        height: 24,
                                      ),
                                      /*Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0,
                                                      vertical: 2),
                                              child: Text("Verso do Dia"),
                                            ),
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                    color: Colors.black)),
                                          ),
                                          Container(
                                            width: 180,
                                            child: Text(
                                              getDailyVerse(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),*/
                                    ],
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(top: 30),
                                    child: GestureDetector(
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          builder: (context) {
                                            return Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: <Widget>[
                                                ListTile(
                                                  leading: Icon(Icons.abc),
                                                  title: Text('Editar Perfil'),
                                                  onTap: () {
                                                    // Ação para Opção 1

                                                    Navigator.pop(context);
                                                    _navigateToEditProfile();
                                                  },
                                                ),
                                                ListTile(
                                                  leading: Icon(Icons.abc),
                                                  title: Text('Afinador'),
                                                  onTap: () {
                                                    // Ação para Opção 1

                                                    Navigator.pop(context);
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              Afinador()),
                                                    );
                                                  },
                                                ),
                                                ListTile(
                                                  leading: Icon(Icons.logout),
                                                  title: Text('Sair'),
                                                  onTap: () {
                                                    // Ação para Opção 2
                                                    // Usando Provider.of com listen: false para evitar reconstruções desnecessárias
                                                    final authProvider =
                                                        Provider.of<
                                                                AuthProvider>(
                                                            context,
                                                            listen: false);

                                                    // Acessa o authProvider e faz algo com ele
                                                    if (authProvider.userId !=
                                                        null) {
                                                      // Faça algo com authProvider.userId
                                                      authProvider.logout();
                                                    }

                                                    Navigator
                                                        .pushAndRemoveUntil(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              login()),
                                                      (Route<dynamic> route) =>
                                                          false,
                                                    );
                                                  },
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                      Icons.notifications,
                                                      color:
                                                          const Color.fromARGB(
                                                              255,
                                                              248,
                                                              237,
                                                              237)),
                                                  onPressed: () {
                                                    // Lógica para abrir notificações
                                                    // Você pode adicionar a navegação ou exibir um modal, por exemplo
                                                    showModalBottomSheet(
                                                      context: context,
                                                      builder: (context) {
                                                        return Column(
                                                          children: [
                                                            ListTile(
                                                              leading: Icon(Icons
                                                                  .notifications),
                                                              title: Text(
                                                                  'Notificações'),
                                                              onTap: () {
                                                                // Ação para visualizar as notificações
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: StreamBuilder<QuerySnapshot>(
                                        stream: _userProfileStream,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Center(
                                                child:
                                                    CircularProgressIndicator());
                                          } else if (snapshot.hasError) {
                                            return Center(
                                                child: Text(
                                                    'Erro ao carregar perfil'));
                                          } else if (!snapshot.hasData ||
                                              snapshot.data!.docs.isEmpty) {
                                            return Center(
                                                child: Text(
                                                    'Nenhum dado encontrado'));
                                          } else {
                                            // Assumindo que há apenas um documento correspondente
                                            final userData =
                                                snapshot.data!.docs.first.data()
                                                    as Map<String, dynamic>;
                                            final photoUrl =
                                                userData['photoUrl'] ?? '';

                                            return Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 50, // Largura do ícone
                                                  height: 50, // Altura do ícone
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color
                                                            .fromARGB(60, 0, 0,
                                                            0), // Sombra alaranjada com 50% de opacidade
                                                        blurRadius: 15,
                                                        offset: Offset(0,
                                                            10), // Deslocamento da sombra
                                                      ),
                                                    ],
                                                  ),
                                                  child: ProfileAvatar(
                                                      avatarUrl: photoUrl),
                                                ),
                                                /*      CircleAvatar(
                                                    radius: 75,
                                                    backgroundColor:
                                                        Colors.grey[200],
                                                    backgroundImage: photoUrl
                                                            .isNotEmpty
                                                        ? NetworkImage(photoUrl)
                                                        : null,
                                                    child: photoUrl.isEmpty
                                                        ? Icon(
                                                            Icons.camera_alt,
                                                            size: 50,
                                                            color: Colors
                                                                .grey[800],
                                                          )
                                                        : null,
                                                  ),
                                                                                        */
                                                SizedBox(height: 20),
                                                /*  Text(
                                                    'Nome: ${userData['name']}'),*/
                                                SizedBox(height: 20),
                                                /* ElevatedButton(
                                                  onPressed: () async {
                                                    // Navegar para a página de edição e esperar até que a página retorne
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            EditProfilePage(
                                                                userId:
                                                                    widget.id),
                                                      ),
                                                    );
                                                    // Após retornar da página de edição, o StreamBuilder atualizará automaticamente
                                                  },
                                                  child: Text('Edit Profile'),
                                                ),*/
                                              ],
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Stack(
                                      children: [
                                        Container(
                                          height: 40,
                                          child: Icon(Icons.notifications,
                                              color: Colors.black),
                                        ),
                                        if (notificationCount > 0)
                                          Positioned(
                                            right: 0,
                                            top: -0,
                                            child: CircleAvatar(
                                              radius: 8,
                                              backgroundColor: Colors.red,
                                              child: Text(
                                                '$notificationCount',
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    onPressed: () {
                                      // Lógica para abrir notificações
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (context) {
                                          return Column(
                                            children: [
                                              ListTile(
                                                leading:
                                                    Icon(Icons.notifications),
                                                title: Text('Notificações'),
                                                onTap: () {
                                                  // Ação para visualizar as notificações
                                                  Navigator.pop(context);
                                                },
                                              ),
                                              // Lista de notificações
                                              Expanded(
                                                child: ListView(
                                                  children: [
                                                    // Notificação 1
                                                    ListTile(
                                                      leading: Icon(Icons
                                                          .event_available),
                                                      title: Text(
                                                          'Novo evento no culto!'),
                                                      subtitle: Text(
                                                          'Não perca a próxima reunião de louvor.'),
                                                      trailing: Text(
                                                        formatDateTime(DateTime
                                                            .now()), // Formata a data e hora
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey),
                                                      ),
                                                      onTap: () {
                                                        // Ação ao clicar na notificação
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                    // Notificação 2
                                                    ListTile(
                                                      leading:
                                                          Icon(Icons.group_add),
                                                      title: Text(
                                                          'Novo voluntário escalado!'),
                                                      subtitle: Text(
                                                          'Você foi escalado para o culto de amanhã.'),
                                                      trailing: Text(
                                                        formatDateTime(
                                                            DateTime.now().add(
                                                                Duration(
                                                                    days: 1))),
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey),
                                                      ),
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                    // Notificação 3
                                                    ListTile(
                                                      leading:
                                                          Icon(Icons.update),
                                                      title: Text(
                                                          'Atualização no perfil'),
                                                      subtitle: Text(
                                                          'Seu perfil foi atualizado com sucesso.'),
                                                      trailing: Text(
                                                        formatDateTime(
                                                            DateTime.now().add(
                                                                Duration(
                                                                    hours: 1))),
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey),
                                                      ),
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                    // Notificação 4
                                                    ListTile(
                                                      leading:
                                                          Icon(Icons.message),
                                                      title: Text(
                                                          'Nova mensagem recebida'),
                                                      subtitle: Text(
                                                          'Você tem uma mensagem nova no seu perfil.'),
                                                      trailing: Text(
                                                        formatDateTime(
                                                            DateTime.now().add(
                                                                Duration(
                                                                    minutes:
                                                                        30))),
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey),
                                                      ),
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            /*          Padding(
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
                              height: 220,
                              margin: EdgeInsets.only(top: 20),
                              child: FutureBuilder<QuerySnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('Cultos')
                                    .orderBy("date")
                                    .get(),
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

                                  // Obtém todos os documentos
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

                                  // Filtra os cultos onde o user_id do músico logado está no array 'musicos'
                                  final authProvider =
                                      Provider.of<AuthProvider>(context,
                                          listen: false);
                                  int loggedInUserId = authProvider.userid!;

                                  List<DocumentSnapshot> filteredDocs =
                                      weeklyDocs.where((doc) {
                                    Map<String, dynamic> data =
                                        doc.data() as Map<String, dynamic>;
                                    List<dynamic> musicos =
                                        data['musicos'] ?? [];

                                    // Verifica se o user_id do músico logado está no array 'musicos'
                                    return musicos.any((musico) =>
                                        musico['user_id'] == loggedInUserId);
                                  }).toList();

                                  if (filteredDocs.isEmpty) {
                                    return Center(
                                        child: Text(
                                            'Nenhum culto para este músico encontrado.'));
                                  }

                                  // Lista para armazenar todas as músicas de todos os cultos filtrados
                                  List<List<Map<String, dynamic>>>
                                      allMusicDataList = List.generate(
                                          filteredDocs.length, (_) => []);

                                  // Função para carregar as músicas de um culto específico
                                  Future<void> loadMusicsForDocument(
                                      int docIndex) async {
                                    final doc = filteredDocs[docIndex];
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
                                              musicSnapshot.id;

                                          // Adiciona o campo 'bpm', 'letra', 'link_audio', e 'key'
                                          musicData['bpm'] =
                                              musicData['bpm'] ?? 'Unknown';
                                          musicData['letra'] =
                                              musicData['letra'] ?? 'Unknown';
                                          musicData['link_audio'] =
                                              musicData['link_audio'] ??
                                                  'Desconhecido';
                                          musicData[
                                              'key'] = playlist.firstWhere(
                                                  (song) =>
                                                      song['music_document'] ==
                                                      musicSnapshot.id,
                                                  orElse: () => {
                                                        'key':
                                                            'Key Desconhecida'
                                                      })['key'] ??
                                              'Key Desconhecida';

                                          return musicData;
                                        } else {
                                          return {
                                            'Music': 'Música Desconhecida',
                                            'Author': 'Autor Desconhecido',
                                            'key': 'Key Desconhecida',
                                            'link': 'Link não disponível',
                                            'document_id': '',
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
                                        i < filteredDocs.length;
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
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 24.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: List.generate(
                                                filteredDocs.length, (index) {
                                              bool isSelected =
                                                  _selectedIndex == index;
                                              DocumentSnapshot doc =
                                                  filteredDocs[index];
                                              Map<String, dynamic> data =
                                                  doc.data()
                                                      as Map<String, dynamic>;
                                              DateTime cultoDate =
                                                  (data['date'] as Timestamp)
                                                      .toDate();

                                              String horario =
                                                  data['horario'] ?? '';

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
                                                                filteredDocs,
                                                            id: doc.id,
                                                            currentIndex: index,
                                                            musics:
                                                                allMusicDataList,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      margin:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 8.0),
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      decoration: BoxDecoration(
                                                        color: isSelected
                                                            ? Colors.blue
                                                            : Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    0.3),
                                                            spreadRadius: 2,
                                                            blurRadius: 5,
                                                            offset:
                                                                Offset(0, 3),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            DateFormat(
                                                                    'dd MMMM yyyy')
                                                                .format(
                                                                    cultoDate),
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                          Text(
                                                              'Horário: $horario'),
                                                          Text(
                                                              'Instrumento: $instrumentText'),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            }),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            
                    */

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
                                          "NESSA SEMANA",
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        /*
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
                                        ),*/
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              height: 150,
                              width: 500,
                              margin: EdgeInsets.only(bottom: 0),
                              child: FutureBuilder<QuerySnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('Cultos')
                                    .where('date',
                                        isGreaterThanOrEqualTo:
                                            getStartOfWeek())
                                    .where('date',
                                        isLessThanOrEqualTo: getEndOfWeek())
                                    .orderBy('date') // Ordena por data
                                    .get(), // Obtém todos os documentos que estão dentro da semana atual
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

                                  // Filtra os documentos para encontrar aqueles que contêm o user_id específico
                                  List<DocumentSnapshot> filteredDocs =
                                      docs.where((doc) {
                                    final musicos =
                                        (doc['musicos'] as List<dynamic>?) ??
                                            [];
                                    return musicos.any((musico) {
                                      return (musico as Map<String, dynamic>)[
                                              'user_id'] ==
                                          int.parse(widget.id);
                                    });
                                  }).toList();

                                  if (filteredDocs.isEmpty) {
                                    return Center(
                                        child: Text(
                                            'Nenhum culto encontrado para o usuário.'));
                                  }

                                  // Lista para armazenar todas as músicas de todos os cultos
                                  List<List<Map<String, dynamic>>>
                                      allMusicDataList = List.generate(
                                          filteredDocs.length, (_) => []);

                                  // Função para carregar as músicas de um culto específico
                                  Future<void> loadMusicsForDocument(
                                      int docIndex) async {
                                    final doc = filteredDocs[docIndex];
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

                                          // Adiciona o campo 'bpm' se estiver disponível no documento
                                          musicData['bpm'] =
                                              musicData.containsKey('bpm')
                                                  ? musicData['bpm']
                                                  : 'Unkown';
                                          musicData['letra'] =
                                              musicData.containsKey('letra')
                                                  ? musicData['letra']
                                                  : 'Unkown';
                                          musicData['link_audio'] = musicData
                                                  .containsKey('link_audio')
                                              ? musicData['link_audio']
                                              : 'Desconhecido';
                                          musicData['id_musica'] =
                                              musicSnapshot.id;

                                          // Encontra o item correspondente no playlist para adicionar a key e link
                                          var song = playlist.firstWhere(
                                            (song) =>
                                                song['music_document'] ==
                                                musicSnapshot.id,
                                            orElse: () => null,
                                          );

                                          if (song != null) {
                                            musicData['key'] = song['key'] ??
                                                'Key Desconhecida'; // Adiciona o campo key
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
                                            'link': 'Link não disponível',
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
                                        i < filteredDocs.length;
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

                                      return Container(
                                        margin: EdgeInsets.only(bottom: 0),
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          padding: EdgeInsets.zero,
                                          itemCount: filteredDocs.length,
                                          itemBuilder: (context, index) {
                                            Map<String, dynamic> data =
                                                filteredDocs[index].data()
                                                    as Map<String, dynamic>;
                                            String idDocument =
                                                filteredDocs[index].id;

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
                                              future: loadInstrumentForDocument(
                                                  widget.id, idDocument),
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
                                                      instrumentSnapshot.data!;
                                                } else if (instrumentSnapshot
                                                    .hasError) {
                                                  print(
                                                      'Erro ao carregar instrumento: ${instrumentSnapshot.error}');
                                                }

                                                return GestureDetector(
                                                  onTap: () {
                                                    print("O Index");
                                                    print(index);
                                                    Navigator.push(
                                                      context,
                                                      PageRouteBuilder(
                                                        pageBuilder: (context,
                                                                animation,
                                                                secondaryAnimation) =>
                                                            ScheduleDetailsMusician(
                                                          documents:
                                                              filteredDocs,
                                                          id: idDocument,
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
                                                          const curve =
                                                              Curves.easeInOut;

                                                          var tween = Tween(
                                                                  begin: begin,
                                                                  end: end)
                                                              .chain(CurveTween(
                                                                  curve:
                                                                      curve));
                                                          var offsetAnimation =
                                                              animation
                                                                  .drive(tween);

                                                          return SlideTransition(
                                                            position:
                                                                offsetAnimation,
                                                            child: child,
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Container(
                                                      width: 250,
                                                      decoration: BoxDecoration(
                                                          color: Colors.black,
                                                          /*   gradient:
                                                              LinearGradient(
                                                            colors: [
                                                              Color(0xff4c5be3),
                                                              Color(0xff6a51b0)
                                                            ],
                                                            begin: Alignment
                                                                .topLeft, // Início do gradiente
                                                            end: Alignment
                                                                .bottomRight, // Fim do gradiente
                                                          ),*/
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          border: Border.all(
                                                              color:
                                                                  Colors.black,
                                                              width: 1)),
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
                                                                  /*
                                                                  Container(
                                                                    height: 78,
                                                                    width: 72,
                                                                    decoration: BoxDecoration(
                                                                        color: const Color
                                                                            .fromARGB(
                                                                            255,
                                                                            66,
                                                                            0,
                                                                            0),
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
                                                                  ),*/
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
                                                                            style: TextStyle(
                                                                                fontSize: 13,
                                                                                fontWeight: FontWeight.bold,
                                                                                color: Colors.white),
                                                                          ),
                                                                          Text(
                                                                            instrumentText,
                                                                            style: TextStyle(
                                                                                fontSize: 10,
                                                                                fontWeight: FontWeight.normal,
                                                                                color: Colors.white),
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
                                                                                FontWeight.normal,
                                                                            color: Colors.white),
                                                                      ),
                                                                      ElevatedButton
                                                                          .icon(
                                                                        style: ButtonStyle(
                                                                            backgroundColor:
                                                                                WidgetStatePropertyAll(Colors.white),
                                                                            iconColor: WidgetStatePropertyAll(Colors.black)),
                                                                        icon: Icon(
                                                                            Icons.info_outline),
                                                                        onPressed:
                                                                            () =>
                                                                                {},
                                                                        label:
                                                                            Text(
                                                                          "Saiba Mais",
                                                                          style:
                                                                              TextStyle(color: Colors.black),
                                                                        ),
                                                                      )
                                                                    ],
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
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
                                height: 600,
                                margin: EdgeInsets.only(bottom: 100),
                                child: FutureBuilder<QuerySnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('Cultos')
                                      .orderBy(
                                          "date") // Ordena por data se necessário
                                      .get(), // Obtém todos os documentos
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

                                    // Filtra os documentos para encontrar aqueles que contêm o user_id específico
                                    List<DocumentSnapshot> filteredDocs =
                                        docs.where((doc) {
                                      final musicos =
                                          (doc['musicos'] as List<dynamic>?) ??
                                              [];
                                      return musicos.any((musico) {
                                        return (musico as Map<String, dynamic>)[
                                                'user_id'] ==
                                            int.parse(widget.id);
                                      });
                                    }).toList();

                                    if (filteredDocs.isEmpty) {
                                      return Center(
                                          child: Text(
                                              'Nenhum culto encontrado para o usuário.'));
                                    }

                                    // Lista para armazenar todas as músicas de todos os cultos
                                    List<List<Map<String, dynamic>>>
                                        allMusicDataList = List.generate(
                                            filteredDocs.length, (_) => []);

                                    // Função para carregar as músicas de um culto específico
                                    Future<void> loadMusicsForDocument(
                                        int docIndex) async {
                                      final doc = filteredDocs[docIndex];
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

                                            // Adiciona o campo 'bpm' se estiver disponível no documento
                                            musicData['bpm'] =
                                                musicData.containsKey('bpm')
                                                    ? musicData['bpm']
                                                    : ' Unkown';

                                            // Adiciona o campo 'bpm' se estiver disponível no documento
                                            musicData['letra'] =
                                                musicData.containsKey('letra')
                                                    ? musicData['letra']
                                                    : ' Unkown';

                                            musicData['link_audio'] = musicData
                                                    .containsKey('link_audio')
                                                ? musicData['link_audio']
                                                : ' Desconhecido';

                                            musicData['id_musica'] =
                                                musicSnapshot.id;

                                            // Encontra o item correspondente no playlist para adicionar a key e link
                                            var song = playlist.firstWhere(
                                              (song) =>
                                                  song['music_document'] ==
                                                  musicSnapshot.id,
                                              orElse: () => null,
                                            );

                                            print("asdasd" + musicData['bpm']);

                                            if (song != null) {
                                              musicData['key'] = song['key'] ??
                                                  'Key Desconhecida'; // Adiciona o campo key
                                              musicData['link'] = song[
                                                      'link'] ??
                                                  'Link não disponível'; // Adiciona o campo link
                                              musicData['bpm'] = musicData[
                                                      'bpm'] ??
                                                  'Link não disponível'; // Adiciona o campo link

                                              musicData['letra'] = musicData[
                                                      'letra'] ??
                                                  'letra não disponível'; // Adiciona o campo link

                                              musicData[
                                                  'link_audio'] = musicData[
                                                      'link_audio'] ??
                                                  'Link não disponível'; // Adiciona o campo link

                                              musicData[
                                                  'id_musica'] = musicData[
                                                      'id_musica'] ??
                                                  'Nao Encontrado'; // Adiciona o campo link
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
                                          i < filteredDocs.length;
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
                                            itemCount: filteredDocs.length,
                                            itemBuilder: (context, index) {
                                              Map<String, dynamic> data =
                                                  filteredDocs[index].data()
                                                      as Map<String, dynamic>;
                                              String idDocument =
                                                  filteredDocs[index].id;

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
                                                        widget.id, idDocument),
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
                                                      print("O Index");
                                                      print(index);
                                                      Navigator.push(
                                                        context,
                                                        PageRouteBuilder(
                                                          pageBuilder: (context,
                                                                  animation,
                                                                  secondaryAnimation) =>
                                                              ScheduleDetailsMusician(
                                                            documents:
                                                                filteredDocs,
                                                            id: idDocument,
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
                                                    child: Column(
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Container(
                                                            margin:
                                                                EdgeInsets.only(
                                                                    bottom: 12),
                                                            child: Row(
                                                              children: [
                                                                Container(
                                                                  height: 78,
                                                                  width: 72,
                                                                  decoration: BoxDecoration(
                                                                      color: Colors
                                                                          .black,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              12)),
                                                                  margin: EdgeInsets
                                                                      .only(
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
                                                                          MainAxisAlignment
                                                                              .start,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Text(
                                                                          data[
                                                                              'nome'],
                                                                          style: TextStyle(
                                                                              fontSize: 13,
                                                                              fontWeight: FontWeight.bold),
                                                                        ),
                                                                        Text(
                                                                          instrumentText,
                                                                          style: TextStyle(
                                                                              fontSize: 10,
                                                                              fontWeight: FontWeight.bold),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    Text(
                                                                      "Noite, " +
                                                                          DateFormat('MMM d')
                                                                              .format(dataDocumento!),
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
                                                },
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            )
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
              Bibliotecamusical(),
              Afinador(),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BottomNavBar(
                currentIndex: _currentIndex,
                onTap: onNavBarTapped,
              ),
            ),
          ),
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
            alignment: () {
              switch (currentIndex) {
                case 0:
                  return Alignment.centerLeft;
                case 1:
                  return Alignment.center;
                case 2:
                  return Alignment.centerRight;
                default:
                  return Alignment
                      .center; // Valor padrão caso currentIndex não seja 0, 1 ou 2
              }
            }(),
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 46, right: 50.0, bottom: 6.0),
              child: Container(
                width: 30,
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
              BottomNavigationBarItem(
                icon: Icon(Icons.tune),
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

class ProfileAvatar extends StatelessWidget {
  String avatarUrl;

  ProfileAvatar({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == "") {
      avatarUrl =
          "https://icons.veryicon.com/png/o/miscellaneous/standard/avatar-15.png";
    }
    return CircleAvatar(
      radius: 100, // Ajuste o tamanho conforme necessário
      backgroundColor: Colors.grey[200], // Cor de fundo do círculo
      backgroundImage: NetworkImage(avatarUrl),
      child: avatarUrl.isEmpty
          ? CircularProgressIndicator() // Exibe o indicador de carregamento se a URL estiver vazia
          : null,
    );
  }
}

// Função para formatar a data e hora
String formatDateTime(DateTime dateTime) {
  return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
}
