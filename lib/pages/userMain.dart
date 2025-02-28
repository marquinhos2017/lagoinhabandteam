import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/main.dart';
import 'package:lagoinha_music/models/culto.dart';
import 'package:lagoinha_music/pages/GerenciamentoCulto.dart';
import 'package:lagoinha_music/pages/MusicDataBase/main.dart';
import 'package:lagoinha_music/pages/MusiciansPage.dart';
import 'package:lagoinha_music/pages/adminCultoForm.dart';
import 'package:lagoinha_music/pages/adminCultoForm2.dart';
import 'package:lagoinha_music/pages/disponibilidade.dart';
import 'package:lagoinha_music/pages/forms_disponibilidade.dart';
import 'package:lagoinha_music/pages/login.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BirthdayCalendarPage extends StatefulWidget {
  @override
  _BirthdayCalendarPageState createState() => _BirthdayCalendarPageState();
}

class _BirthdayCalendarPageState extends State<BirthdayCalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<String>> _birthdays = {
    DateTime(DateTime.now().year, 1, 29): ["Vanderson"],
    DateTime(DateTime.now().year, 2, 6): ["Bruna"],
    DateTime(DateTime.now().year, 3, 3): ["Mário"],
    DateTime(DateTime.now().year, 3, 5): ["Matheus"],
    DateTime(DateTime.now().year, 3, 9): ["Jaime"],
    DateTime(DateTime.now().year, 3, 27): ["Nicole"],
    DateTime(DateTime.now().year, 4, 8): ["Marquinhos"],
    DateTime(DateTime.now().year, 4, 15): ["Génesis"],
    DateTime(DateTime.now().year, 4, 21): ["Marcos"],
    DateTime(DateTime.now().year, 8, 29): ["Yego"],
    DateTime(DateTime.now().year, 9, 9): ["Deivid"],
    DateTime(DateTime.now().year, 9, 26): ["Ueliton"],
    DateTime(DateTime.now().year, 9, 27): ["Marina"],
    DateTime(DateTime.now().year, 10, 2): ["Irlana"],
    DateTime(DateTime.now().year, 11, 19): ["Juan"],
    DateTime(DateTime.now().year, 11, 21): ["Amanda"],
  };

  List<String> _getEventsForDay(DateTime day) {
    return _birthdays[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Calendário de Aniversários"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          TableCalendar(
            locale: 'pt_BR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(color: Colors.black),
              weekendTextStyle: TextStyle(color: Colors.black87),
              markerDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(color: Colors.black, fontSize: 18),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                List<String> birthdays = _getEventsForDay(day);
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(color: Colors.black),
                      ),
                      if (birthdays.isNotEmpty)
                        Text(
                          birthdays.join(", "),
                          style: TextStyle(color: Colors.black, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                );
              },
            ),
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ).animate().fade(duration: 600.ms).slideY(begin: -0.2, end: 0),
          SizedBox(height: 20),
          Expanded(
            child: _selectedDay != null &&
                    _getEventsForDay(_selectedDay!).isNotEmpty
                ? ListView.builder(
                    itemCount: _getEventsForDay(_selectedDay!).length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          "🎂 Aniversário de ${_getEventsForDay(_selectedDay!)[index]}",
                          style: TextStyle(color: Colors.black),
                        ),
                        leading: Icon(Icons.cake, color: Colors.black),
                      ).animate().fade(duration: 500.ms).scale();
                    },
                  )
                : Center(
                    child: Text(
                      "Nenhum aniversário neste dia.",
                      style: TextStyle(color: Colors.black87),
                    ).animate().fade(duration: 400.ms),
                  ),
          ),
        ],
      ),
    );
  }
}

class MusicianCountProvider with ChangeNotifier {
  int count = 0;

  void updateCount(int newCount) {
    count = newCount;
    notifyListeners();
  }
}

class userMainPage extends StatefulWidget {
  const userMainPage({super.key});

  @override
  State<userMainPage> createState() => _userMainPageState();
}

class _userMainPageState extends State<userMainPage> {
  // Mapeamento de aniversários
  Map<DateTime, List<String>> _birthdays = {
    DateTime(DateTime.now().year, 1, 29): ["Vanderson"],
    DateTime(DateTime.now().year, 2, 6): ["Bruna"],
    DateTime(DateTime.now().year, 3, 3): ["Mário"],
    DateTime(DateTime.now().year, 3, 5): ["Matheus"],
    DateTime(DateTime.now().year, 3, 9): ["Jaime"],
    DateTime(DateTime.now().year, 3, 27): ["Nicole"],
    DateTime(DateTime.now().year, 4, 8): ["Marquinhos"],
    DateTime(DateTime.now().year, 4, 15): ["Génesis"],
    DateTime(DateTime.now().year, 4, 21): ["Marcos"],
    DateTime(DateTime.now().year, 8, 29): ["Yego"],
    DateTime(DateTime.now().year, 9, 9): ["Deivid"],
    DateTime(DateTime.now().year, 9, 26): ["Ueliton"],
    DateTime(DateTime.now().year, 9, 27): ["Marina"],
    DateTime(DateTime.now().year, 10, 2): ["Irlana"],
    DateTime(DateTime.now().year, 11, 19): ["Juan"],
    DateTime(DateTime.now().year, 11, 21): ["Amanda"],
  };

  // Função para calcular aniversários no período entre hoje e os próximos 14 dias
  List<String> _getUpcomingBirthdays() {
    DateTime today = DateTime.now();
    DateTime twoWeeksFromNow = today.add(Duration(days: 14));

    // Filtra os aniversários dentro do intervalo de hoje e 14 dias à frente
    List<String> upcomingBirthdays = [];

    _birthdays.forEach((date, names) {
      if (date.isAfter(today) && date.isBefore(twoWeeksFromNow)) {
        upcomingBirthdays.addAll(names);
      }
    });

    return upcomingBirthdays;
  }

