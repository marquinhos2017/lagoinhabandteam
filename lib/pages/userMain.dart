import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/main.dart';
import 'package:lagoinha_music/models/culto.dart';
import 'package:lagoinha_music/pages/GerenciamentoCulto.dart';
import 'package:lagoinha_music/pages/MusicDataBase/main.dart';
import 'package:lagoinha_music/pages/adminCultoForm.dart';
import 'package:lagoinha_music/pages/adminCultoForm2.dart';
import 'package:lagoinha_music/pages/disponibilidade.dart';
import 'package:lagoinha_music/pages/forms_disponibilidade.dart';
import 'package:lagoinha_music/pages/login.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class userMainPage extends StatefulWidget {
  const userMainPage({super.key});

  @override
  State<userMainPage> createState() => _userMainPageState();
}

class _userMainPageState extends State<userMainPage> {
  // StreamSubscription para controlar a inscrição no snapshot do Firestore
  late StreamSubscription<QuerySnapshot> _snapshotSubscription;

  late bool click = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<DocumentSnapshot> _proximosCultos = [];
  bool tem_culto_na_data = false;

  DateTime _selectedDate = DateTime.now();
  Map<String, List<QueryDocumentSnapshot>> _events = {};
  late Stream<QuerySnapshot> _stream;
  bool _showEvents = false; // Estado para controlar a exibição dos eventos
  ScrollController _scrollController =
      ScrollController(); // Controlador de rolagem

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _scrollController.addListener(() {});
    _loadProximosCultos(); // Carregar os próximos cultos ao inicializar o estado

    //_stream = _getProximosCultos();
    print("Pagina Atualizada");
    //  _loadProximosCultos();
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
    });
  }

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    });
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
    DocumentSnapshot? proximoCulto = _findProximoCulto();
    var scaffoldKey = GlobalKey<ScaffoldState>();
    CultosProvider cultosProvider = Provider.of<CultosProvider>(context);
    final TextEditingController dataController = TextEditingController();
    String servicename = '';
    String dataselecionada = "";
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text(
          "Lagoinha Worship Faro",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: Colors.white,
          ),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
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
        backgroundColor: Colors.black,
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              child: Text('Drawer Header'),
            ),
            ListTile(
              title: const Text(
                'Formularios Mensais',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // Update the state of the app.
                // ...
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => forms_disponiblidade()),
                );
              },
            ),
            ListTile(
              title: const Text(
                'Muisc Database',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // Update the state of the app.
                // ...
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MainMusicDataBase()),
                );
              },
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xff171717),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 0),
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
              ),
              Container(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Calendar",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 12, bottom: 24),
                        height: 270,
                        decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius:
                                BorderRadius.all(Radius.circular(24))),
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
                      if (_events.isNotEmpty)
                        Column(
                          children: [
                            if (_buildEventList2().isNotEmpty)
                              ..._buildEventList2(),
                          ],
                        ),
                      proximoCulto != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Próximo Culto:",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 16),
                                Container(
                                  margin: EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Color(0xff010101),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 30.0, vertical: 12),
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
                                              width: 280,
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
                                                                  .circular(24),
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 24.0,
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
                    ],
                  ),
                ),
              ),
              /* if (_proximosCultos.isNotEmpty)
                ..._proximosCultos
                    .map((culto) => _buildEventItem(culto))
                    .toList(),*/
            ],
          ),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: _previousMonth,
          ),
          Text(
            DateFormat.yMMMM().format(_selectedDate),
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_forward,
              color: Colors.white,
            ),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildDaysOfWeek() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final weekDay = DateFormat.E().format(DateTime(2020, 1, index + 6));
          return Container(
            width: 30,
            child: Center(
              child: Text(
                weekDay,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
          height: 180,
          child: GridView.builder(
            padding: EdgeInsets.zero,
            itemCount: daysInMonth + daysBefore,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: 2,
              crossAxisCount: 7,
              mainAxisSpacing:
                  1.0, // Espaçamento vertical mínimo entre as células
              //   crossAxisSpacing:
              //       0.0, // Espaçamento horizontal mínimo entre as células
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
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                "" +
                                                    DateFormat('dd/MMM')
                                                        .format(currentDate),
                                                style: TextStyle(
                                                    color: Colors.white),
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

                      setState(() {
                        //  click = false;
                      });
                    }
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hasEvent ? Color(0xff0A7AFF) : Colors.transparent,
                      border: Border.all(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(day.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
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
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30.0, vertical: 12),
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
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
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
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "" +
                                          DateFormat('dd/MMM')
                                              .format(currentDate),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
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
                                              BorderRadius.circular(8),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
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
                                              BorderRadius.circular(8),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
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
                                              BorderRadius.circular(8),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
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
                                          color: horario == "10:30"
                                              ? Colors.blue
                                              : Colors.black,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            "10:30",
                                            style:
                                                TextStyle(color: Colors.white),
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
                                              BorderRadius.circular(8),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            "19:30",
                                            style:
                                                TextStyle(color: Colors.white),
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
                                              BorderRadius.circular(8),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            "20:30",
                                            style:
                                                TextStyle(color: Colors.white),
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
                          onPressed: () => Navigator.pop(context, 'Cancel'),
                          child: const Text('Cancelar'),
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
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  });
                });
          },
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(25)),
                color: Colors.blue,
                border: Border.all(color: Colors.blue),
              ),
              child: Center(
                child: Text(
                  "+",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
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
