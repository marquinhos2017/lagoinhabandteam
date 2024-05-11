import 'package:flutter/material.dart';
import 'package:lagoinha_music/models/culto.dart';
import 'package:lagoinha_music/pages/adminAddtoPlaylist.dart';
import 'package:lagoinha_music/pages/adminCultoForm.dart';
import 'package:lagoinha_music/pages/adminWorshipTeamSelect.dart';
import 'package:lagoinha_music/pages/userMain.dart';
import 'package:provider/provider.dart';

class CultosProvider extends ChangeNotifier {
  List<Culto> _cultos = [];

  List<Culto> get cultos => _cultos;

  void adicionarCulto(Culto culto) {
    _cultos.add(culto);
    notifyListeners();
  }

  void removerCulto(int index) {
    _cultos.removeAt(index);
    notifyListeners();
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => CultosProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: const userMainPage(),
      routes: {
        '/intro_page': (context) => const userMainPage(),
        // '/adminCultoForm': (context) => adminCultoForm(culto: Culto(nome: n),),
        //'/MusicianSelect': (context) => MusicianSelect(),
        '/AddtoPlaylist': (context) => AddtoPlaylist(),
      },
    );
  }
}