  // Função para exibir o AlertDialog com os aniversariantes
  void _showBirthdayAlert(List<String> birthdays) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Aniversariantes nos próximos 14 dias"),
          content: Text(birthdays.isNotEmpty
              ? birthdays.join(", ")
              : "Nenhum aniversário nos próximos 14 dias."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Fechar"),
            ),
          ],
        );
      },
    );
  }

  int _musicianCount = 0; // Valor inicial (pode ser 0 ou o valor anterior)
  bool _isLoading = true; // Para saber se estamos carregando ou não

  int _musicsCount = 0; // Valor inicial (pode ser 0 ou o valor anterior)
  final ScrollController _scrollController =
      ScrollController(); // Controlador de rolagem

  Widget _createDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.black,
        size: 24,
      ),
      title: Text(
        text,
        style: TextStyle(color: Colors.black, fontSize: 16),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 24),
      visualDensity: VisualDensity(vertical: -3),
    );
  }

  // StreamSubscription para controlar a inscrição no snapshot do Firestore
  late StreamSubscription<QuerySnapshot> _snapshotSubscription;

  double _scrollPosition = 0.0; // Variável para armazenar a posição do scroll

  late bool click = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<DocumentSnapshot> _proximosCultos = [];
  bool tem_culto_na_data = false;

  DateTime _selectedDate = DateTime.now();
  Map<String, List<QueryDocumentSnapshot>> _events = {};
  late Stream<QuerySnapshot> _stream;
  bool _showEvents = false; // Estado para controlar a exibição dos eventos

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _scrollController.addListener(() {});

    _loadProximosCultos(); // Carregar os próximos cultos ao inicializar o estado

    //_stream = _getProximosCultos();
    print("Pagina Atualizada");
    _fetchMusicianCount(); // Chama a função para carregar o número de músicos uma vez
    //  _loadProximosCultos();
  }

  Future<void> _fetchMusicianCount() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('musicos').get();
    setState(() {
      _musicianCount =
          querySnapshot.docs.length; // Atualiza o número de músicos
    });
  }

  Future<void> _fetchMusicCount() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('music_database').get();
    setState(() {
      _musicsCount = querySnapshot.docs.length; // Atualiza o número de músicos
    });
  }

  Future<void> _loadProximosCultos() async {
    try {
      // Consultar o Firestore para obter os cultos ordenados pela data e horário
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Cultos')
          .orderBy('date')
          .orderBy('horario')
          .get();

      setState(() {
        _proximosCultos = querySnapshot.docs;
      });
    } catch (e) {
      print('Erro ao carregar próximos cultos: $e');
      // Tratamento de erro
    }
  }

  // Encontrar o próximo culto com base na data atual
  DocumentSnapshot? _findProximoCulto() {
    DateTime dataAtual = DateTime.now();

    for (var culto in _proximosCultos) {
      DateTime dataCulto = (culto['date'] as Timestamp).toDate();

      // Comparar a data do culto com a data atual
      if (dataCulto.isAfter(dataAtual)) {
        return culto; // Retornar o primeiro culto que ocorre após a data atual
      }
    }

    return null; // Retornar null se não houver culto futuro encontrado
  }

  @override
  void dispose() {
    // Cancelar a assinatura do snapshot do Firestore para evitar memory leaks
    _snapshotSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    _snapshotSubscription = FirebaseFirestore.instance
        .collection('Cultos')
        .orderBy('date')
        .orderBy('horario')
        .snapshots()
        .listen((snapshot) {
      Map<String, List<QueryDocumentSnapshot>> events = {};
      for (var doc in snapshot.docs) {
        var data = doc.data();
        DateTime date = (data['date'] as Timestamp).toDate();
        String formattedDate = DateFormat('yyyy-MM-dd').format(date);
        if (!events.containsKey(formattedDate)) {
          events[formattedDate] = [];
        }
        events[formattedDate]!.add(doc);
      }
      if (mounted) {
        setState(() {
          _events = events;
        });
      }
      print("Eventos");
      print(_events);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Atualiza a contagem de músicos sempre que a página é reconstruída
    _fetchMusicianCount();
  }

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    });
    // Após atualizar o estado, restaura a posição do scroll
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    });
    // Após atualizar o estado, restaura a posição do scroll
  }

  /*
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream == null) {
      _stream = _getProximosCultos();
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    // Lista de aniversariantes para os próximos 14 dias
    List<String> upcomingBirthdays = _getUpcomingBirthdays();
    DocumentSnapshot? proximoCulto = _findProximoCulto();
    var scaffoldKey = GlobalKey<ScaffoldState>();
    //CultosProvider cultosProvider = Provider.of<CultosProvider>(context);
    final TextEditingController dataController = TextEditingController();
    String servicename = '';
    String dataselecionada = "";
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Lagoinha Music Faro",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: Colors.black,
          ),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          // Ícone de aniversário com a quantidade de aniversariantes próximos
          // Ícone de aniversário com a quantidade de aniversariantes próximos
          GestureDetector(
            onTap: () {
              _showBirthdayAlert(upcomingBirthdays);
            },
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Icon(
                  Icons.cake,
                  size: 24,
                  color: Colors.black,
                ),
                if (upcomingBirthdays.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                      child: Text(
                        "${upcomingBirthdays.length}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          GestureDetector(
              onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => login()),
                  ),
              child: Icon(
                Icons.login,
                color: Colors.white,
              )),
        ],
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Drawer Header
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.white,
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Menu',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Ação para Opção 2
                        // Usando Provider.of com listen: false para evitar reconstruções desnecessárias
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);

                        // Acessa o authProvider e faz algo com ele
                        if (authProvider.userId != null) {
                          // Faça algo com authProvider.userId
                          authProvider.logout();
                        }
                        Navigator.pop(context);

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => login()),
                          (Route<dynamic> route) => false,
                        );
                      },
                      child: Icon(Icons.logout),
                    ),
                  ],
                ),
              ),
            ),
            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _createDrawerItem(
                    icon: Icons.library_add,
                    text: 'Formulários Mensais',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => forms_disponiblidade()),
                      );
                    },
                  ),
                  _createDrawerItem(
                    icon: Icons.person,
                    text: 'Voluntários',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MusiciansPage()),
                      );
                    },
                  ),
                  _createDrawerItem(
                    icon: Icons.music_note,
                    text: 'Banco de Canções',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MainMusicDataBase()),
                      );
                    },
                  ),
                  _createDrawerItem(
                    icon: Icons.music_note,
                    text: 'Calendário de aniversariantes',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => BirthdayCalendarPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Footer
            Container(
              color: Colors.blue,
              child: ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: Colors.white,
                ),
                title: Text(
                  'Sobre',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Handle the 'Sobre' navigation
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            /*
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 170,
                    height: 154,
                    decoration: BoxDecoration(
                      color: Color(0xff0A7AFF),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.zero,
                            child: Text(
                              '18',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.w200,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.zero,
                            child: Container(
                              child: Text(
                                "Voluntarios ",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
            ),*/
            Container(
              child: Padding(
                padding: const EdgeInsets.all(0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    /*      proximoCulto != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Próximo culto",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                              SizedBox(
                                height: 12,
                              ),
            
                              Container(
                                margin: EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Color(0xff010101),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(
                                          1), // Cor da sombra com opacidade
                                      spreadRadius:
                                          2, // Opção para aumentar o tamanho da sombra
                                      blurRadius:
                                          3, // Intensidade do desfoque da sombra
                                      offset: Offset(2,
                                          2), // Deslocamento da sombra (horizontal, vertical)
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0, vertical: 16),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                "${DateFormat('dd/MM/yyyy').format((proximoCulto['date'] as Timestamp).toDate())}",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            proximoCulto['horario'] ??
                                                'Nome do Culto Indisponível',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w300,
                                              fontSize: 12,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Container(
                                            height: 30,
                                            width: 320,
                                            child: ListView.builder(
                                              scrollDirection:
                                                  Axis.horizontal,
                                              itemCount:
                                                  (proximoCulto['playlist']
                                                          as List<dynamic>)
                                                      .length,
                                              itemBuilder: (context, idx) {
                                                final musicDocumentId =
                                                    proximoCulto['playlist']
                                                                [idx]
                                                            ['music_document']
                                                        as String;
            
                                                return FutureBuilder<
                                                    DocumentSnapshot>(
                                                  future: FirebaseFirestore
                                                      .instance
                                                      .collection(
                                                          'music_database')
                                                      .doc(musicDocumentId)
                                                      .get(),
                                                  builder: (context,
                                                      musicSnapshot) {
                                                    if (musicSnapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return Center(
                                                          child:
                                                              CircularProgressIndicator());
                                                    }
            
                                                    if (musicSnapshot
                                                        .hasError) {
                                                      return Text(
                                                          'Erro ao carregar música');
                                                    }
            
                                                    if (!musicSnapshot
                                                            .hasData ||
                                                        !musicSnapshot
                                                            .data!.exists) {
                                                      return Text(
                                                          'Música não encontrada');
                                                    }
            
                                                    final musicData =
                                                        musicSnapshot.data!
                                                                .data()
                                                            as Map<String,
                                                                dynamic>;
                                                    final nomeMusica = musicData[
                                                            'Music'] ??
                                                        'Nome da Música Desconhecido';
            
                                                    return Container(
                                                      margin: EdgeInsets.only(
                                                          right: 8),
                                                      decoration:
                                                          BoxDecoration(
                                                        color:
                                                            Color(0xff0075FF),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(0),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 32.0,
                                                          vertical: 6,
                                                        ),
                                                        child: Text(
                                                          nomeMusica,
                                                          style: TextStyle(
                                                            color:
                                                                Colors.white,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
            
                              /*  Text(
                                "Data: ${DateFormat('dd/MM/yyyy').format((proximoCulto['date'] as Timestamp).toDate())}",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),*/
                              SizedBox(height: 8),
                              Text(
                                "Horário: ${proximoCulto['horario']}",
                                style: TextStyle(fontSize: 16),
                              ),
                              // Outras informações do culto, se necessário
                            ],
                          )
                        : Visibility(
                            visible: false,
                            child: Text(
                              // Aqui mostra caso a tabela de cultos esteja vazia
                              "Nenhum culto futuro encontrado.",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.white),
                            ),
                          ),
                    */
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //   Text("Membros cadastrados"),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Membros ",
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "cadastrados",
                                        style: TextStyle(
                                            fontSize: 10, color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('musicos')
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        // Enquanto estiver esperando os dados, mantenha o valor anterior
                                        return Text(
                                          "$_musicianCount",
                                          style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold),
                                        );
                                      }

                                      if (!snapshot.hasData ||
                                          snapshot.data!.docs.isEmpty) {
                                        // Caso não tenha dados, exibe 0
                                        return Text(
                                          "0",
                                          style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold),
                                        );
                                      }

                                      // Obtém a contagem de músicos e atualiza apenas após a construção da UI
                                      int count = snapshot.data!.docs.length;

                                      // Usar addPostFrameCallback para atualizar o estado após a construção do widget
                                      if (_musicianCount != count) {
                                        WidgetsBinding.instance!
                                            .addPostFrameCallback((_) {
                                          setState(() {
                                            _musicianCount =
                                                count; // Atualiza o valor da contagem
                                          });
                                        });
                                      }

                                      return Text(
                                        "$count",
                                        style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Musicas ",
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "cadastrados",
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.blueAccent),
                                      ),
                                    ],
                                  ),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('music_database')
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        // Enquanto estiver esperando os dados, mantenha o valor anterior
                                        return Text(
                                          "$_musicsCount",
                                          style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold),
                                        );
                                      }

                                      if (!snapshot.hasData ||
                                          snapshot.data!.docs.isEmpty) {
                                        // Caso não tenha dados, exibe 0
                                        return Text(
                                          "0",
                                          style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold),
                                        );
                                      }

                                      // Obtém a contagem de músicos e atualiza apenas após a construção da UI
                                      int count = snapshot.data!.docs.length;

                                      // Usar addPostFrameCallback para atualizar o estado após a construção do widget
                                      if (_musicsCount != count) {
                                        WidgetsBinding.instance!
                                            .addPostFrameCallback((_) {
                                          setState(() {
                                            _musicsCount =
                                                count; // Atualiza o valor da contagem
                                          });
                                        });
                                      }

                                      return Text(
                                        "$count",
                                        style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          /*          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('musicos')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                // Enquanto estiver esperando os dados, mantenha o valor anterior
                                return Text(
                                  "$_musicianCount",
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                // Caso não tenha dados, exibe 0
                                return Text(
                                  "0",
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                );
                              }

                              // Obtém a contagem de músicos e atualiza apenas após a construção da UI
                              int count = snapshot.data!.docs.length;

                              // Usar addPostFrameCallback para atualizar o estado após a construção do widget
                              if (_musicianCount != count) {
                                WidgetsBinding.instance!
                                    .addPostFrameCallback((_) {
                                  setState(() {
                                    _musicianCount =
                                        count; // Atualiza o valor da contagem
                                  });
                                });
                              }

                              return Text(
                                "$count",
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              );
                            },
                          ),
                  */
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Exibe a lista de meses (usando o Listmove)
            Listmove(
              onMonthSelected:
                  _onMonthSelected, // Passa a função de callback para Listmove
              selectedDate: _selectedDate, // Passa o mês selecionado
            ),
            //    _buildMonthSelector(),
            _Calendario(),
            /* if (_proximosCultos.isNotEmpty)
              ..._proximosCultos
                  .map((culto) => _buildEventItem(culto))
                  .toList(),*/
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCulto(String id) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Começa uma nova transação
    return firestore.runTransaction((transaction) async {
      // Obter todos os documentos na coleção user_culto_instruments com o idCulto igual ao cultoId
      final QuerySnapshot userCultoInstrumentsSnapshot = await firestore
          .collection('user_culto_instrument')
          .where('idCulto', isEqualTo: id)
          .get();

      // Deletar cada documento na coleção user_culto_instruments
      for (DocumentSnapshot doc in userCultoInstrumentsSnapshot.docs) {
        transaction.delete(doc.reference);
      }

      // Deletar o documento do culto
      final DocumentReference cultoDocRef =
          firestore.collection('Cultos').doc(id);
      transaction.delete(cultoDocRef);
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Culto removido com sucesso!'),
          backgroundColor: Colors.red, // Cor de aviso de remoção
        ),
      );
      print(
          'Culto com ID $id e todos os documentos associados na coleção user_culto_instruments foram deletados.');
      if (mounted) {
        setState(() {
          _proximosCultos.removeWhere((culto) => culto.id == id);
        });
      }
    }).catchError((error) {
      print('Erro ao deletar culto e documentos associados: $error');
      print('Erro ao deletar culto: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao remover culto. Tente novamente mais tarde.'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

// Função para navegar até o mês selecionado
  void _goToSelectedMonth(DateTime selectedMonth) {
    setState(() {
      _selectedDate = selectedMonth;
    });
  }

  // Função para atualizar o mês ao clicar no mês
  void _onMonthSelected(DateTime monthDate) {
    setState(() {
      _selectedDate = monthDate;
    });
  }

  // Função para construir a linha com os meses do ano
  Widget _buildMonthSelector() {
    List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    // Dividir os meses em duas linhas
    List<List<String>> monthRows = [
      months.sublist(0, 6), // Meses de Jan a Jun
      months.sublist(6), // Meses de Jul a Dez
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: monthRows.map((monthRow) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: monthRow.map((month) {
              int monthIndex = months.indexOf(month);
              DateTime monthDate =
                  DateTime(_selectedDate.year, monthIndex + 1, 1);

              return GestureDetector(
                onTap: () {
                  // Atualiza o mês selecionado
                  _onMonthSelected(monthDate);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: _selectedDate.month == monthIndex + 1
                        ? Colors.blueAccent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      month,
                      style: TextStyle(
                        color: _selectedDate.month == monthIndex + 1
                            ? Colors.white
                            : Colors.black,
                        fontSize: 10,
                        fontWeight: _selectedDate.month == monthIndex + 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
            onPressed: _previousMonth,
          ),
          Text(
            DateFormat.yMMMM().format(_selectedDate),
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_forward,
              color: Colors.black,
            ),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Widget _buildDaysOfWeek() {
    final List<String> weekdays = [];
    for (var i = 0; i < 7; i++) {
      final weekDay = DateFormat.E('pt_BR').format(DateTime(2020, 1, i + 6));
      weekdays.add(capitalize(weekDay));
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          return Container(
            width: 30,
            child: Center(
              child: Text(
                weekdays[index],
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 10),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDays() {
    final firstDayOfMonth =
        DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    final firstWeekdayOfMonth = firstDayOfMonth.weekday;
    final daysBefore = firstWeekdayOfMonth == 1 ? 0 : firstWeekdayOfMonth - 1;
    final totalDays = daysBefore + daysInMonth;
    final daysAfter = (totalDays % 7 == 0) ? 0 : 7 - (totalDays % 7);
    final totalItems = totalDays + daysAfter;

    return Column(
      children: [
        Container(
          height: 250,
          child: GridView.builder(
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: daysInMonth + daysBefore,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: 1.2,
              crossAxisCount: 7,
              mainAxisSpacing:
                  0.0, // Espaçamento vertical mínimo entre as células
              crossAxisSpacing:
                  0.0, // Espaçamento horizontal mínimo entre as células
            ),
            itemBuilder: (context, index) {
              if (index < daysBefore || index >= totalDays + daysBefore) {
                return Container();
              } else {
                final day = index - daysBefore + 1;

                final currentDate =
                    DateTime(_selectedDate.year, _selectedDate.month, day);
                final formattedDate =
                    DateFormat('yyyy-MM-dd').format(currentDate);

                bool hasEvent = _events.containsKey(formattedDate);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = currentDate;
                      //    click = true;
                    });
                    if (hasEvent) {
                      print('Data selecionada: $formattedDate');
                      print('Cultos: ${_events[formattedDate]}');
                    } else {
                      print("Data sem evento");
                      print('Data selecionada: $formattedDate');
                      print('Data formatada: ' +
                          DateFormat('dd-MM-yyyy').format(currentDate));

                      print('Cultos: ${_events[formattedDate]}');

                      DateTime data = DateTime.parse(formattedDate);

                      // Ajustar para UTC+1 (00:00:00 UTC+1)
                      data = DateTime.utc(data.year, data.month, data.day, 0, 0)
                          .add(Duration(hours: 1));

                      // Converter para Timestamp do Firestore
                      Timestamp timestamp = Timestamp.fromDate(_selectedDate);
                      print(timestamp);

                      _loadEvents();

                      // Na funcao abaixo ele abre o form para adiconar um culto, ao clicar em um dia em que nao tem culto

                      /* 
                      showDialog<String>(
                          context: context,
                          builder: (BuildContext context) {
                            String horario = "";
                            String data = "";
                            String servicename = "";
                            String culto = "";
                            print("Horario sem nenhum horairo antes" + horario);
                            return StatefulBuilder(
                                builder: (context, setState) {
                              return AlertDialog(
                                backgroundColor: Color(0xff171717),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 32,
                                    ),
                                    Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          /* TextFormField(
                                            decoration: const InputDecoration(
                                              hintStyle: TextStyle(
                                                  color: Colors.white),
                                              labelStyle: TextStyle(
                                                  color: Colors.white),
                                              labelText: "Culto",
                                              enabledBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.white)),
                                              border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.white)),
                                            ),
                                            style: TextStyle(
                                                color: Colors
                                                    .white), // Cor do texto
                                            validator: (String? value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Insira o nome do culto';
                                              }
                                              return null;
                                            },
                                            onSaved: (value) {
                                              servicename = value!;
                                            },
                                          ),*/
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Selecione o Culto",
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                "" +
                                                    DateFormat('dd/MMM')
                                                        .format(currentDate),
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 12,
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    culto = "Adoração";
                                                  });
                                                  print("Culto1: " + culto);
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: culto == "Adoração"
                                                        ? Colors.blue
                                                        : Colors.black,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      "Adoração",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    culto = "Fé";
                                                  });
                                                  print("culto1: " + culto);
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: culto == "Fé"
                                                        ? Colors.blue
                                                        : Colors.black,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      "Fé",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    culto = "Familia";
                                                  });
                                                  print("culto1: " + culto);
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: culto == "Familia"
                                                        ? Colors.blue
                                                        : Colors.black,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      "Familia",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 18,
                                          ),
                                          Text(
                                            "Selecione o horário",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(
                                            height: 12,
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    horario = "10:30";
                                                  });
                                                  print("Horario1: " + horario);
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: horario == "10:30"
                                                        ? Colors.blue
                                                        : Colors.black,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      "10:30",
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    horario = "19:30";
                                                  });
                                                  print("Horario1: " + horario);
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: horario == "19:30"
                                                        ? Colors.blue
                                                        : Colors.black,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      "19:30",
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    horario = "20:30";
                                                  });
                                                  print("Horario1: " + horario);
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: horario == "20:30"
                                                        ? Colors.blue
                                                        : Colors.black,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      "20:30",
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, 'Cancel'),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      // Verifica se o formulário é válido
                                      if (_formKey.currentState!.validate()) {
                                        // Salva o valor do input
                                        _formKey.currentState!.save();

                                        try {
                                          // Adiciona o culto ao Firestore
                                          DocumentReference docRef =
                                              await FirebaseFirestore.instance
                                                  .collection('Cultos')
                                                  .add({
                                            'nome': culto != "Adoração"
                                                ? "Culto da " + culto
                                                : "Culto de " + culto,
                                            'musicos': [],
                                            'playlist': [],
                                            'date': timestamp,
                                            'horario': horario,
                                          });

                                          // Recarregar os próximos cultos após adicionar um novo culto
                                          await _loadProximosCultos();

                                          // Fecha o diálogo
                                          Navigator.pop(context);

                                          // Navega para a página de detalhes do culto
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    GerenciamentoCulto(
                                                        documentId: docRef.id)),
                                          );
                                          // Exibir uma mensagem de sucesso ou outro feedback ao usuário
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              backgroundColor:
                                                  Color(0xff0A7AFF),
                                              content: Text(
                                                  'Novo culto adicionado com sucesso.'),
                                            ),
                                          );
                                        } catch (e) {
                                          print('Erro ao adicionar culto: $e');
                                        }
                                      }
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            });
                          });

                  */
                      setState(() {
                        //  click = false;
                      });
                    }
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hasEvent ? Color(0xff0A7AFF) : Colors.transparent,
                      border: Border.all(
                          color: _selectedDate.day == day.toInt()
                              ? Colors.blue
                              : Colors.white),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(day.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: hasEvent ? Colors.white : Colors.black,
                          fontSize: 10.0,
                        )),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildEventList() {
    final selectedDateFormatted =
        DateFormat('yyyy-MM-dd').format(_selectedDate);
    final events = _events[selectedDateFormatted] ?? [];

    if (events.isEmpty) {
      return [
        Center(
          child: Text(''),
        ),
      ];
    }

    return events.map((culto) {
      var cultoData = culto.data() as Map<String, dynamic>;
      String cultoNome = cultoData['nome'] ?? 'Nome não disponível';
      String cultoId = culto.id ?? 'Nome não disponível';
      DateTime cultoDate = (cultoData['date'] as Timestamp).toDate();
      String cultoHorario = cultoData['horario'] ?? 'Horário não disponível';

      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => GerenciamentoCulto(
                      documentId: cultoId,
                    )),
          );
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Color(0xff010101),
            borderRadius: BorderRadius.circular(0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30.0, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cultoNome,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(cultoDate) +
                          " às " +
                          cultoHorario,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    _deleteCulto(culto.id);
                  },
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // Cabeçalho do calendário
  Widget _buildHeader2() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: _previousMonth,
          ),
          Text(
            DateFormat.yMMMM().format(_selectedDate),
            style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward, color: Colors.black),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _Calendario2() {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          color: Colors.white),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 12, bottom: 24),
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 4,
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: -4,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(),
                    _buildDaysOfWeek(),
                    _buildDays(),
                  ],
                ),
              ),
            ),
            if (_events.isEmpty)
              Column(
                children: [
                  ..._buildEventList2(),
                ],
              ),
            if (_events.isNotEmpty)
              Column(
                children: [
                  if (_buildEventList2().isNotEmpty) ..._buildEventList2(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _Calendario() {
    return Container(
      //   height: 700,
      // color: Colors.green,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          color: Colors.white),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            /*
                            Text(
                              "Calendário",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),*/
            Container(
              margin: EdgeInsets.only(top: 12, bottom: 24),
              height: 360,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // Sombra mais clara
                    spreadRadius: 4, // Tamanho da propagação
                    blurRadius: 15, // Suavidade da sombra
                    offset: Offset(0, 8), // Deslocamento horizontal e vertical
                  ),
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.05), // Sombra adicional mais sutil
                    spreadRadius: -4,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(),
                    _buildDaysOfWeek(),
                    _buildDays(),
                  ],
                ),
              ),
            ),

            /* ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showEvents =
                                  !_showEvents; // Alternar entre mostrar e ocultar eventos
                            });
                          },
                          child: Text(_showEvents
                              ? 'Ocultar Eventos'
                              : 'Mostrar Eventos'),
                        ),
                        SizedBox(height: 20),
                        // Lista de eventos da data selecionada
                        if (_showEvents) ..._buildEventList(),
                        */
            if (_events.isEmpty)
              Column(
                children: [
                  // Text("Clique em um culto"),
                  ..._buildEventList2(),
                ],
              ),
            if (_events.isNotEmpty)
              Column(
                children: [
                  if (_buildEventList2().isNotEmpty) ..._buildEventList2(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(DocumentSnapshot culto) {
    var data = culto.data() as Map<String, dynamic>;
    DateTime cultoDate = (data['date'] as Timestamp).toDate();
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Color(0xff010101),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM/yyyy').format(cultoDate),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  data['nome'] ?? 'Nome do Culto Indisponível',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  height: 30,
                  width: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: (data['playlist'] as List<dynamic>).length,
                    itemBuilder: (context, idx) {
                      final musicDocumentId =
                          data['playlist'][idx]['music_document'] as String;

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('music_database')
                            .doc(musicDocumentId)
                            .get(),
                        builder: (context, musicSnapshot) {
                          if (musicSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (musicSnapshot.hasError) {
                            return Text('Erro ao carregar música');
                          }

                          if (!musicSnapshot.hasData ||
                              !musicSnapshot.data!.exists) {
                            return Text('Música não encontrada');
                          }

                          final musicData = musicSnapshot.data!.data()
                              as Map<String, dynamic>;
                          final nomeMusica = musicData['Music'] ??
                              'Nome da Música Desconhecido';

                          return Container(
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Color(0xff0075FF),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: 6,
                              ),
                              child: Text(
                                nomeMusica,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEventList2() {
    final selectedDateFormatted =
        DateFormat('yyyy-MM-dd').format(_selectedDate);
    final events = _events[selectedDateFormatted] ?? [];

    // Lista de widgets para os eventos
    List<Widget> eventWidgets = [];

    // Verifica se há eventos na data selecionada
    if (events.isEmpty) {
      // Aqui Mostra caso o array events esteja vazio
      /*   eventWidgets.add(
        Center(
          child: Text(
            'Nenhum culto encontrado para esta data',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );*/

      eventWidgets.add(
        Column(
          children: [
            /* Mostra data clicada
            Text(
              selectedDateFormatted,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),*/
            Container(
              margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Nenhum culto encontrado para esta data',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                showDialog<String>(
                    context: context,
                    builder: (BuildContext context) {
                      String horario = "";
                      String culto = "";
                      DateTime data = _selectedDate;
                      String servicename = "";

                      final currentDate = DateTime(_selectedDate.year,
                          _selectedDate.month, _selectedDate.day);
                      final formattedDate =
                          DateFormat('yyyy-MM-dd').format(currentDate);

                      Timestamp timestamp = Timestamp.fromDate(data);

                      print(horario);
                      print(culto);
                      return StatefulBuilder(builder: (context, setState) {
                        return AlertDialog(
                          title: Text("Adicionar culto"),
                          shadowColor: Colors.black,
                          surfaceTintColor: Colors.black,
                          backgroundColor: Colors.white,
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 0.0),
                                child: Container(
                                  height: 1.0,
                                  width: double.infinity,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(
                                height: 32,
                              ),
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Selecione o Culto",
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          "" +
                                              DateFormat('dd/MMM')
                                                  .format(currentDate),
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              culto = "Adoração";
                                            });
                                            print("Culto1: " + culto);
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                width: 1,
                                                color: culto == "Adoração"
                                                    ? Colors.blue
                                                    : Colors.white,
                                              ),
                                              color: culto == "Adoração"
                                                  ? Colors.white
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(24.0),
                                              child: Center(
                                                child: Text(
                                                  "Adoração",
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 14),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 12,
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              culto = "Fé";
                                            });
                                            print("culto1: " + culto);
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                width: 1,
                                                color: culto == "Fé"
                                                    ? Colors.blue
                                                    : Colors.white,
                                              ),
                                              color: culto == "Fé"
                                                  ? Colors.white
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Center(
                                                child: Text(
                                                  "Fé",
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 12,
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              culto = "Familia";
                                            });
                                            print("culto1: " + culto);
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                width: 1,
                                                color: culto == "Familia"
                                                    ? Colors.blue
                                                    : Colors.white,
                                              ),
                                              color: culto == "Familia"
                                                  ? Colors.white
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Center(
                                                child: Text(
                                                  "Familia",
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 18,
                                    ),
                                    Text(
                                      "Selecione o horário",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              horario = "10:30";
                                            });
                                            print("Horario1: " + horario);
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                width: 2,
                                                color: horario == "10:30"
                                                    ? Color(0xff2266ee)
                                                    : Colors.white,
                                              ),
                                              color: horario == "10:30"
                                                  ? Colors.white
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                "10:30",
                                                style: TextStyle(
                                                  color: horario == "10:30"
                                                      ? Color(0xff2266ee)
                                                      : Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              horario = "19:30";
                                            });
                                            print("Horario1: " + horario);
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                width: 1,
                                                color: horario == "19:30"
                                                    ? Color(0xff2266ee)
                                                    : Colors.white,
                                              ),
                                              color: horario == "19:30"
                                                  ? Colors.white
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                "19:30",
                                                style: TextStyle(
                                                  color: horario == "19:30"
                                                      ? Color(0xff2266ee)
                                                      : Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              horario = "20:30";
                                            });
                                            print("Horario1: " + horario);
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                width: 1,
                                                color: horario == "20:30"
                                                    ? Colors.blue
                                                    : Colors.white,
                                              ),
                                              color: horario == "20:30"
                                                  ? Colors.white
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                "20:30",
                                                style: TextStyle(
                                                  color: horario == "20:30"
                                                      ? Color(0xff2266ee)
                                                      : Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          actions: <Widget>[
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, 'Cancel'),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ButtonStyle(
                                  backgroundColor: WidgetStatePropertyAll(
                                      Color(0xff2266ee))),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                // Verifica se o formulário é válido
                                if (_formKey.currentState!.validate()) {
                                  // Salva o valor do input
                                  _formKey.currentState!.save();

                                  try {
                                    // Adiciona o culto ao Firestore
                                    DocumentReference docRef =
                                        await FirebaseFirestore.instance
                                            .collection('Cultos')
                                            .add({
                                      'nome': culto != "Adoração"
                                          ? "Culto da " + culto
                                          : "Culto de " + culto,
                                      'musicos': [],
                                      'playlist': [],
                                      'date': timestamp,
                                      'horario': horario,
                                    });

                                    // Recarregar os próximos cultos após adicionar um novo culto
                                    await _loadProximosCultos();

                                    // Fecha o diálogo
                                    Navigator.pop(context);

                                    // Navega para a página de detalhes do culto
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              GerenciamentoCulto(
                                                  documentId: docRef.id)),
                                    );
                                    // Exibir uma mensagem de sucesso ou outro feedback ao usuário
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Novo culto adicionado com sucesso.'),
                                      ),
                                    );
                                  } catch (e) {
                                    print('Erro ao adicionar culto: $e');
                                  }
                                }
                              },
                              child: const Text(
                                'OK',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ButtonStyle(
                                  backgroundColor: WidgetStatePropertyAll(
                                      Color(0xff2266ee))),
                            ),
                          ],
                        );
                      });
                    });
              },
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: EdgeInsets.only(top: 16),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "+ Adicionar outro",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Mapeia os eventos para uma lista de widgets
      eventWidgets.addAll(events.map((culto) {
        var cultoData = culto.data() as Map<String, dynamic>;
        String cultoNome = cultoData['nome'] ?? 'Nome não disponível';
        String cultoId = culto.id ?? 'Nome não disponível';
        DateTime cultoDate = (cultoData['date'] as Timestamp).toDate();
        String cultoHorario = cultoData['horario'] ?? 'Horário não disponível';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GerenciamentoCulto(
                  documentId: cultoId,
                ),
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1), // Sombra mais clara
                  spreadRadius: 4, // Tamanho da propagação
                  blurRadius: 15, // Suavidade da sombra
                  offset: Offset(0, 8), // Deslocamento horizontal e vertical
                ),
                BoxShadow(
                  color: Colors.black
                      .withOpacity(0.05), // Sombra adicional mais sutil
                  spreadRadius: -4,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cultoNome,
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        cultoHorario,
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${DateFormat('dd/MM/yyyy').format(cultoDate)}",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () {
                            _deleteCulto(culto.id);
                          },
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList());
    }

    // Adiciona o texto "Adicionar Outro?" se houver eventos
    if (events.isNotEmpty) {
      eventWidgets.add(
        GestureDetector(
          onTap: () {
            showDialog<String>(
                context: context,
                builder: (BuildContext context) {
                  String horario = "";
                  String culto = "";
                  DateTime data = _selectedDate;
                  String servicename = "";

                  final currentDate = DateTime(_selectedDate.year,
                      _selectedDate.month, _selectedDate.day);
                  final formattedDate =
                      DateFormat('yyyy-MM-dd').format(currentDate);

                  Timestamp timestamp = Timestamp.fromDate(data);

                  print(horario);
                  print(culto);
                  return StatefulBuilder(builder: (context, setState) {
                    return AlertDialog(
                      title: Text("Adicionar culto"),
                      shadowColor: Colors.black,
                      surfaceTintColor: Colors.black,
                      backgroundColor: Colors.white,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 0.0),
                            child: Container(
                              height: 1.0,
                              width: double.infinity,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(
                            height: 32,
                          ),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Selecione o Culto",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "" +
                                          DateFormat('dd/MMM')
                                              .format(currentDate),
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 12,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          culto = "Adoração";
                                        });
                                        print("Culto1: " + culto);
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            width: 1,
                                            color: culto == "Adoração"
                                                ? Colors.blue
                                                : Colors.white,
                                          ),
                                          color: culto == "Adoração"
                                              ? Colors.white
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(24.0),
                                          child: Center(
                                            child: Text(
                                              "Adoração",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 14),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          culto = "Fé";
                                        });
                                        print("culto1: " + culto);
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            width: 1,
                                            color: culto == "Fé"
                                                ? Colors.blue
                                                : Colors.white,
                                          ),
                                          color: culto == "Fé"
                                              ? Colors.white
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Center(
                                            child: Text(
                                              "Fé",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          culto = "Familia";
                                        });
                                        print("culto1: " + culto);
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            width: 1,
                                            color: culto == "Familia"
                                                ? Colors.blue
                                                : Colors.white,
                                          ),
                                          color: culto == "Familia"
                                              ? Colors.white
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Center(
                                            child: Text(
                                              "Familia",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 18,
                                ),
                                Text(
                                  "Selecione o horário",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  height: 12,
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          horario = "10:30";
                                        });
                                        print("Horario1: " + horario);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            width: 2,
                                            color: horario == "10:30"
                                                ? Color(0xff2266ee)
                                                : Colors.white,
                                          ),
                                          color: horario == "10:30"
                                              ? Colors.white
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            "10:30",
                                            style: TextStyle(
                                              color: horario == "10:30"
                                                  ? Color(0xff2266ee)
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          horario = "19:30";
                                        });
                                        print("Horario1: " + horario);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            width: 1,
                                            color: horario == "19:30"
                                                ? Color(0xff2266ee)
                                                : Colors.white,
                                          ),
                                          color: horario == "19:30"
                                              ? Colors.white
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            "19:30",
                                            style: TextStyle(
                                              color: horario == "19:30"
                                                  ? Color(0xff2266ee)
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          horario = "20:30";
                                        });
                                        print("Horario1: " + horario);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            width: 1,
                                            color: horario == "20:30"
                                                ? Colors.blue
                                                : Colors.white,
                                          ),
                                          color: horario == "20:30"
                                              ? Colors.white
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            "20:30",
                                            style: TextStyle(
                                              color: horario == "20:30"
                                                  ? Color(0xff2266ee)
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, 'Cancel'),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ButtonStyle(
                              backgroundColor:
                                  WidgetStatePropertyAll(Color(0xff2266ee))),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            // Verifica se o formulário é válido
                            if (_formKey.currentState!.validate()) {
                              // Salva o valor do input
                              _formKey.currentState!.save();

                              try {
                                // Adiciona o culto ao Firestore
                                DocumentReference docRef =
                                    await FirebaseFirestore.instance
                                        .collection('Cultos')
                                        .add({
                                  'nome': culto != "Adoração"
                                      ? "Culto da " + culto
                                      : "Culto de " + culto,
                                  'musicos': [],
                                  'playlist': [],
                                  'date': timestamp,
                                  'horario': horario,
                                });

                                // Recarregar os próximos cultos após adicionar um novo culto
                                await _loadProximosCultos();

                                // Fecha o diálogo
                                Navigator.pop(context);

                                // Navega para a página de detalhes do culto
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => GerenciamentoCulto(
                                          documentId: docRef.id)),
                                );
                                // Exibir uma mensagem de sucesso ou outro feedback ao usuário
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Novo culto adicionado com sucesso.'),
                                  ),
                                );
                              } catch (e) {
                                print('Erro ao adicionar culto: $e');
                              }
                            }
                          },
                          child: const Text(
                            'OK',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ButtonStyle(
                              backgroundColor:
                                  WidgetStatePropertyAll(Color(0xff2266ee))),
                        ),
                      ],
                    );
                  });
                });
          },
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: EdgeInsets.only(top: 16),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  "+ Adicionar outro",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return eventWidgets;
  }
}

