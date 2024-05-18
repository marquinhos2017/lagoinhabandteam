class Musician {
  final String name;
  final String instrument;
  final String color;
  final String password;
  final String tipo;

  Musician({
    required this.name,
    required this.instrument,
    required this.color,
    required this.password,
    required this.tipo,
  });

  factory Musician.fromFirestore(Map<String, dynamic> data) {
    return Musician(
      name: data['name'] ?? '',
      instrument: data['instrument'] ?? '',
      color: data['color'] ?? '',
      password: data['password'] ?? '',
      tipo: data['tipo'] ?? '',
    );
  }

  static Musician fromMap(Map<String, dynamic> map) {
    return Musician(
      name: map['name'] ?? '',
      instrument: map['instrument'] ?? '',
      color: map['color'] ?? '',
      password: map['password'] ?? '',
      tipo: map['tipo'] ?? '',
    );
  }
}
