import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/main.dart';
import 'package:lagoinha_music/models/culto.dart';
import 'package:lagoinha_music/pages/adminCultoForm.dart';
import 'package:lagoinha_music/pages/login.dart';
import 'package:provider/provider.dart';

class Disponibilidade extends StatefulWidget {
  const Disponibilidade({super.key});

  @override
  State<Disponibilidade> createState() => _DisponibilidadeState();
}

class Cultoss {
  String nome;
  String data;
  String horario;

  Cultoss({required this.nome, required this.data, required this.horario});
}

class _DisponibilidadeState extends State<Disponibilidade> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<Cultoss> cultosss = [
    Cultoss(nome: 'Culto Fé', data: '24/04', horario: '10:00'),
    Cultoss(nome: 'Culto Batismo', data: '24/04', horario: '15:00'),
    Cultoss(nome: 'Culto Adoracao', data: '25/04', horario: '10:30'),
    Cultoss(nome: 'Culto Batismo', data: '26/04', horario: '19:00'),
  ];
  List<bool> checked = [false, false, false, false];

  @override
  Widget build(BuildContext context) {
    CultosProvider cultosProvider = Provider.of<CultosProvider>(context);
    String servicename = '';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "LWF",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
      backgroundColor: const Color(0xff171717),
      body: SingleChildScrollView(
        child: Container(
          child: Padding(
            padding: const EdgeInsets.all(59.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 16),
                        child: Text(
                          "Selecione os cultos que você esteja disponivel em Agosto",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 20),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        height: 600,
                        child: ListView.builder(
                          itemCount: cultosss.length,
                          itemBuilder: (context, index) {
                            return CheckboxListTile(
                              title: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                        color: checked[index]
                                            ? Colors.blue
                                            : Colors.white,
                                        width: 1)),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Container(
                                      width: 100,
                                      child: Text(
                                        cultosss[index].nome,
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 14),
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          cultosss[index].horario,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10),
                                        ),
                                        Text(
                                          cultosss[index].data,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              value: checked[index],
                              onChanged: (bool? value) {
                                setState(() {
                                  checked[index] = value!;
                                });
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
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog<String>(
            context: context,
            builder: (BuildContext context) {
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
                                  borderSide: BorderSide(color: Colors.white)),
                              border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white)),
                            ),
                            style:
                                TextStyle(color: Colors.white), // Cor do texto
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
                    onPressed: () async {
                      // Verifica se o formulário é válido
                      if (_formKey.currentState!.validate()) {
                        // Salva o valor do input
                        _formKey.currentState!.save();

                        Future<void> _addCulto(String name) async {
                          // Dados do novo culto
                          Map<String, dynamic> cultoData = {
                            'nome': name,
                            'musicos': [],
                          };

                          // Adicionar o documento na coleção 'cultos'
                          await FirebaseFirestore.instance
                              .collection('Cultos')
                              .add(cultoData);
                        }

                        // Cria um novo culto com o nome inserido
                        /*Culto newCulto = Culto(
                      nome: servicename,
                    );

                    // Adiciona o novo culto ao array
                    cultosProvider.adicionarCulto(newCulto);*/

                        await _addCulto(servicename);
                        Navigator.of(context).pop(); // Fecha o popup

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => adminCultoForm(
                                cultoatual: Culto(nome: servicename)),
                          ),
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

Row _build_Item(String culto, String data, String horario) {
  return Row(
    children: [
      Container(
        padding: EdgeInsets.fromLTRB(22, 8, 22, 8),
        decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: Colors.white, width: 1),
            borderRadius: BorderRadius.circular(25)),
        child: Row(
          children: [
            Container(
              width: 40,
              margin: EdgeInsets.only(right: 52),
              child: Text(
                "$culto",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: Colors.white,
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 12),
                      child: Text(
                        "$data",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: Colors.white,
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 12),
                      child: Text(
                        "$horario",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    ],
  );
}
