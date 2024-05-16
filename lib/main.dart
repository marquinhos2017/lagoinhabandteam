import 'package:flutter/material.dart';
import 'package:lagoinha_music/models/culto.dart';
import 'package:lagoinha_music/models/musician.dart';
import 'package:lagoinha_music/pages/adminAddtoPlaylist.dart';
import 'package:lagoinha_music/pages/adminCultoForm.dart';
import 'package:lagoinha_music/pages/adminWorshipTeamSelect.dart';
import 'package:lagoinha_music/pages/login.dart';
import 'package:lagoinha_music/pages/userMain.dart';
import 'package:provider/provider.dart';

class CultosProvider extends ChangeNotifier {
  List<Culto> _cultos = [];
  List<Musician> _musicians = [
    Musician(
        name: "Marcos Rodrigues",
        instrument: "Guitar",
        color: "Blue",
        password: "08041999",
        tipo: "musico"),
    Musician(
        name: "Lucas Almeida",
        instrument: "Vocal",
        color: "Green",
        password: "123456789",
        tipo: "admin"),
  ];

  List<Culto> get cultos => _cultos;
  List<Musician> get musician => _musicians;

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
      theme: ThemeData(
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      title: 'Flutter Demo',
      home: const login(),
      routes: {
        '/intro_page': (context) => const userMainPage(),
        // '/adminCultoForm': (context) => adminCultoForm(culto: Culto(nome: n),),
        //'/MusicianSelect': (context) => MusicianSelect(),
        '/AddtoPlaylist': (context) => AddtoPlaylist(),
      },
    );
  }
}
