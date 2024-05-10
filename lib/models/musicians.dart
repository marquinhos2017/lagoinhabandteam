import 'package:flutter/material.dart';
import 'package:lagoinha_music/models/musician.dart';

class Shop extends ChangeNotifier {
  final List<Musician> _shop = [
    Musician(
      name: "Marcos Rodrigues",
      instrument: "Guitar",
      color: "white",
    ),
    Musician(
      name: "Lucas Barbosa",
      instrument: "Vocal",
      color: "white",
    ),
    Musician(
      name: "Maria Eduarda",
      instrument: "Drum",
      color: "white",
    ),
    Musician(
      name: "Product 4",
      instrument: "Guitar",
      color: "Blue",
    ),
  ];

  List<Musician> _cart = [];

  List<Musician> get shop => _shop;
  List<Musician> get cart => _cart;

  void addToCart(Musician item) {
    _cart.add(item);
    notifyListeners();
  }

  void removeFromCart(Musician item) {
    _cart.remove(item);
    notifyListeners();
  }
}
