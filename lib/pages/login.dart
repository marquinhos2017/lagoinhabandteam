import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/main.dart';
import 'package:lagoinha_music/models/culto.dart';
import 'package:lagoinha_music/pages/adminCultoForm.dart';
import 'package:lagoinha_music/pages/musicianPage.dart';
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
      appBar: AppBar(
        title: Text("Login"),
      ),
      body: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
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
          ),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(), labelText: "Email"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(), labelText: "Password"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 16.0),
                    child: Center(
                      child: ElevatedButton(
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
                                        builder: (context) =>
                                            MusicianPage(id: musicianDoc.id)),
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
                                  content:
                                      Text('Por favor, preencha os campos')),
                            );
                          }
                        },
                        child: const Text('Submit'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}