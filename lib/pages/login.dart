import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/main.dart';
import 'package:lagoinha_music/models/culto.dart';
import 'package:lagoinha_music/pages/MusicianPage/Cultos.dart';
import 'package:lagoinha_music/pages/MusicianPage/musicianPageNewUI.dart';
import 'package:lagoinha_music/pages/adminCultoForm.dart';
import 'package:lagoinha_music/pages/MusicianPage/musicianPage%20copy.dart';

import 'package:lagoinha_music/pages/userMain.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

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
  void initState() {
    super.initState();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    // Checa se há um usuário salvo nas preferências
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    String? userType = prefs.getString('tipo');

    if (userId != null && userType != null) {
      // Redireciona para a página correta com base no tipo de usuário
      if (userType == 'user') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MusicianPageNewUI(
              id: userId,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => userMainPage(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      /*
      appBar: AppBar(
        title: const Text(
          "",
          style: TextStyle(color: Colors.white),
        ),
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
      ),*/
      body: Column(
        children: [
          Container(
            //     color: Colors.yellow,
            height: 200,
            child: Center(
              child: Container(
                width: 200,
                child: Image.asset(
                  "assets/logo.png", // URL da imagem
                  //  fit: BoxFit.cover, // Ajusta a imagem para cobrir o container
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.only(topLeft: Radius.circular(80))),
              height: 500,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Login",
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 24),
                    ),
                    Center(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Container(
                              margin: EdgeInsets.only(),
                              child: Column(
                                children: [
                                  /*
                                  Container(
                                    height: 70,
                                    child: const Text(
                                      "LM",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 64,
                                        fontStyle: FontStyle.normal,
                                        fontWeight: FontWeight.w200,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    "faro",
                                    style: TextStyle(
                                        letterSpacing: 14,
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),*/
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(80)),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 40),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 16),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color.fromARGB(
                                                  255, 40, 38, 38),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color.fromARGB(
                                                      19, 36, 6, 6),
                                                  spreadRadius: 2,
                                                  blurRadius: 15,
                                                  offset: Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: TextFormField(
                                              style: const TextStyle(
                                                  color: Colors.black),
                                              controller: emailController,
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                filled: true,
                                                fillColor: Colors
                                                    .white, // Cor de fundo do campo
                                                hintText:
                                                    'Digite seu texto aqui', // Exemplo de texto de dica
                                                //  border: OutlineInputBorder(
                                                //    borderSide: BorderSide(color: Colors.black),
                                                //       ),
                                                //     enabledBorder: OutlineInputBorder(

                                                //    borderRadius:
                                                //          BorderRadius.all(Radius.circular(20)),
                                                // borderSide: BorderSide(color: Colors.black),
                                                //           ),
                                                //      focusedBorder: OutlineInputBorder(
                                                //     borderRadius:
                                                //      BorderRadius.all(Radius.circular(20)),
                                                //    borderSide: BorderSide(color: Colors.black),
                                                //      ),
                                                labelText: "Usuário",
                                                labelStyle: TextStyle(
                                                    color: Colors.black),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Por favor insira seu usuario';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 16),
                                          child: TextFormField(
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 18),
                                            controller: passwordController,
                                            obscureText: true,
                                            obscuringCharacter:
                                                '*', // defaults to *

                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              filled: true,
                                              fillColor: Colors
                                                  .white, // Cor de fundo do campo
                                              hintText:
                                                  'Digite seu texto aqui', // Exemplo de texto de dica
                                              //  border: OutlineInputBorder(
                                              //    borderSide: BorderSide(color: Colors.black),
                                              //       ),
                                              //     enabledBorder: OutlineInputBorder(

                                              //    borderRadius:
                                              //          BorderRadius.all(Radius.circular(20)),
                                              // borderSide: BorderSide(color: Colors.black),
                                              //           ),
                                              //      focusedBorder: OutlineInputBorder(
                                              //     borderRadius:
                                              //      BorderRadius.all(Radius.circular(20)),
                                              //    borderSide: BorderSide(color: Colors.black),
                                              //      ),
                                              labelText: "Senha",
                                              labelStyle: TextStyle(
                                                  color: Colors.black),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
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
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: ElevatedButton(
                                        style: ButtonStyle(
                                          foregroundColor:
                                              MaterialStateProperty.all(
                                                  Colors.white),
                                          backgroundColor:
                                              MaterialStateProperty.all(
                                                  Colors.transparent),
                                        ),
                                        onPressed: () async {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            QuerySnapshot querySnapshot =
                                                await FirebaseFirestore.instance
                                                    .collection('musicos')
                                                    .where('name',
                                                        isEqualTo:
                                                            emailController
                                                                .text)
                                                    .get();

                                            if (querySnapshot.docs.isNotEmpty) {
                                              DocumentSnapshot musicianDoc =
                                                  querySnapshot.docs[0];
                                              Map<String, dynamic>
                                                  musicianData =
                                                  musicianDoc.data()
                                                      as Map<String, dynamic>;

                                              if (musicianData['password'] ==
                                                  passwordController.text) {
                                                // Salva o user_id no AuthProvider
                                                Provider.of<AuthProvider>(
                                                        context,
                                                        listen: false)
                                                    .login(
                                                        musicianData['user_id']
                                                            .toString());

                                                String musicianType =
                                                    musicianData['tipo'];
                                                if (musicianType == 'user') {
                                                  Navigator.pushAndRemoveUntil(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          MusicianPageNewUI(
                                                        id: musicianData[
                                                                'user_id']
                                                            .toString(),
                                                      ),
                                                    ),
                                                    (Route<dynamic> route) =>
                                                        false,
                                                  );
                                                } else {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            userMainPage()),
                                                  );
                                                }
                                              } else {
                                                // Senha incorreta
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Senha incorreta')),
                                                );
                                              }
                                            } else {
                                              // Usuario não encontrado
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Usuario não encontrado')),
                                              );
                                            }
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  backgroundColor: Colors.red,
                                                  content: Text(
                                                      'Por favor, preencha os campos')),
                                            );
                                          }
                                        },
                                        child: const Text('Entrar'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
