import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/main.dart';
import 'package:lagoinha_music/models/culto.dart';
import 'package:lagoinha_music/pages/adminCultoForm.dart';
import 'package:lagoinha_music/pages/MusicianPage/musicianPage%20copy.dart';

import 'package:lagoinha_music/pages/userMain.dart';
import 'package:provider/provider.dart';

class login extends StatefulWidget {
  const login({super.key});

  @override
  State<login> createState() => _LoginStateState();
}

class _LoginStateState extends State<login> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController();

  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    CultosProvider cultosProvider = Provider.of<CultosProvider>(context);
    int index = cultosProvider.musician
        .indexWhere((musician) => musician.name == "Marcos Rodrigues");
    bool exists = cultosProvider.musician
        .any((musician) => musician.name == "Marcos Rodrigues");
    print(exists);
    print(index);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "",
          style: TextStyle(color: Colors.white),
        ),
        foregroundColor: Colors.black,
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /*     StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Cultos').where(
                  'musicos',
                  arrayContains: {'name': 'Marcos'}).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
        
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('Não há cultos com Marcos'),
                  );
                }
        
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var cultoDoc = snapshot.data!.docs[index];
                    var cultoData = cultoDoc.data() as Map<String, dynamic>;
                    var cultoName = cultoData['nome'] ?? '';
        
                    return ListTile(
                      title: Text(cultoName),
                      // Adicione mais campos conforme necessário
                    );
                  },
                );
              },
            ),*/
            /*
            Container(
              height: 200,
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('Cultos').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
        
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text('Nenhum culto encontrado'),
                    );
                  }
        
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var culto = snapshot.data!.docs[index];
                      var cultoData = culto.data() as Map<String, dynamic>;
        
                      return ListTile(
                        title: Text(cultoData['nome'] ?? ''),
                        subtitle: Text(
                            'Data: ${cultoData['data']}'), // Substitua 'data' pelo campo correto
                        // Adicione mais campos conforme necessário
                      );
                    },
                  );
                },
              ),
            ),*/
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            height: 70,
                            child: Text(
                              "LM",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 64,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w200,
                              ),
                            ),
                          ),
                          Text(
                            "faro",
                            style: TextStyle(
                                letterSpacing: 14,
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 40),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 16),
                          child: TextFormField(
                            style: TextStyle(color: Colors.white),
                            controller: emailController,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.white), // Borda branca
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                  borderSide: BorderSide(
                                      color: Colors
                                          .white), // Borda branca quando o campo está habilitado
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                  borderSide: BorderSide(
                                      color: Colors
                                          .white), // Borda branca quando o campo está focado
                                ),
                                labelText: "Usuario",
                                labelStyle: TextStyle(color: Colors.white)),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor insira seu usuario';
                              }
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 16),
                          child: TextFormField(
                            style: TextStyle(color: Colors.white),
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.white), // Borda branca
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                  borderSide: BorderSide(
                                      color: Colors
                                          .white), // Borda branca quando o campo está habilitado
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                  borderSide: BorderSide(
                                      color: Colors
                                          .white), // Borda branca quando o campo está focado
                                ),
                                labelText: "Senha",
                                labelStyle: TextStyle(color: Colors.white)),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 16.0),
                    child: Container(
                      height: 48,
                      width: 400,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black26,
                              offset: Offset(0, 4),
                              blurRadius: 5.0)
                        ],
                        /*
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: [0.0, 1.0],
                          colors: [
                            Color(0xff41AA5C),
                            Color(0xff558FFF),
                          ],
                        ),*/
                        color: Color(0xff4465D9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ElevatedButton(
                        style: ButtonStyle(
                          foregroundColor:
                              WidgetStateProperty.all(Colors.white),
                          backgroundColor:
                              WidgetStateProperty.all(Colors.transparent),
                          // elevation: MaterialStateProperty.all(3),
                          shadowColor:
                              WidgetStateProperty.all(Colors.transparent),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // Verifica se o e-mail está presente no banco de dados
                            QuerySnapshot querySnapshot =
                                await FirebaseFirestore.instance
                                    .collection('musicos')
                                    .where('name',
                                        isEqualTo: emailController.text)
                                    .get();

                            if (querySnapshot.docs.isNotEmpty) {
                              // E-mail encontrado
                              // Verifica se a senha está correta
                              DocumentSnapshot musicianDoc =
                                  querySnapshot.docs[0];
                              Map<String, dynamic> musicianData =
                                  musicianDoc.data() as Map<String, dynamic>;
                              if (musicianData['password'] ==
                                  passwordController.text) {
                                // Senha correta
                                // Navegue para a página correta com base no tipo de usuário
                                String musicianType = musicianData['tipo'];
                                if (musicianType == 'user') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => MusicianPageCopy(
                                            id: musicianData['user_id']
                                                .toString())),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => userMainPage()),
                                  );
                                }
                              } else {
                                // Senha incorreta
                                print('Senha incorreta');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Senha incorreta')),
                                );
                              }
                            } else {
                              // E-mail não encontrado
                              print('Usuario não encontrado');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('E-mail não encontrado')),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  backgroundColor: Colors.red,
                                  content:
                                      Text('Por favor, preencha os campos')),
                            );
                          }
                        },
                        child: const Text('Sign In'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
