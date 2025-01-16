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
//import 'package:flutter_audio_capture/flutter_audio_capture.dart';
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

  // Função para buscar cultos da semana com base em userId
  Future<void> fetchCultos(int userId) async {
    try {
      // Determinar o início e o fim da semana
      DateTime startOfWeek = getStartOfWeek();
      DateTime endOfWeek = getEndOfWeek();

      // Formatar as datas para Timestamp
      Timestamp startTimestamp = Timestamp.fromDate(startOfWeek);
      Timestamp endTimestamp = Timestamp.fromDate(endOfWeek);

      // Buscar documentos em 'user_culto_instrument' para o userId
      var userCultoSnapshot = await FirebaseFirestore.instance
          .collection('user_culto_instrument')
          .where('idUser', isEqualTo: userId)
          .get();

      // Coletar os IDs dos cultos onde o usuário está escalado
      List<String> idCultos = userCultoSnapshot.docs
          .map((doc) => doc['idCulto'] as String)
          .toList();

      if (idCultos.isEmpty) {
        setState(() {
          cultosDaSemana = [];
        });
        return; // Não há cultos associados a este usuário
      }

      // Buscar os cultos dentro do intervalo de datas
      var querySnapshot = await FirebaseFirestore.instance
          .collection('Cultos')
          .where('date', isGreaterThanOrEqualTo: startTimestamp)
          .where('date', isLessThanOrEqualTo: endTimestamp)
          .get();

      // Filtrar os cultos que correspondem aos IDs encontrados
      List<QueryDocumentSnapshot> filteredCultos =
          querySnapshot.docs.where((doc) => idCultos.contains(doc.id)).toList();

      // Atualizar o estado com os cultos encontrados
      setState(() {
        cultosDaSemana = filteredCultos;
      });

      print("Cultos da semana:");
      print(cultosDaSemana);
    } catch (e) {
      print("Erro ao buscar cultos da semana: $e");
    }
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

  int cultosSemanaCount = 0;

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
    contarCultosSemanaDoUsuario();
  }

  Future<void> contarCultosSemanaDoUsuario() async {
    try {
      // Obtém todos os cultos em que o usuário está escalado
      var userCultoSnapshot = await FirebaseFirestore.instance
          .collection('user_culto_instrument')
          .where('idUser',
              isEqualTo: int.parse(widget.id)) // Filtra pelo idUser
          .get();

      if (userCultoSnapshot.docs.isEmpty) {
        setState(() {
          cultosSemanaCount = 0; // Nenhum culto escalado
        });
        return;
      }

      // Converte os documentos para uma lista
      List<DocumentSnapshot> userCultosDocs = userCultoSnapshot.docs;

      // Busca os cultos na coleção 'Cultos'
      List<Future<Map<String, dynamic>>> cultosFutures =
          userCultosDocs.map((userCultoDoc) async {
        final cultoId = userCultoDoc['idCulto'];
        DocumentSnapshot cultoDoc = await FirebaseFirestore.instance
            .collection('Cultos')
            .doc(cultoId)
            .get();

        Map<String, dynamic> cultoData =
            cultoDoc.data() as Map<String, dynamic>;
        cultoData['date'] = (cultoData['date'] as Timestamp).toDate();
        return cultoData;
      }).toList();

      // Aguarda todos os cultos serem carregados
      List<Map<String, dynamic>> cultos = await Future.wait(cultosFutures);

      // Define o intervalo da semana atual
      DateTime startOfWeek = getStartOfWeek();
      DateTime endOfWeek = getEndOfWeek();

      // Filtra os cultos que estão dentro da semana atual
      int countsemana = cultos.where((cultoData) {
        DateTime cultoDate = cultoData['date'];
        return cultoDate.isAfter(startOfWeek) && cultoDate.isBefore(endOfWeek);
      }).length;

      // Atualiza o estado com a contagem
      setState(() {
        cultosSemanaCount = countsemana;
      });
      print("asdasd");

      // print("Total de cultos escalados na semana: $count");
    } catch (e) {
      print('Erro ao contar cultos da semana: $e');
    }
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
      // Verifica se o widget.id é numérico antes de converter para int
      int? userId = int.tryParse(widget.id);
      if (userId == null) {
        setState(() {
          errorMessage = 'ID de usuário inválido.';
          isLoading = false;
        });
        return;
      }

      // Busca o documento do músico no Firestore onde o campo usr_id é igual ao userId
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('musicos')
          .where('user_id', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Tratamento de erro caso nenhum documento seja encontrado
        setState(() {
          errorMessage = 'Nenhum músico com user_id $userId foi encontrado.';
          isLoading = false;
        });
      } else {
        // Extrai os campos "name" e "photoUrl" do primeiro documento encontrado
        setState(() {
          musicianName = querySnapshot.docs.first['name'];
          avatar = querySnapshot.docs.first['photoUrl'] ??
              ''; // Usando um valor padrão caso 'photoUrl' seja nulo
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
      // Faz a consulta na coleção 'user_culto_instrument'
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('user_culto_instrument')
          .where('idUser', isEqualTo: int.parse(userID))
          .get();

      // Itera sobre os documentos encontrados
      for (var doc in querySnapshot.docs) {
        // Aqui você pode acessar os dados de cada documento
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('ID do documento: ${doc.id}');
        print('Dados do documento: $data');
        print("documentos");
        print(doc);
      }
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
      // Obtém todos os cultos em que o usuário está escalado através da coleção 'user_culto_instrument'
      var userCultoSnapshot = await FirebaseFirestore.instance
          .collection('user_culto_instrument')
          .where('idUser',
              isEqualTo: int.parse(widget.id)) // A busca é pelo idUser
          .get();

      // A quantidade de cultos é igual ao número de documentos encontrados
      int count = userCultoSnapshot.docs.length;

      setState(() {
        cultosCount = count; // Armazena a contagem de cultos
      });

      print("Total de cultos do usuário: $count");
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

  Widget buildTagBasedOnTime(String horario) {
    // Converter o horário para um DateTime
    final timeParts = horario.split(':');
    if (timeParts.length < 2) {
      return Text(
        'Horário inválido',
        style: TextStyle(color: Colors.red),
      );
    }

    int hour = int.parse(timeParts[0]);

    // Verificar o intervalo do horário e retornar o widget correspondente
    if (hour >= 7 && hour < 12) {
      return Row(
        children: [
          Icon(
            Icons.wb_sunny, // Ícone de "Manhã"
            color: Colors.orange,
            size: 14,
          ),
          SizedBox(width: 8),
          Text(
            "Manhã",
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else if (hour >= 18 && hour <= 24) {
      return Row(
        children: [
          Icon(
            Icons.nights_stay, // Ícone de "Noite"
            color: Colors.blue,
            size: 14,
          ),
          SizedBox(width: 8),
          Text(
            "Noite",
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else {
      return Text(
        'Horário fora dos intervalos',
        style: TextStyle(color: Colors.grey),
      );
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
      appBar: AppBar(
          centerTitle: true,
          surfaceTintColor: Colors.black,
          foregroundColor: Colors.black,
          shadowColor: Colors.black,
          backgroundColor: Colors.white,
          toolbarHeight: 100,
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ],
                ),
                IconButton(
                  icon: Stack(
                    children: [
                      Container(
                        height: 40,
                        child: Icon(Icons.notifications, color: Colors.black),
                      ),
                      if (notificationCount > 0)
                        Positioned(
                          right: 0,
                          top: 00,
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
                              leading: Icon(Icons.notifications),
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
                                    leading: Icon(Icons.event_available),
                                    title: Text('Novo evento no culto!'),
                                    subtitle: Text(
                                        'Não perca a próxima reunião de louvor.'),
                                    trailing: Text(
                                      formatDateTime(DateTime
                                          .now()), // Formata a data e hora
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                    onTap: () {
                                      // Ação ao clicar na notificação
                                      Navigator.pop(context);
                                    },
                                  ),
                                  // Notificação 2
                                  ListTile(
                                    leading: Icon(Icons.group_add),
                                    title: Text('Novo voluntário escalado!'),
                                    subtitle: Text(
                                        'Você foi escalado para o culto de amanhã.'),
                                    trailing: Text(
                                      formatDateTime(DateTime.now()
                                          .add(Duration(days: 1))),
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                  // Notificação 3
                                  ListTile(
                                    leading: Icon(Icons.update),
                                    title: Text('Atualização no perfil'),
                                    subtitle: Text(
                                        'Seu perfil foi atualizado com sucesso.'),
                                    trailing: Text(
                                      formatDateTime(DateTime.now()
                                          .add(Duration(hours: 1))),
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                  // Notificação 4
                                  ListTile(
                                    leading: Icon(Icons.message),
                                    title: Text('Nova mensagem recebida'),
                                    subtitle: Text(
                                        'Você tem uma mensagem nova no seu perfil.'),
                                    trailing: Text(
                                      formatDateTime(DateTime.now()
                                          .add(Duration(minutes: 30))),
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
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
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled:
                          true, // Permite ajustar a altura do BottomSheet
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(
                                20)), // Bordas arredondadas no topo
                      ),
                      builder: (context) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 16),
                          child: Wrap(
                            // Ajusta a altura automaticamente ao conteúdo
                            children: <Widget>[
                              ListTile(
                                leading: Icon(Icons.abc),
                                title: Text('Editar Perfil'),
                                onTap: () {
                                  // Ação para editar perfil
                                  Navigator.pop(context);
                                  _navigateToEditProfile();
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.logout),
                                title: Text('Sair'),
                                onTap: () {
                                  // Ação para logout
                                  final authProvider =
                                      Provider.of<AuthProvider>(context,
                                          listen: false);

                                  if (authProvider.userId != null) {
                                    authProvider.logout();
                                  }

                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => login()),
                                    (Route<dynamic> route) => false,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _userProfileStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Erro ao carregar perfil'));
                      } else if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('Nenhum dado encontrado'));
                      } else {
                        final userData = snapshot.data!.docs.first.data()
                            as Map<String, dynamic>;
                        final photoUrl = userData['photoUrl'] ?? '';

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(60, 0, 0, 0),
                                    blurRadius: 5,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ProfileAvatar(avatarUrl: photoUrl),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          )),
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
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
                                        SizedBox(
                                          width: 12,
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
                                              cultosSemanaCount.toString(),
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
                            Container(
                              height: 215,
                              margin: EdgeInsets.only(bottom: 0),
                              child: FutureBuilder<QuerySnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection(
                                        'user_culto_instrument') // Coleção onde está o relacionamento entre usuários e cultos
                                    .where('idUser',
                                        isEqualTo: int.parse(widget
                                            .id)) // Filtra pelo userId do músico
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
                                        child: Text(
                                            'Nenhum culto escalado encontrado.'));
                                  }

                                  List<DocumentSnapshot> userCultosDocs =
                                      snapshot.data!.docs;

                                  // Agora vamos buscar os cultos na coleção 'Cultos' que correspondem aos cultos escalados
                                  List<Future<Map<String, dynamic>>>
                                      cultosFutures =
                                      userCultosDocs.map((userCultoDoc) async {
                                    final cultoId = userCultoDoc[
                                        'idCulto']; // Supondo que o campo idCulto está armazenado no documento
                                    final instrumento =
                                        userCultoDoc['Instrument'] ??
                                            'Instrumento não definido';

                                    DocumentSnapshot cultoDoc =
                                        await FirebaseFirestore.instance
                                            .collection('Cultos')
                                            .doc(cultoId)
                                            .get();

                                    Map<String, dynamic> cultoData =
                                        cultoDoc.data() as Map<String, dynamic>;
                                    cultoData['instrumento'] =
                                        instrumento; // Adiciona o instrumento ao culto
                                    cultoData['idCulto'] = cultoId;
                                    return cultoData;
                                  }).toList();

                                  return FutureBuilder<
                                      List<Map<String, dynamic>>>(
                                    future: Future.wait(cultosFutures),
                                    builder: (context, cultosSnapshot) {
                                      if (cultosSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      }

                                      if (cultosSnapshot.hasError) {
                                        return Center(
                                            child: Text(
                                                'Erro ao carregar os cultos.'));
                                      }

                                      if (!cultosSnapshot.hasData ||
                                          cultosSnapshot.data!.isEmpty) {
                                        return Center(
                                            child: Text(
                                                'Nenhum culto encontrado para o usuário.'));
                                      }

                                      // Agora você tem todos os cultos escalados para o usuário com informações adicionais
                                      List<Map<String, dynamic>> cultos =
                                          cultosSnapshot.data!;

                                      // Filtra os cultos para exibir apenas os da semana atual
                                      DateTime startOfWeek = getStartOfWeek();
                                      DateTime endOfWeek = getEndOfWeek();

                                      List<Map<String, dynamic>>
                                          filteredCultos =
                                          cultos.where((cultoData) {
                                        DateTime cultoDate =
                                            (cultoData['date'] as Timestamp)
                                                .toDate();
                                        return cultoDate.isAfter(startOfWeek) &&
                                            cultoDate.isBefore(endOfWeek);
                                      }).toList();

                                      if (filteredCultos.isEmpty) {
                                        return Center(
                                            child: Text(
                                                'Nenhum culto escalado esta semana.'));
                                      }

                                      return ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: filteredCultos.length,
                                        itemBuilder: (context, index) {
                                          Map<String, dynamic> cultoData =
                                              filteredCultos[index];
                                          String cultoName =
                                              cultoData['nome'] ??
                                                  'Culto sem nome';
                                          DateTime cultoDate =
                                              (cultoData['date'] as Timestamp)
                                                  .toDate();
                                          String horario =
                                              cultoData['horario'] ??
                                                  'Horário não definido';
                                          String instrument =
                                              cultoData['instrumento'];

                                          String idCulto = cultoData['idCulto'];

                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ScheduleDetailsMusician(
                                                    id: idCulto,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color:
                                                          Colors.grey.shade300,
                                                      spreadRadius: 3,
                                                      blurRadius: 5,
                                                      offset: Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                height: 240,
                                                width: 300,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                      24.0),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Container(
                                                                width: 40,
                                                                height: 40,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  image:
                                                                      DecorationImage(
                                                                    image:
                                                                        NetworkImage(
                                                                      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQiomxFAA1cgas1K_PPfGc-4pkW1sLUc3Anog&s",
                                                                    ),
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 16),
                                                              Row(
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Text(
                                                                        cultoDate.day.toString() +
                                                                            "/",
                                                                        style:
                                                                            TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          color: const Color
                                                                              .fromARGB(
                                                                              255,
                                                                              135,
                                                                              135,
                                                                              135),
                                                                          fontSize:
                                                                              12,
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        cultoDate
                                                                            .month
                                                                            .toString(),
                                                                        style:
                                                                            TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          color: const Color
                                                                              .fromARGB(
                                                                              255,
                                                                              135,
                                                                              135,
                                                                              135),
                                                                          fontSize:
                                                                              12,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  Text(
                                                                    " as " +
                                                                        horario,
                                                                    style:
                                                                        TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: const Color
                                                                          .fromARGB(
                                                                          255,
                                                                          135,
                                                                          135,
                                                                          135),
                                                                      fontSize:
                                                                          12,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                          Row(
                                                            children: [
                                                              buildTagBasedOnTime(
                                                                  horario),
                                                              SizedBox(
                                                                  width: 8),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                          height: 16),
                                                      Text(
                                                        cultoName,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Color(0xffebf4fe),
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      8.0,
                                                                  vertical: 2),
                                                          child: Text(
                                                            instrument,
                                                            style: TextStyle(
                                                                fontSize: 14,
                                                                color: Colors
                                                                    .grey
                                                                    .shade700,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                        ),
                                                      ),
                                                      Align(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child: Container(
                                                          height: 30,
                                                          child: ElevatedButton(
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor:
                                                                  Colors.black,
                                                            ),
                                                            onPressed: () => {},
                                                            child: Text(
                                                              "Clique aqui",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 12),
                                                            ),
                                                          ),
                                                        ),
                                                      )
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
                              ),
                            ),
                            SizedBox(
                              height: 12,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0, vertical: 24),
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
                            Container(
                              margin: EdgeInsets.only(bottom: 0),
                              child: FutureBuilder<QuerySnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection(
                                        'user_culto_instrument') // Coleção onde está o relacionamento entre usuários e cultos
                                    .where('idUser',
                                        isEqualTo: int.parse(widget
                                            .id)) // Filtra pelo userId do músico
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
                                        child: Text(
                                            'Nenhum culto escalado encontrado.'));
                                  }

                                  List<DocumentSnapshot> userCultosDocs =
                                      snapshot.data!.docs;

                                  // Buscar cultos e incluir informações de instrumento
                                  List<Future<Map<String, dynamic>>>
                                      cultosFutures =
                                      userCultosDocs.map((userCultoDoc) async {
                                    final cultoId = userCultoDoc['idCulto'];
                                    final instrument =
                                        userCultoDoc['Instrument'];

                                    // Buscar o culto correspondente
                                    final cultoDoc = await FirebaseFirestore
                                        .instance
                                        .collection('Cultos')
                                        .doc(cultoId)
                                        .get();

                                    return {
                                      'culto': cultoDoc.data(),
                                      'instrument': instrument,
                                      'cultoId': cultoId,
                                    };
                                  }).toList();

                                  return FutureBuilder<
                                      List<Map<String, dynamic>>>(
                                    future: Future.wait(cultosFutures),
                                    builder: (context, cultosSnapshot) {
                                      if (cultosSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      }

                                      if (cultosSnapshot.hasError) {
                                        return Center(
                                            child: Text(
                                                'Erro ao carregar os cultos.'));
                                      }

                                      if (!cultosSnapshot.hasData ||
                                          cultosSnapshot.data!.isEmpty) {
                                        return Center(
                                            child: Text(
                                                'Nenhum culto encontrado para o usuário.'));
                                      }

                                      // Lista de cultos com instrumentos
                                      List<Map<String, dynamic>>
                                          cultosComInstrumentos =
                                          cultosSnapshot.data!;

                                      final today = DateTime.now();
                                      final normalizedToday = DateTime(
                                          today.year, today.month, today.day);
                                      final cultosFuturos =
                                          cultosComInstrumentos
                                              .where((cultoItem) {
                                        final cultoData = cultoItem['culto'];
                                        if (cultoData != null &&
                                            cultoData['date'] is Timestamp) {
                                          DateTime cultoDate =
                                              (cultoData['date'] as Timestamp)
                                                  .toDate();
                                          final normalizedCultoDate = DateTime(
                                              cultoDate.year,
                                              cultoDate.month,
                                              cultoDate.day);
                                          return normalizedCultoDate
                                                  .isAtSameMomentAs(
                                                      normalizedToday) ||
                                              normalizedCultoDate
                                                  .isAfter(normalizedToday);
                                        }
                                        return false;
                                      }).toList();

                                      if (cultosFuturos.isEmpty) {
                                        return Center(
                                            child: Text(
                                                'Nenhum culto futuro encontrado.'));
                                      }

                                      return Column(
                                        children:
                                            cultosFuturos.map((cultoItem) {
                                          final cultoData = cultoItem['culto'];
                                          final instrument =
                                              cultoItem['instrument'];
                                          final cultoId = cultoItem['cultoId'];

                                          String cultoName =
                                              cultoData?['nome'] ??
                                                  'Culto sem nome';
                                          DateTime cultoDate =
                                              (cultoData?['date'] as Timestamp)
                                                  .toDate();
                                          String horario =
                                              cultoData?['horario'] ?? '';

                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ScheduleDetailsMusician(
                                                    id: cultoId,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color:
                                                          Colors.grey.shade300,
                                                      spreadRadius: 3,
                                                      blurRadius: 5,
                                                      offset: Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                width: double.infinity,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                      12.0),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Text(
                                                                "${cultoDate.day}/${cultoDate.month}",
                                                                style:
                                                                    TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: const Color
                                                                      .fromARGB(
                                                                      255,
                                                                      135,
                                                                      135,
                                                                      135),
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 24),
                                                              Text(
                                                                horario,
                                                                style:
                                                                    TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: const Color
                                                                      .fromARGB(
                                                                      255,
                                                                      135,
                                                                      135,
                                                                      135),
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          buildTagBasedOnTime(
                                                              horario),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        cultoName,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Color(0xffebf4fe),
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      8.0,
                                                                  vertical: 2),
                                                          child: Text(
                                                            instrument,
                                                            style: TextStyle(
                                                                fontSize: 14,
                                                                color: Colors
                                                                    .grey
                                                                    .shade700,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
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
              //  Afinador(),
            ],
          ),
          /*
          Align(
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
