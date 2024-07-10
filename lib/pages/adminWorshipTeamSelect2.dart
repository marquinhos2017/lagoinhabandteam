import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/main.dart';
import 'package:lagoinha_music/models/culto.dart';
import 'package:lagoinha_music/models/musician.dart';
import 'package:lagoinha_music/models/musico.dart';
import 'package:lagoinha_music/pages/adminCultoForm.dart';
import 'package:lagoinha_music/pages/userMain.dart';
import 'package:provider/provider.dart';

class MusicianSelect2 extends StatefulWidget {
  final String document_id;

  MusicianSelect2({required this.document_id});

  @override
  State<MusicianSelect2> createState() => _MusicianSelect2State();
}

class _MusicianSelect2State extends State<MusicianSelect2> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? date;

  @override
  void initState() {
    super.initState();
    obterDataDocumento(widget.document_id).then((value) {
      setState(() {
        date = value;
      });
    });
  }

  void adicionarMusico(String cultoId, int userId) async {
    try {
      DocumentReference cultoRef = _firestore.collection('Cultos').doc(cultoId);
      DocumentSnapshot cultoDoc = await cultoRef.get();

      if (!cultoDoc.exists) {
        throw Exception('Documento de culto não encontrado');
      }

      await cultoRef.update({
        'musicos': FieldValue.arrayUnion([
          {'user_id': userId}
        ])
      });

      print('Musico adicionado com sucesso');
    } catch (e) {
      print('Erro ao adicionar músico: $e');
    }
  }

  Future<bool> verificaDisponibilidade(String date, String musicoId) async {
    print(musicoId);
    try {
      // Consultar a coleção Form_Voluntario_Culto
      QuerySnapshot querySnapshot = await _firestore
          .collection('Form_Voluntario_Culto')
          .where('musico_id', isEqualTo: musicoId)
          .get();

      print(querySnapshot.docs);

      // Verificar cada documento se a disponibilidade_culto corresponde à data desejada
      for (var doc in querySnapshot.docs) {
        var disponibilidadeCultoId = doc['disponibilidade_culto'];

        DocumentSnapshot formMesCultosDoc = await _firestore
            .collection('Form_Mes_Cultos')
            .doc(disponibilidadeCultoId)
            .get();

        if (formMesCultosDoc.exists) {
          var dataCulto = formMesCultosDoc['data'];

          // Comparar a data do culto com a data desejada
          if (dataCulto == date) {
            return true; // Se encontrou um documento disponível para a data desejada
          }
        }
      }

      return false; // Se nenhum documento foi encontrado para a data desejada
    } catch (e) {
      print('Erro ao verificar disponibilidade: $e');
      return false;
    }
  }

  Future<String?> obterDataDocumento(String documentId) async {
    try {
      DocumentSnapshot documentSnapshot =
          await _firestore.collection('Cultos').doc(documentId).get();

      if (documentSnapshot.exists) {
        return documentSnapshot['date'];
      } else {
        print('Documento não encontrado.');
        return null;
      }
    } catch (e) {
      print('Erro ao buscar documento: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    void adicionarMusico(String cultoId, int userId) async {
      try {
        DocumentReference cultoRef =
            _firestore.collection('Cultos').doc(cultoId);
        DocumentSnapshot cultoDoc = await cultoRef.get();

        if (!cultoDoc.exists) {
          throw Exception('Documento de culto não encontrado');
        }

        await cultoRef.update({
          'musicos': FieldValue.arrayUnion([
            {'user_id': userId}
          ])
        });

        print('Musico adicionado com sucesso');
      } catch (e) {
        print('Erro ao adicionar músico: $e');
      }
    }

    CultosProvider cultosProvider = Provider.of<CultosProvider>(context);

    void addMarcos(int id) {
      cultosProvider.cultos[id].musicos.add(Musician(
          color: "grey",
          instrument: "guitar",
          name: "Marcos Rodrigues",
          password: "08041999",
          tipo: "user"));
    }

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
                      /*
                      date == null
                          ? CircularProgressIndicator()
                          : Text(
                              'Data: $date',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),*/
                      Container(
                        height: MediaQuery.of(context).size.height * 0.6,
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
                                  'Nenhum Musico cadastrado',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: snapshot.data!.docs.length,
                              padding: EdgeInsets.zero,
                              itemBuilder: (context, index) {
                                var data = snapshot.data!.docs[index];
                                var musicos =
                                    data.data() as Map<String, dynamic>;
                                var cultoId = data.id;

                                var musicoId = musicos['user_id'];
                                var nomeMusico = musicos['name'];

                                return FutureBuilder<bool>(
                                  future: verificaDisponibilidade(
                                      date!, musicoId.toString()),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return ListTile(
                                        title: Text(nomeMusico),
                                        subtitle: Text(
                                            'Verificando disponibilidade...'),
                                      );
                                    }

                                    if (snapshot.hasError) {
                                      return ListTile(
                                        title: Text(nomeMusico),
                                        subtitle: Text(
                                            'Erro ao verificar disponibilidade.'),
                                      );
                                    }

                                    bool disponivel = snapshot.data ?? false;

                                    return Container(
                                      padding: EdgeInsets.all(8),
                                      child: GestureDetector(
                                        onTap: () => showDialog<String>(
                                          context: context,
                                          builder: (BuildContext context) =>
                                              disponivel
                                                  ? AlertDialog(
                                                      backgroundColor:
                                                          Color(0xff171717),
                                                      title: Text(
                                                        "Quer convidar " +
                                                            musicos['name'],
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      actions: <Widget>[
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  'Cancel'),
                                                          child: const Text(
                                                              'Cancel'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            adicionarMusico(
                                                                widget
                                                                    .document_id,
                                                                musicoId);
                                                            Navigator.of(
                                                                    context)
                                                                .pop(); // Fecha o popup

                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child:
                                                              const Text('OK'),
                                                        ),
                                                      ],
                                                    )
                                                  : AlertDialog(
                                                      backgroundColor:
                                                          Color(0xff171717),
                                                      title: Text(
                                                        "Ele esta como indisponivel ",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      actions: <Widget>[
                                                        TextButton(
                                                          onPressed: () {
                                                            adicionarMusico(
                                                                widget
                                                                    .document_id,
                                                                musicoId);
                                                            Navigator.of(
                                                                    context)
                                                                .pop(); // Fecha o popup

                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: const Text(
                                                              'Adicionar mesmo assim'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  'Cancel'),
                                                          child: const Text(
                                                              'Voltar'),
                                                        ),
                                                      ],
                                                    ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              nomeMusico,
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            Text(
                                                disponivel
                                                    ? 'Disponível'
                                                    : 'Indisponível',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
