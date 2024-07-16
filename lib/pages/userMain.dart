import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/main.dart';
import 'package:lagoinha_music/models/culto.dart';
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
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
          ],
        ),
      ),
      backgroundColor: const Color(0xff171717),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    Container(
                      margin: EdgeInsets.only(top: 30, bottom: 20),
                      child: Text(
                        "Cultos",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
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

                              String cultoDate = cultoData['date'].toString() ??
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

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => adminCultoForm2(
                                              document_id: DocRef,
                                            )),
                                  );

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
                    ),
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
                                builder: (context) => adminCultoForm2(
                                      document_id: doc,
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
}

void _deleteCulto(String cultoId) async {
  try {
    await FirebaseFirestore.instance.collection('Cultos').doc(cultoId).delete();
    print('Culto deletado com sucesso');
  } catch (e) {
    print('Erro ao deletar culto: $e');
  }
}
