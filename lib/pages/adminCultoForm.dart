import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/firestoreservice.dart';
import 'package:lagoinha_music/main.dart';
import 'package:lagoinha_music/models/culto.dart';
import 'package:lagoinha_music/models/musician.dart';
import 'package:lagoinha_music/models/musico.dart';
import 'package:lagoinha_music/pages/adminWorshipTeamSelect.dart';
import 'package:lagoinha_music/pages/login.dart';
import 'package:lagoinha_music/pages/userMain.dart';
import 'package:provider/provider.dart';

class adminCultoForm extends StatelessWidget {
  late Culto cultoatual;

  adminCultoForm({required this.cultoatual});

  @override
  Widget build(BuildContext context) {
    CultosProvider cultosProvider = Provider.of<CultosProvider>(context);
    print("Nome do culto: " + cultoatual.nome);

    Future<String?> findDocumentId(
        String collectionPath, String fieldName, String value) async {
      try {
        // Consulta para encontrar documentos com o campo 'fieldName' igual a 'value'
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection(collectionPath)
            .where(fieldName, isEqualTo: value)
            .limit(1) // Limite para 1 documento (espera-se que haja apenas um)
            .get();

        // Verifica se a consulta retornou algum documento
        if (querySnapshot.docs.isNotEmpty) {
          // Retorna o ID do primeiro documento encontrado
          return querySnapshot.docs.first.id;
        } else {
          // Retorna null se nenhum documento for encontrado
          return null;
        }
      } catch (e) {
        // Trata qualquer erro que possa ocorrer durante a consulta
        print('Erro ao buscar documento: $e');
        return null;
      }
    }

    /*Future<String> Encontrar() async {
      String? documentId =
          await findDocumentId('Cultos', 'nome', 'Culto Batismo');
      if (documentId != null) {
        return documentId;
      } else {
        // Lidar com o caso em que o documento não foi encontrado, se necessário
        // Por exemplo, você pode lançar uma exceção ou retornar uma string vazia
        throw Exception(
            'O documento com o nome "Culto Batismo" não foi encontrado.');
      }
    }

    Encontrar();
    */

    /*int index = cultosProvider.cultos
        .indexWhere((culto) => culto.nome == cultoatual.nome);
    print(index);

    Culto cultoEspecifico = cultosProvider.cultos[index];
    String nomes = "";
    print("Culto: " + cultoEspecifico.nome);
    for (Musician musico in cultoEspecifico.musicos) {
      //print(musico.nome);
      if (nomes.isEmpty) {
        nomes = nomes + musico.name;
      } else {
        nomes = nomes + ", " + musico.name;
      }

      print(
          nomes); // Supondo que 'nome' seja o atributo que você deseja imprimir
    }
    */

    //print(cultosProvider.cultos.toString());
    return Scaffold(
      backgroundColor: Color(0xff010101),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(top: 60),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /*Text(
                  "Culto: " + cultoatual.nome,
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  "Musicos: " + nomes,
                  style: TextStyle(color: Colors.white),
                ),*/
                Container(
                  margin: EdgeInsets.only(top: 20, bottom: 0),
                  child: GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => userMainPage()),
                          ),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      )),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      child: Text(
                        "${cultosProvider.cultos}",
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(bottom: 20),
                      child: Text(
                        "", //cultoEspecifico.nome//,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
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
                              margin: EdgeInsets.only(bottom: 20),
                              child: Text(
                                "Team",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(
                              height: 200,
                              child: Container(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        child: StreamBuilder<QuerySnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection('Cultos')
                                              .where('nome',
                                                  isEqualTo: cultoatual.nome)
                                              .snapshots(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            }

                                            if (!snapshot.hasData ||
                                                snapshot.data!.docs.isEmpty) {
                                              return Center(
                                                child: Text(
                                                    'Culto de Batismo não encontrado'),
                                              );
                                            }

                                            var cultoDoc =
                                                snapshot.data!.docs.first;
                                            var cultoData = cultoDoc.data()
                                                as Map<String, dynamic>;

                                            print("Documento do Culto: " +
                                                cultoDoc.id);
                                            print("Musicos Escalados: " +
                                                (cultoData['musicos']
                                                    .toString()));

                                            // Verifica se o campo 'musicos' está presente e não é nulo
                                            if (cultoData
                                                    .containsKey('musicos') &&
                                                cultoData['musicos'] != null) {
                                              var musicos = cultoData['musicos']
                                                  as List<dynamic>;

                                              return ListView.builder(
                                                itemCount: musicos.length,
                                                itemBuilder: (context, index) {
                                                  var musicoData = musicos[
                                                          index]
                                                      as Map<String, dynamic>;
                                                  return ListTile(
                                                    title: Text(
                                                      musicoData['name'] ?? '',
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                    subtitle: Text(musicoData[
                                                            'instrument'] ??
                                                        ''),
                                                    // Adicione mais campos conforme necessário
                                                  );
                                                },
                                              );
                                            } else {
                                              return Center(
                                                child: Text(
                                                    'Não há músicos neste culto de Batismo'),
                                              );
                                            }
                                          },
                                        ),

                                        /* child: ListView.builder(
                                          padding: EdgeInsets.zero,
                                          itemCount:
                                              cultoEspecifico.musicos.length,
                                          itemBuilder: (context, index) {
                                            final musico =
                                                cultoEspecifico.musicos;
                                            return ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              title: GestureDetector(
                                                onTap: () {
                                                  //Navigator.pushNamed(
                                                  //    context, '/adminCultoForm');
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.zero,
                                                  height: 150,
                                                  child: ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    itemCount: cultoEspecifico
                                                        .musicos.length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      final musico =
                                                          cultoEspecifico
                                                              .musicos[index];
                                                      return Column(
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Text(
                                                                musico.name,
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        10,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Container(
                                                                    margin: EdgeInsets.only(
                                                                        right:
                                                                            20),
                                                                    child: Text(
                                                                      musico
                                                                          .instrument,
                                                                      style: TextStyle(
                                                                          color: Color(
                                                                              0xff558FFF),
                                                                          fontSize:
                                                                              8),
                                                                    ),
                                                                  ),
                                                                  Icon(
                                                                    Icons
                                                                        .keyboard,
                                                                    color: Colors
                                                                        .white,
                                                                  )
                                                                ],
                                                              )
                                                            ],
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),*/
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Center(
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MusicianSelect(
                                        cultoatual: Culto(
                                            nome: cultoatual
                                                .nome)), //cultoEspecifico.nome//)),
                                  ),
                                ),
                                child: Container(
                                  width: 100,
                                  margin: EdgeInsets.only(top: 24, bottom: 0),
                                  decoration: BoxDecoration(
                                      color: Color(0xff4465D9),
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Center(
                                      child: Text(
                                        "ADD MUSICIAN",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 24),
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
                              child: Text(
                                "Playlist",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              child: Column(children: [
                                Container(
                                  margin: EdgeInsets.only(top: 12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Name",
                                          style: TextStyle(
                                              color: Colors.white, fontSize: 8),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "Singer",
                                          style: TextStyle(
                                              color: Colors.white, fontSize: 8),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "Tone",
                                          style: TextStyle(
                                              color: Colors.white, fontSize: 8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(top: 12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Tu es",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "FHOP",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "C",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(top: 12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Pra Sempre",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "Kari Jobe",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "F",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ]),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                  context, '/AddtoPlaylist'),
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                margin: EdgeInsets.only(top: 24, bottom: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Color(0xff4465D9),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(0.0),
                                  child: Center(
                                    child: Text(
                                      "+",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 24),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 24),
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  margin: EdgeInsets.only(top: 24),
                                  decoration:
                                      BoxDecoration(color: Color(0xff171717)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 8),
                                    child: Text(
                                      "DATE",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.4,
                                    margin: EdgeInsets.only(top: 24, left: 16),
                                    decoration:
                                        BoxDecoration(color: Color(0xff171717)),
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          "14/ABR",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  margin: EdgeInsets.only(top: 24, bottom: 16),
                                  decoration:
                                      BoxDecoration(color: Color(0xff171717)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 8),
                                    child: Text(
                                      "TIME",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.4,
                                    margin: EdgeInsets.only(
                                        top: 24, bottom: 16, left: 16),
                                    decoration:
                                        BoxDecoration(color: Color(0xff171717)),
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          "7PM",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
