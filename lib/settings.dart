import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'style.dart';

class Ajustes extends ChangeNotifier {
  bool _temaOscuro = false;
  bool _vinilo = true;

  bool get temaOscuro => _temaOscuro;
  bool get vinilo => _vinilo;

  /// Lee lo guardado. Se llama una vez, al abrir la app.
  Future<void> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _temaOscuro = prefs.getBool('tema_oscuro') ?? false;
      _vinilo = prefs.getBool('vinilo') ?? true;
    } catch (_) {
      // Si falla la lectura, se quedan los valores por defecto.
    }
    _aplicarPaleta();
  }

  Future<void> cambiarTemaOscuro(bool valor) async {
    _temaOscuro = valor;
    _aplicarPaleta();
    notifyListeners();
    await _guardar('tema_oscuro', valor);
  }

  Future<void> cambiarVinilo(bool valor) async {
    _vinilo = valor;
    notifyListeners();
    await _guardar('vinilo', valor);
  }

  void _aplicarPaleta() {
    paletaActual = _temaOscuro ? paletaOscura : paletaAzul;
  }

  Future<void> _guardar(String clave, bool valor) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(clave, valor);
    } catch (_) {
      // Si no se pudo guardar, el cambio vale solo hasta cerrar la app.
    }
  }
}