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
      body: Form(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 16.0),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Navigate the user to the Home page
                        bool exists = cultosProvider.musician.any((musician) =>
                            musician.name == emailController.text);
                        int index = cultosProvider.musician.indexWhere(
                            (musician) =>
                                musician.name == emailController.text);
                        if (index >= 0) {
                          if (passwordController.text ==
                              cultosProvider.musician[index].password) {
                            if (cultosProvider.musician[index].tipo ==
                                "musico") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MusicianPage(
                                          email: emailController.text,
                                        )),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => userMainPage()),
                              );
                            }
                          } else {
                            print("Senha Incorreda");
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Invalid Credentials')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill input')),
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
    );
  }
}
