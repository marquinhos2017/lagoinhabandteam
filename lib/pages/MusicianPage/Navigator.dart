import 'package:flutter/material.dart';

class MyNavigatorObserver extends NavigatorObserver {
  final Function onPagePopped;

  MyNavigatorObserver({required this.onPagePopped});

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // Chama a função de atualização da página principal quando a página anterior for popada
    onPagePopped();
  }
}
