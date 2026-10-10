import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Entorno { creditos, finanzas }

const _kPreferredEntorno = 'preferred_entorno';

final entornoProvider = StateProvider<Entorno>((ref) => Entorno.creditos);

Future<Entorno> loadPreferredEntorno() async {
  final prefs = await SharedPreferences.getInstance();
  final val = prefs.getString(_kPreferredEntorno);
  return val == 'finanzas' ? Entorno.finanzas : Entorno.creditos;
}

Future<void> savePreferredEntorno(Entorno entorno) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kPreferredEntorno, entorno.name);
}
