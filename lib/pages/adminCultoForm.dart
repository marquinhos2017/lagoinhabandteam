import 'package:flutter/material.dart';
import 'package:lagoinha_music/main.dart';
import 'package:lagoinha_music/models/culto.dart';
import 'package:lagoinha_music/models/musico.dart';
import 'package:lagoinha_music/pages/adminWorshipTeamSelect.dart';
import 'package:provider/provider.dart';

class adminCultoForm extends StatelessWidget {
  late Culto cultoatual;

  adminCultoForm({required this.cultoatual});

  @override
  Widget build(BuildContext context) {
    CultosProvider cultosProvider = Provider.of<CultosProvider>(context);

    int index = cultosProvider.cultos
        .indexWhere((culto) => culto.nome == cultoatual.nome);
    print(index);

    Culto cultoEspecifico = cultosProvider.cultos[index];
    String nomes = "";
    print("Culto: " + cultoEspecifico.nome);
    for (Musico musico in cultoEspecifico.musicos) {
      //print(musico.nome);
      if (nomes.isEmpty) {
        nomes = nomes + musico.nome;
      } else {
        nomes = nomes + ", " + musico.nome;
      }

      print(
          nomes); // Supondo que 'nome' seja o atributo que você deseja imprimir
    }

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
                Text(
                  "Culto " + cultoatual.nome,
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  "Musicos:" + nomes,
                  style: TextStyle(color: Colors.white),
                ),
                Container(
                  margin: EdgeInsets.only(top: 20, bottom: 20),
                  child: GestureDetector(
                      onTap: () => Navigator.of(context)
                          .popUntil((route) => route.isFirst),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      )),
                ),
                Column(
                  children: [
                    Container(
                      child: Text(
                        "${cultosProvider.cultos}",
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
                            Container(
                              padding: EdgeInsets.zero,
                              height: 100,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      child: ListView.builder(
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
                                                              musico.nome,
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                            Row(
                                                              children: [
                                                                Container(
                                                                  margin: EdgeInsets
                                                                      .only(
                                                                          right:
                                                                              20),
                                                                  child: Text(
                                                                    musico
                                                                        .instrumento,
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
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Center(
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MusicianSelect(
                                        cultoatual:
                                            Culto(nome: cultoEspecifico.nome)),
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
