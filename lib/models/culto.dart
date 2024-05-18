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
}

// Exemplo de como adicionar um músico a um culto específico
void adicionarMusicoAoCulto(Musician musico, Culto culto) {
  culto.musicos.add(musico);
}

// Exemplo de como adicionar uma música a um culto específico
void adicionarMusicaAoCulto(Musica musica, Culto culto) {
  culto.musicas.add(musica);
}
