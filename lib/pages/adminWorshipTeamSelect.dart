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
                    GestureDetector(
                      onTap: () => showDialog<String>(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          backgroundColor: Color(0xff171717),
                          title: const Text(
                            'Enviar solicitação para Marcos ?',
                            style: TextStyle(color: Colors.white),
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'Cancel'),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                addMarcos(index);

                                Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (context) => adminCultoForm(
                                            cultoatual:
                                                Culto(nome: cultoatual.nome))),
                                    (Route<dynamic> route) => false);
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
                                "Marcos Rodrigues",
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
                                    "Keyboard",
                                    style: TextStyle(
                                        color: Color(0xff558FFF), fontSize: 10),
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
                    ),
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
