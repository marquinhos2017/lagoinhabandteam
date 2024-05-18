import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lagoinha_music/models/musician.dart';

class FirestoreService {
  static FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Função para obter os músicos que participaram de um culto específico
  static Future<List<Musician>> getMusicosDoCultoEspecifico(
      String nomeCulto) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('cultos')
        .where('nome', isEqualTo: nomeCulto)
        .get();

    List<Musician> musicosDoCulto = [];

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Aqui você precisa extrair os dados do músico do documento do Firestore e criar um objeto Musician
      // Supondo que 'Musician.fromMap()' seja um construtor estático na classe Musician que cria um objeto Musician a partir de um mapa de dados
      Musician musico = Musician.fromMap(data);

      musicosDoCulto.add(musico);
    }

    return musicosDoCulto;
  }
}
