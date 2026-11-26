import 'package:on_audio_query_forked/on_audio_query.dart';

class Carpeta {
  Carpeta(this.nombre, this.ruta);

  final String nombre;
  final String ruta;
  final Map<String, Carpeta> subcarpetas = {};
  final List<SongModel> canciones = [];

  /// Cantidad de canciones de esta carpeta y de todas sus subcarpetas.
  int get total =>
      canciones.length +
      subcarpetas.values.fold(0, (suma, sub) => suma + sub.total);

  /// Las canciones de esta carpeta y de todas sus subcarpetas, en una sola lista.
  List<SongModel> todasLasCanciones() {
    return [
      ...canciones,
      for (final sub in subcarpetas.values) ...sub.todasLasCanciones(),
    ];
  }
}

int _largoVolumen(List<String> p) {
  if (p.length >= 3 &&
      p[0] == 'storage' &&
      (p[1] == 'emulated' || p[1] == 'self')) {
    return 3; // /storage/emulated/0
  }
  if (p.length >= 2 && p[0] == 'storage') {
    return 2; // /storage/XXXX-XXXX (tarjeta SD)
  }
  return 1;
}

String _nombreVolumen(List<String> p, int largo) {
  if (largo == 3) return 'Almacenamiento interno';
  if (p[0] == 'storage') return 'Tarjeta SD';
  return p[0];
}

Carpeta construirArbol(List<SongModel> canciones) {
  final raiz = Carpeta('Raíz', '');

  for (final cancion in canciones) {
    final partes = cancion.data.split('/').where((p) => p.isNotEmpty).toList();
    if (partes.length < 2) continue;
    partes.removeLast(); // quita el nombre del archivo, queda solo la carpeta

    final largo = _largoVolumen(partes);
    var ruta = '/${partes.take(largo).join('/')}';
    var actual = raiz.subcarpetas.putIfAbsent(
      ruta,
      () => Carpeta(_nombreVolumen(partes, largo), ruta),
    );

    for (final parte in partes.skip(largo)) {
      ruta = '$ruta/$parte';
      final rutaActual = ruta;
      actual = actual.subcarpetas.putIfAbsent(
        rutaActual,
        () => Carpeta(parte, rutaActual),
      );
    }
    actual.canciones.add(cancion);
  }
  return raiz;
}