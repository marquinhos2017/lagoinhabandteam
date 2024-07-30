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
  late bool click = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<DocumentSnapshot> _proximosCultos = [];

  DateTime _selectedDate = DateTime.now();
  Map<String, List<QueryDocumentSnapshot>> _events = {};
  late Stream<QuerySnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _loadProximosCultos(); // Carregar os próximos cultos ao inicializar o estado

    //_stream = _getProximosCultos();
    print("Pagina Atualizada");
    //  _loadProximosCultos();
  }

  /*
  void _loadProximosCultos() async {
    DateTime now = DateTime.now();
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Cultos')
        .where('date', isGreaterThanOrEqualTo: now)
        .orderBy('date')
        .get();

    if (mounted) {
      setState(() {
        // Atualiza a lista de cultos após a exclusão
        _proximosCultos = snapshot.docs;
      });
    }

    setState(() {});
  }
  */

  /*

  Stream<QuerySnapshot> _getProximosCultos() {
    DateTime now = DateTime.now();
    return FirebaseFirestore.instance
        .collection('Cultos')
        .where('date', isGreaterThanOrEqualTo: now)
        .orderBy('date')
        .snapshots();
  }

  */

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

  Future<void> _loadEvents() async {
    FirebaseFirestore.instance
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
      setState(() {
        _events = events;
      });
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
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 23),
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
                        height: 420,
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
                      if (_events.isNotEmpty)
                        Container(
                          height: 200,
                          child: _buildEventList(),
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
                                Text(
                                  "Data: ${DateFormat('dd/MM/yyyy').format((proximoCulto['date'] as Timestamp).toDate())}",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Horário: ${proximoCulto['horario']}",
                                  style: TextStyle(fontSize: 16),
                                ),
                                // Outras informações do culto, se necessário
                              ],
                            )
                          : Text(
                              "Nenhum culto futuro encontrado.",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                    ],
                  ),
                ),
              ),
              /*Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Closest Service",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),*/
              if (_proximosCultos.isNotEmpty)
                ..._proximosCultos
                    .map((culto) => _buildEventItem(culto))
                    .toList(),
              /*  Container(
                  height: 200,
                  child: StreamBuilder<QuerySnapshot>(
                      stream: _stream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Text(
                              'Nenhum culto encontrado',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        List<DocumentSnapshot> docs = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            Map<String, dynamic> data =
                                docs[index].data() as Map<String, dynamic>;
                            DateTime cultoDate = (data['date'] as Timestamp)
                                .toDate(); // Converter Timestamp para DateTime
                            print(cultoDate);

                            return Container(
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
                                                  DateFormat('dd/MM/yyyy')
                                                      .format(cultoDate),
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
                                              data['nome'] ??
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
                                                itemCount: (data['playlist']
                                                        as List<dynamic>)
                                                    .length,
                                                itemBuilder: (context, idx) {
                                                  final musicDocumentId =
                                                      data['playlist'][idx]
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
                                    ]));
                          },
                        );
                      }))*/
              Container(
                margin: EdgeInsets.only(top: 16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /*
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: EdgeInsets.only(top: 20, bottom: 0),
                          child: GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => login()),
                                  ),
                              child: Icon(
                                Icons.login,
                                color: Colors.white,
                              )),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 48),
                        child: const Text(
                          "Bem Vindo",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ),*/
/*
                      Container(
                        height: 400,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('Cultos')
                              .orderBy('date')
                              .orderBy('horario')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Text(
                                  'Nenhum culto encontrado',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: snapshot.data!.docs.length,
                              padding: EdgeInsets.zero,
                              itemBuilder: (context, index) {
                                var culto = snapshot.data!.docs[index];
                                String DocRef = culto.id;
                                var cultoData =
                                    culto.data() as Map<String, dynamic>;
                                String cultoNome =
                                    cultoData['nome'] ?? 'Nome não disponível';

                                String cultoDate =
                                    cultoData['date'].toString() ??
                                        'Nome não disponível';

                                DateTime? dataDocumento;
                                try {
                                  dataDocumento = cultoData['date']?.toDate();
                                  print(dataDocumento);
                                } catch (e) {
                                  print('Erro ao converter data: $e');
                                  dataDocumento = null;
                                }
                                // print(culto);

                                return GestureDetector(
                                  onTap: () {
                                    print(cultoData['nome']);

                                    //Navigator.push(
                                    // context,
                                    //MaterialPageRoute(
                                    //builder: (context) => adminCultoForm(
                                    //  cultoatual: Culto(nome: cultoNome)),
                                    //),
                                    //);

                                    //Navigator.pushNamed(
                                    //    context, '/adminCultoForm');

                                    //Navigator.pushNamed(
                                    //    context, '/adminCultoForm');
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                        color: Color(0xff010101),
                                        borderRadius: BorderRadius.circular(0)),
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
                                              Text(
                                                cultoNome,
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14),
                                              ),
                                              dataDocumento != null
                                                  ? Text(
                                                      DateFormat('dd/MM/yyyy')
                                                              .format(
                                                                  dataDocumento!) +
                                                          " às " +
                                                          cultoData['horario'],
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w300,
                                                          fontSize: 10),
                                                    )
                                                  : Text('Data Indisponível'),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: GestureDetector(
                                            onTap: () {
                                              print("ID: " + culto.id);
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

                                // Adicione mais campos conforme necessário
                              },
                            );
                          },
                        ),
                      ),*/
                      /*     SizedBox(
                        height: cultosProvider.cultos.length * 70.0,
                        child: Container(
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.zero,
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: cultosProvider.cultos.length,
                                    itemBuilder: (context, index) {
                                      final culto = cultosProvider.cultos[index];
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: GestureDetector(
                                          onTap: () {
                                            print(culto.nome);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    adminCultoForm(
                                                        cultoatual: Culto(
                                                            nome: culto.nome)),
                                              ),
                                            );
                                            //Navigator.pushNamed(
                                            //    context, '/adminCultoForm');
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                                color: Color(0xff010101),
                                                borderRadius:
                                                    BorderRadius.circular(0)),
                                            width:
                                                MediaQuery.of(context).size.width,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 30.0, vertical: 12),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        culto.nome,
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 14),
                                                      ),
                                                      Text(
                                                        "19:30 - 21:00",
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w300,
                                                            fontSize: 10),
                                                      ),
                                                    ],
                                                  ),
                                                  Column(
                                                    children: [Text("14/abr")],
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),*/
                      /*cultosProvider.cultos.isEmpty
                          ? Text(
                              "Nenhum culto encontrado, adicione um",
                              style: TextStyle(color: Colors.white),
                            )
                          : Text(""),*/
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog<String>(
            context: context,
            builder: (BuildContext context) {
              String horario = "";
              print(horario);
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
                            TextFormField(
                              decoration: const InputDecoration(
                                hintStyle: TextStyle(color: Colors.white),
                                labelStyle: TextStyle(color: Colors.white),
                                labelText: "Service Name",
                                enabledBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white)),
                                border: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white)),
                              ),
                              style: TextStyle(
                                  color: Colors.white), // Cor do texto
                              validator: (String? value) {
                                if (value == null || value.isEmpty) {
                                  return 'Insira o nome do culto';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                servicename = value!;
                              },
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 24),
                              child: TextField(
                                controller: dataController,
                                decoration: const InputDecoration(
                                  hintStyle: TextStyle(color: Colors.white),
                                  labelStyle: TextStyle(color: Colors.white),
                                  labelText: "Data",
                                  enabledBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white)),
                                  border: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white)),
                                ),
                                style: TextStyle(
                                    color: Colors.white), // Cor do texto
                                onTap: () async {
                                  //FocusScope.of(context).requestFocus(new FocusNode());
                                  DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        DateTime(DateTime.now().year, 8, 1),
                                    firstDate: DateTime(
                                        2000), // Define a data inicial para 1 de janeiro de 2000
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    dataController.text =
                                        "${picked.toLocal()}".split(' ')[0];
                                  }
                                },
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      horario = "10:30";
                                    });
                                    print(horario);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: horario == "10:30"
                                          ? Colors.blue
                                          : Colors.grey,
                                      border: Border.all(color: Colors.white),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        "10:30",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      horario = "19:30";
                                    });
                                    print(horario);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: horario == "19:30"
                                          ? Colors.blue
                                          : Colors.grey,
                                      border: Border.all(color: Colors.white),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        "19:30",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      horario = "20:30";
                                    });
                                    print(horario);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: horario == "20:30"
                                          ? Colors.blue
                                          : Colors.grey,
                                      border: Border.all(color: Colors.white),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        "20:30",
                                        style: TextStyle(color: Colors.white),
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
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        // Verifica se o formulário é válido
                        if (_formKey.currentState!.validate()) {
                          // Salva o valor do input
                          _formKey.currentState!.save();

                          Future<String> _addCulto(String name) async {
                            // Converter a String para DateTime
                            DateTime data = DateTime.parse(dataController.text);

                            // Ajustar para UTC+1 (00:00:00 UTC+1)
                            data = DateTime.utc(
                                    data.year, data.month, data.day, 0, 0)
                                .add(Duration(hours: 1));

                            // Converter para Timestamp do Firestore
                            Timestamp timestamp = Timestamp.fromDate(data);

                            // Dados do novo culto
                            Map<String, dynamic> cultoData = {
                              'nome': name,
                              'musicos': [],
                              'playlist': [],
                              'date': timestamp,
                              'horario': horario
                            };

                            // Adicionar o documento na coleção 'cultos'
                            DocumentReference docId = await FirebaseFirestore
                                .instance
                                .collection('Cultos')
                                .add(cultoData);

                            return docId.id;
                          }

                          // Cria um novo culto com o nome inserido
                          /*Culto newCulto = Culto(
                        nome: servicename,
                      );
                
                      // Adiciona o novo culto ao array
                      cultosProvider.adicionarCulto(newCulto);*/

                          String doc = (await _addCulto(servicename));
                          Navigator.of(context).pop(); // Fecha o popup

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => GerenciamentoCulto(
                                      documentId: doc,
                                    )),
                          );

                          // Fecha o diálogo

                          // Navega para a página de formulário de administração de culto
                          //   Navigator.pushNamed(context, '/adminCultoForm');
                        }
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              });
            }),
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        shape: CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteCulto(String id) async {
    await FirebaseFirestore.instance.collection('Cultos').doc(id).delete();
    if (mounted) {
      setState(() {
        _proximosCultos.removeWhere((culto) => culto.id == id);
      });
    }
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
          height: 320,
          child: GridView.builder(
            padding: EdgeInsets.zero,
            itemCount: daysInMonth + daysBefore,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: 1,
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

  Widget _buildEventList() {
    final selectedDateFormatted =
        DateFormat('yyyy-MM-dd').format(_selectedDate);
    final events = _events[selectedDateFormatted] ?? [];

    if (events.isEmpty) {
      return Center(
        child: Text('Nenhum culto encontrado para esta data'),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        var culto = events[index];
        var cultoData = culto.data() as Map<String, dynamic>;
        String cultoNome = cultoData['nome'] ?? 'Nome não disponível';
        String cultoId = culto.id ?? 'Nome não disponível';
        DateTime cultoDate = (cultoData['date'] as Timestamp).toDate();
        String cultoHorario = cultoData['horario'] ?? 'Horário não disponível';

        return GestureDetector(
          onTap: () {
            print('Culto selecionado: $cultoNome');
          },
          child: GestureDetector(
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
                        print("ID: " + culto.id);
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
          ),
        );
      },
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
}

void _deleteCulto(String cultoId) async {
  try {
    await FirebaseFirestore.instance.collection('Cultos').doc(cultoId).delete();
    print('Culto deletado com sucesso');
  } catch (e) {
    print('Erro ao deletar culto: $e');
  }
}
