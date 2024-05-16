import 'package:flutter/material.dart';
import 'package:lagoinha_music/models/musician.dart';

class Shop extends ChangeNotifier {
  final List<Musician> _shop = [
    Musician(
        name: "Marcos Rodrigues",
        instrument: "Guitar",
        color: "white",
        password: "08041999",
        tipo: "musico"),
    Musician(
        name: "Lucas Barbosa",
        instrument: "Vocal",
        color: "white",
        password: "123456789",
        tipo: "musico"),
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
