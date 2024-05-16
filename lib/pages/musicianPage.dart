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
        appBar: AppBar(
          title: const Text('Home Page'),
        ),
        body: Column(
          children: [
            Text(email),
            Text("Cultos"),
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
        ));
  }
}
