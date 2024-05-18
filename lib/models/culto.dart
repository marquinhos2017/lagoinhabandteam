import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lagoinha_music/models/musica.dart';
import 'package:lagoinha_music/models/musician.dart';
import 'package:lagoinha_music/models/musico.dart';

class Culto {
  String nome;
  List<Musician> musicos = [];
  List<Musica> musicas = [];

  Culto({
    required this.nome,
    List<Musician>? musicos,
    List<Musica>? musicas,
  }) {
    this.musicos =
        musicos ?? []; // Inicialize com uma lista vazia se não for fornecida
    this.musicas =
        musicas ?? []; // Inicialize com uma lista vazia se não for fornecida
  }

  factory Culto.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List<dynamic> musicosData = data['musicos'] ?? [];
    List<Musician> musicosList = musicosData.map((musicianData) {
      return Musician(
        name: musicianData['name'] ?? '',
        instrument: musicianData['instrument'] ?? '',
        color: musicianData['color'] ?? '',
        password: musicianData['password'] ?? '',
        tipo: musicianData['tipo'] ?? '',
      );
    }).toList();
    return Culto(
      nome: data['nome'] ?? '',
      musicos: musicosList,
    );
  }
}

// Exemplo de como adicionar um músico a um culto específico
void adicionarMusicoAoCulto(Musician musico, Culto culto) {
  culto.musicos.add(musico);
}

// Exemplo de como adicionar uma música a um culto específico
void adicionarMusicaAoCulto(Musica musica, Culto culto) {
  culto.musicas.add(musica);
}
