import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/models/culto.dart';
import 'package:lagoinha_music/models/musician.dart';

import 'package:lagoinha_music/pages/adminAddtoPlaylist.dart';
import 'package:lagoinha_music/pages/adminWorshipTeamSelect.dart';

import 'package:lagoinha_music/pages/login.dart';
import 'package:lagoinha_music/pages/userMain.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class AuthProvider with ChangeNotifier {
  String? _userId;

  String? get userId => _userId;

  void login(String userId) {
    _userId = userId;
    notifyListeners();
  }

  void logout() {
    _userId = null;
    notifyListeners();
  }
}

class CultosProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  void addMarcos(CultosProvider culto, int index) {
    culto.cultos[index].musicos.add(Musician(
        color: "grey",
        instrument: "guitar",
        name: "Marcos Rodrigues",
        password: "08041999",
        tipo: "user"));

    notifyListeners();
  }

  Future<void> adicionarMusico(
      Culto culto_atual, String nome, String instrumento) async {
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
          .where('nome', isEqualTo: culto_atual.nome)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Se o documento existe, obter a referência do documento
        var cultoRef = querySnapshot.docs.first.reference;

        // Tentar adicionar o novo músico ao array de músicos
        await cultoRef.update({
          'musicos': FieldValue.arrayUnion([novoMusico])
        });
        print('Músico adicionado com sucesso!');

        FirebaseFirestore.instance.collection('clicks').add({
          'clicked': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
        print("Clicado no: " + novoMusico['name']!);
      } else {
        // Se o documento não existe, criar o documento com o array de músicos
        await cultoCollection.doc().set({
          'nome': culto_atual.nome,
          'musicos': [novoMusico]
        });
        print('Documento criado e músico adicionado com sucesso!');

        await _firestore
            .collection('notifications')
            .doc('musico_adicionado')
            .update({
          'name': novoMusico['name'],
          'instrument': novoMusico['instrument'],
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('Notification updated');

        notifyListeners();
      }
    } catch (e) {
      print('Erro ao adicionar músico: $e');
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('pt_BR', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
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
        // Define cores e estilo global para o time picker
        timePickerTheme: TimePickerThemeData(
          backgroundColor: const Color.fromARGB(255, 0, 0, 0), // Cor de fundo
          dialHandColor: Colors.blue, // Cor do ponteiro
          hourMinuteTextColor: Colors.black, // Cor do texto da hora e minutos
          dayPeriodTextColor: Colors.black, // Cor do texto do período (AM/PM)
          dayPeriodColor: Colors.blue, // Cor do fundo do período (AM/PM)
        ),
      ),
      title: 'LWF',
      home: const login(),
      routes: {
        // '/intro_page': (context) => const userMainPage(),
        // '/adminCultoForm': (context) => adminCultoForm(culto: Culto(nome: n),),
        //'/MusicianSelect': (context) => MusicianSelect(),
        //   '/AddtoPlaylist': (context) => AddtoPlaylist(),
      },
    );
  }
}
