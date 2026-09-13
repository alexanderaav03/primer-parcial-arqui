import 'package:flutter/material.dart';

/// Key global para poder mostrar SnackBars desde fuera del árbol de widgets
/// (por ejemplo, desde el interceptor de Dio cuando el gateway responde 401/503).
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showGlobalMessage(String message) {
  scaffoldMessengerKey.currentState
    ?..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}