void _deleteCulto(String cultoId) async {
  try {
    await FirebaseFirestore.instance.collection('Cultos').doc(cultoId).delete();
    print('Culto deletado com sucesso');
  } catch (e) {
    print('Erro ao deletar culto: $e');
  }
}

void _showMenuBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Container(
        color: Colors.white,
        child: Column(
          children: [
            // Menu Header (similar ao DrawerHeader)
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _createMenuItem(
                    icon: Icons.library_add,
                    text: 'Formulários Mensais',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => forms_disponiblidade()),
                      );
                    },
                  ),
                  _createMenuItem(
                    icon: Icons.person,
                    text: 'Voluntários',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MusiciansPage()),
                      );
                    },
                  ),
                  _createMenuItem(
                    icon: Icons.music_note,
                    text: 'Banco de Canções',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MainMusicDataBase()),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Footer (similar ao Footer do Drawer)
            Container(
              color: Colors.blue,
              child: ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: Colors.white,
                ),
                title: Text(
                  'Sobre',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Handle the 'Sobre' navigation
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

// Método para criar o item do menu
Widget _createMenuItem({
  required IconData icon,
  required String text,
  required GestureTapCallback onTap,
}) {
  return ListTile(
    leading: Icon(icon),
    title: Text(text),
    onTap: onTap,
  );
}

class Listmove extends StatelessWidget {
  final Function(DateTime)
      onMonthSelected; // Callback para comunicação com CalendarPage
  final DateTime selectedDate; // Data atualmente selecionada

  const Listmove({
    super.key,
    required this.onMonthSelected,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        key: const PageStorageKey<String>('monthsScroll'),
        child: Row(
          children: months.map((month) {
            int monthIndex = months.indexOf(month);
            DateTime monthDate = DateTime(selectedDate.year, monthIndex + 1, 1);

            return GestureDetector(
              onTap: () {
                // Passa o mês selecionado para a função de callback
                onMonthSelected(monthDate);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: selectedDate.month == monthIndex + 1
                      ? Colors.blueAccent
                      : Colors.grey.shade300, // Destaque para o mês selecionado
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  month,
                  style: TextStyle(
                    color: selectedDate.month == monthIndex + 1
                        ? Colors.white
                        : Colors.black,
                    fontWeight: selectedDate.month == monthIndex + 1
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
