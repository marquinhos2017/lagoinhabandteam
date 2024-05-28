import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/main.dart';
import 'package:lagoinha_music/models/culto.dart';
import 'package:lagoinha_music/models/musician.dart';
import 'package:lagoinha_music/models/musico.dart';
import 'package:lagoinha_music/pages/adminCultoForm.dart';
import 'package:lagoinha_music/pages/userMain.dart';
import 'package:provider/provider.dart';

class MusicianSelect extends StatelessWidget {
  late Culto cultoatual;

  MusicianSelect({required this.cultoatual});

  @override
  Widget build(BuildContext context) {
    CultosProvider cultosProvider = Provider.of<CultosProvider>(context);
    print("Escolhendo Musico: Culto " + cultoatual.nome);

    void addMarcos(int id) {
      cultosProvider.cultos[id].musicos.add(Musician(
          color: "grey",
          instrument: "guitar",
          name: "Marcos Rodrigues",
          password: "08041999",
          tipo: "user"));
    }

    int index = cultosProvider.cultos
        .indexWhere((culto) => culto.nome == cultoatual.nome);
    print("Index: $index");

    /*
    Future<void> adicionarMusico(String nome, String instrumento) async {
      // Criar um novo músico como um mapa
      var novoMusico = {
        'name': nome,
        'instrument': instrumento,
      };

      // Referência para a coleção 'Cultos' no Firestore
      var cultoCollection = FirebaseFirestore.instance.collection('Cultos');

      try {
        // Encontrar o documento do culto pelo nome
        QuerySnapshot querySnapshot = await cultoCollection
            .where('nome', isEqualTo: cultoatual.nome)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Se o documento existe, obter a referência do documento
          var cultoRef = querySnapshot.docs.first.reference;

          // Tentar adicionar o novo músico ao array de músicos
          await cultoRef.update({
            'musicos': FieldValue.arrayUnion([novoMusico])
          });
          print('Músico adicionado com sucesso!');
        } else {
          // Se o documento não existe, criar o documento com o array de músicos
          await cultoCollection.doc().set({
            'nome': cultoatual.nome,
            'musicos': [novoMusico]
          });
          print('Documento criado e músico adicionado com sucesso!');
        }
      } catch (e) {
        print('Erro ao adicionar músico: $e');
      }
    }*/

    return Scaffold(
      backgroundColor: Color(0xff010101),
      body: Container(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Container(
              margin: EdgeInsets.only(top: 60, bottom: 40),
              child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                  )),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              "Worship Team",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              margin: EdgeInsets.only(top: 2),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Color(0xff171717),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('musicos')
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
                                'Nenhum Musico xadastrado',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: snapshot.data!.docs.length,
                            padding: EdgeInsets.zero,
                            itemBuilder: (context, index) {
                              var data = snapshot.data!.docs[index];
                              var musicos = data.data() as Map<String, dynamic>;

                              var cultoId = data.id;

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: GestureDetector(
                                    onTap: () {
                                      print(musicos['name']);

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => adminCultoForm(
                                              cultoatual:
                                                  Culto(nome: musicos['name'])),
                                        ),
                                      );
                                      //Navigator.pushNamed(
                                      //    context, '/adminCultoForm');

                                      //Navigator.pushNamed(
                                      //    context, '/adminCultoForm');
                                    },
                                    child: Container(
                                      child: GestureDetector(
                                        onTap: () => showDialog<String>(
                                          context: context,
                                          builder: (BuildContext context) =>
                                              AlertDialog(
                                            backgroundColor: Color(0xff171717),
                                            title: Text(
                                              "Quer convidar " +
                                                  musicos['name'],
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, 'Cancel'),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  var novoMusico = {
                                                    'name': musicos['name'],
                                                    'instrument':
                                                        musicos['instrument'],
                                                  };

                                                  cultosProvider
                                                      .adicionarMusico(
                                                          cultoatual,
                                                          musicos['name'],
                                                          musicos[
                                                              'instrument']);

                                                  Navigator.of(context).pushAndRemoveUntil(
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              adminCultoForm(
                                                                  cultoatual: Culto(
                                                                      nome: cultoatual
                                                                          .nome))),
                                                      (Route<dynamic> route) =>
                                                          false);
                                                },
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          ),
                                        ),
                                        child: Container(
                                          margin: EdgeInsets.zero,
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 30,
                                                height: 30,
                                                margin:
                                                    EdgeInsets.only(right: 20),
                                                decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25)),
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    child: Text(
                                                      musicos['name'],
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 10),
                                                    ),
                                                  ),
                                                  Container(
                                                    child: Center(
                                                      child: Text(
                                                        musicos['instrument'],
                                                        style: TextStyle(
                                                            color: Color(
                                                                0xff558FFF),
                                                            fontSize: 10),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    )),

                                // Adicione mais campos conforme necessário
                              );
                            },
                          );
                        },
                      ),
                    ),
                    /*      GestureDetector(
                      onTap: () => showDialog<String>(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          backgroundColor: Color(0xff171717),
                          title: const Text(
                            'Enviar solicitação para Lucas ?',
                            style: TextStyle(color: Colors.white),
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'Cancel'),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                cultosProvider.cultos[index].musicos.add(
                                    Musician(
                                        color: "grey",
                                        instrument: "Guitar",
                                        name: "Marcos",
                                        password: "08041999",
                                        tipo: "user"));
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => adminCultoForm(
                                        cultoatual:
                                            Culto(nome: cultoatual.nome)),
                                  ),
                                );
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      ),
                      child: Container(
                        margin: EdgeInsets.only(top: 20),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25)),
                            ),
                            Container(
                              margin: EdgeInsets.only(left: 24),
                              child: Text(
                                "Lucas Almeida",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10),
                              ),
                            ),
                            Container(
                              width: 70,
                              margin: EdgeInsets.only(left: 24),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(
                                    "Guitarra",
                                    style: TextStyle(
                                        color: Color(0xffCCFFD1), fontSize: 10),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => showDialog<String>(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          backgroundColor: Color(0xff171717),
                          title: const Text(
                            'Enviar solicitação para Rafaela ?',
                            style: TextStyle(color: Colors.white),
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'Cancel'),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                cultosProvider.cultos[index].musicos.add(
                                    Musician(
                                        color: "grey",
                                        instrument: "Vocal",
                                        name: "Rafaela",
                                        password: "08041999",
                                        tipo: "user"));
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => adminCultoForm(
                                        cultoatual:
                                            Culto(nome: cultoatual.nome)),
                                  ),
                                );
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      ),
                      child: Container(
                        margin: EdgeInsets.only(top: 20),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25)),
                            ),
                            Container(
                              margin: EdgeInsets.only(left: 24),
                              child: Text(
                                "Rafaela",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10),
                              ),
                            ),
                            Container(
                              width: 70,
                              margin: EdgeInsets.only(left: 24),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(
                                    "Guitarra",
                                    style: TextStyle(
                                        color: Color(0xffCCFFD1), fontSize: 10),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),*/
                  ],
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }
}
