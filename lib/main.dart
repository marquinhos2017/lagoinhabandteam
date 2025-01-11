import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/models/culto.dart';
import 'package:lagoinha_music/models/musician.dart';
import 'package:lagoinha_music/pages/MusicianPage/musicianPageNewUI.dart';

import 'package:lagoinha_music/pages/adminAddtoPlaylist.dart';
import 'package:lagoinha_music/pages/adminWorshipTeamSelect.dart';

import 'package:lagoinha_music/pages/login.dart';
import 'package:lagoinha_music/pages/userMain.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String? _userId;
  int? userid;

  String? get userId => _userId;

  AuthProvider() {
    // Carrega o userId automaticamente ao inicializar o AuthProvider
    loadUserId();
  }

  Future<void> loadUserId() async {
    // Carrega o userId das preferências
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');

    // Converte o userIdString para int, se possível
    if (_userId != null) {
      try {
        userid = int.parse(_userId!);
      } catch (e) {
        // Em caso de erro na conversão, definir userid como null
        userid = null;
        print('Erro ao converter user_id para int: $e');
      }
    } else {
      userid = null;
    }

    print(userid);

    notifyListeners();
  }

  Future<void> login(String userId) async {
    _userId = userId;
    notifyListeners();

    // Salva o userId nas preferências
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  Future<void> logout() async {
    _userId = null;
    userid = null; // Limpa também o userid convertido para int
    notifyListeners();

    // Remove o userId das preferências
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');

    // Limpa outros caches ou dados específicos do usuário aqui
    await clearUserCache();

    // Navegar para a tela inicial ou de login
  }

  Future<void> clearUserCache() async {
    // Implementar lógica para limpar outros caches, se necessário
    // Exemplo:
    // - Limpar dados temporários
    // - Resetar qualquer estado relacionado ao usuário
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
  await SharedPreferences.getInstance(); // Inicializa as preferências
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print("Autasdo: " + authProvider._userId.toString());

        return MaterialApp(
          theme: ThemeData(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
              dialHandColor: Colors.blue,
              hourMinuteTextColor: Colors.black,
              dayPeriodTextColor: Colors.black,
              dayPeriodColor: Colors.blue,
            ),
          ),
          title: 'LWF',
          home: authProvider.userId == null
              ? const login()
              : FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('musicos')
                      .where('user_id', isEqualTo: authProvider.userid)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      print("User_Id: = " + authProvider._userId.toString());
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        print("aasdasasdasdasdassd");
                        // Pega o primeiro documento da consulta
                        var userData = snapshot.data!.docs.first.data()
                            as Map<String, dynamic>;
                        var userType = userData['tipo'];

                        // Redireciona com base no tipo de usuário
                        if (userType == 'user') {
                          return MusicianPageNewUI(id: authProvider.userId!);
                        } else {
                          return userMainPage();
                        }
                      } else {
                        return Center(
                          child: Container(
                            color: Colors.white,
                            child: Column(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.exit_to_app,
                                    color: Colors.black,
                                  ),
                                  onPressed: () async {
                                    // Chama a função de logout
                                    await Provider.of<AuthProvider>(context,
                                            listen: false)
                                        .logout();
                                    // Redireciona para a página de login após o logout
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => login()),
                                    );
                                  },
                                ),
                                GestureDetector(
                                    onTap: () async {
                                      // Chama a função de logout
                                      await Provider.of<AuthProvider>(context,
                                              listen: false)
                                          .logout();
                                      // Redireciona para a página de login após o logout
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => login()),
                                      );
                                    },
                                    child: Text('Usuário não encontrado')),
                              ],
                            ),
                          ),
                        );
                      }
                    }
                    return const CircularProgressIndicator();
                  },
                ),
        );
      },
    );
  }
}
