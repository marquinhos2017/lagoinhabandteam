import 'package:flutter/material.dart';
import 'package:lagoinha_music/main.dart';
import 'package:lagoinha_music/models/culto.dart';
import 'package:provider/provider.dart';

class MusicianPage extends StatelessWidget {
  const MusicianPage({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    CultosProvider cultosProvider = Provider.of<CultosProvider>(context);
    List<Culto> findCultosForMusician(String musicianName) {
      return cultosProvider.cultos.where((culto) {
        return culto.musicos.any((musician) => musician.nome == musicianName);
      }).toList();
    }

    List<Culto> cultosWithMarcos = findCultosForMusician("Marcos Rodrigues");

    for (var culto in cultosWithMarcos) {
      print("Marcos Rodrigues está escalado para: ${culto.nome}");
    }

    return Scaffold(
        backgroundColor: const Color(0xff171717),
        body: Container(
          margin: EdgeInsets.only(top: 100),
          padding: EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Ola, " + email,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 40),
                child: Text(
                  "Cultos Escalados",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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
                            itemCount: cultosWithMarcos.length,
                            itemBuilder: (context, index) {
                              final culto = cultosProvider.cultos[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: GestureDetector(
                                  onTap: () {
                                    //Navigator.pushNamed(
                                    //    context, '/adminCultoForm');
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Color(0xff010101),
                                        borderRadius: BorderRadius.circular(0)),
                                    width: MediaQuery.of(context).size.width,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 30.0, vertical: 12),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                cultosWithMarcos[index].nome,
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                              Text(
                                                "19:30 - 21:00",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w300,
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
              Expanded(
                child: Container(
                  child: ListView.builder(
                      itemCount: cultosWithMarcos.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(cultosWithMarcos[index].nome),
                        );
                      }),
                ),
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Go back!"),
                ),
              ),
            ],
          ),
        ));
  }
}
