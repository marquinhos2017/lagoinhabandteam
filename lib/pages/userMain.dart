import 'package:flutter/material.dart';
import 'package:lagoinha_music/main.dart';
import 'package:lagoinha_music/models/culto.dart';
import 'package:lagoinha_music/pages/adminCultoForm.dart';
import 'package:lagoinha_music/pages/login.dart';
import 'package:provider/provider.dart';

class userMainPage extends StatefulWidget {
  const userMainPage({super.key});

  @override
  State<userMainPage> createState() => _userMainPageState();
}

class _userMainPageState extends State<userMainPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    CultosProvider cultosProvider = Provider.of<CultosProvider>(context);
    String servicename = '';
    return Scaffold(
      backgroundColor: const Color(0xff171717),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: 150),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
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
                    Container(
                      margin: EdgeInsets.only(top: 2),
                      child: const Text(
                        "Boa noite Ju, seja bem vinda",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
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
                    SizedBox(
                      height: cultosProvider.cultos.length * 60.0,
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
                    ),
                    cultosProvider.cultos.isEmpty
                        ? Text(
                            "Nenhum culto encontrado, adicione um",
                            style: TextStyle(color: Colors.white),
                          )
                        : Text(""),
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
          builder: (BuildContext context) => AlertDialog(
            backgroundColor: Color(0xff171717),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 20),
                  child: const Text(
                    'Qual o nome do culto ?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold),
                  ),
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
                              borderSide: BorderSide(color: Colors.white)),
                          border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white)),
                        ),
                        style: TextStyle(color: Colors.white), // Cor do texto
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          servicename = value!;
                        },
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
                onPressed: () {
                  // Verifica se o formulário é válido
                  if (_formKey.currentState!.validate()) {
                    // Salva o valor do input
                    _formKey.currentState!.save();

                    // Cria um novo culto com o nome inserido
                    Culto newCulto = Culto(
                      nome: servicename,
                    );

                    // Adiciona o novo culto ao array
                    cultosProvider.adicionarCulto(newCulto);

                    // Fecha o diálogo
                    Navigator.pop(context);

                    // Navega para a página de formulário de administração de culto
                    //   Navigator.pushNamed(context, '/adminCultoForm');
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
        ),
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        shape: CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
