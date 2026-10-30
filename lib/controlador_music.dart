import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'carpeta.dart';
import 'control_audio.dart';
import 'settings.dart';

enum Orden { nombreAsc, nombreDesc, fechaReciente, fechaAntigua }

String nombreArtista(SongModel c) {
  final a = c.artist;
  return (a == null || a == '<unknown>') ? 'Artista desconocido' : a;
}

class ControladorMusica extends ChangeNotifier {
  ControladorMusica(this._manejador, this.ajustes) {
    _suscripcionIndice = reproductor.currentIndexStream.listen((i) {
      if (i != null && i >= 0 && i < _cola.length) {
        actual = _cola[i];
        notifyListeners();
      }
    });
    // Si cambias aleatorio desde la notificación, la pantalla se entera.
    _manejador.aleatorio.addListener(notifyListeners);
  }

  final ManejadorAudio _manejador;
  final Ajustes ajustes;
  final OnAudioQuery _consulta = OnAudioQuery();
  late final StreamSubscription<int?> _suscripcionIndice;

  AudioPlayer get reproductor => _manejador.reproductor;
  bool get aleatorio => _manejador.aleatorio.value;

  bool cargando = true;
  bool tienePermiso = false;
  List<SongModel> todas = [];
  List<SongModel> visibles = [];
  Carpeta raiz = Carpeta('Raíz', '');

  String _busqueda = '';
  Orden _orden = Orden.nombreAsc;
  Orden get orden => _orden;

  List<SongModel> _cola = [];
  SongModel? actual;
  LoopMode repetir = LoopMode.off;

  Future<void> iniciar() async {
    cargando = true;
    notifyListeners();

    var permiso = await _consulta.permissionsStatus();
    if (!permiso) permiso = await _consulta.permissionsRequest();
    tienePermiso = permiso;

    if (permiso) {
      if (!await Permission.notification.isGranted) {
        await Permission.notification.request();
      }

      todas = await _consulta.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      raiz = construirArbol(todas);
      _aplicarFiltro();
    }

    cargando = false;
    notifyListeners();
  }

  // ---------- Filtrar y ordenar ----------

  void buscar(String texto) {
    _busqueda = texto.trim().toLowerCase();
    _aplicarFiltro();
    notifyListeners();
  }

  void cambiarOrden(Orden nuevo) {
    _orden = nuevo;
    _aplicarFiltro();
    notifyListeners();
  }

  List<SongModel> ordenar(List<SongModel> lista) {
    final copia = List<SongModel>.of(lista);
    switch (_orden) {
      case Orden.nombreAsc:
        copia.sort((a, b) =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case Orden.nombreDesc:
        copia.sort((a, b) =>
            b.title.toLowerCase().compareTo(a.title.toLowerCase()));
      case Orden.fechaReciente:
        copia.sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
      case Orden.fechaAntigua:
        copia.sort((a, b) => (a.dateAdded ?? 0).compareTo(b.dateAdded ?? 0));
    }
    return copia;
  }

  void _aplicarFiltro() {
    final filtradas = todas.where((c) {
      if (_busqueda.isEmpty) return true;
      return c.title.toLowerCase().contains(_busqueda) ||
          nombreArtista(c).toLowerCase().contains(_busqueda);
    }).toList();
    visibles = ordenar(filtradas);
  }

  // ---------- Reproducción ----------

  MediaItem _crearItem(SongModel c) {
    final ms = c.duration ?? 0;
    return MediaItem(
      id: c.id.toString(),
      title: c.title,
      artist: nombreArtista(c),
      album: c.album,
      duration: ms > 0 ? Duration(milliseconds: ms) : null,
      artUri: c.albumId != null
          ? Uri.parse('content://media/external/audio/albumart/${c.albumId}')
          : null,
      extras: {'uri': c.uri},
    );
  }

  Future<bool> reproducirLista(List<SongModel> lista, int indice) async {
    _cola = lista;
    try {
      await _manejador.cargar(lista.map(_crearItem).toList(), indice);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> siguiente() => reproductor.seekToNext();
  Future<void> anterior() => reproductor.seekToPrevious();

  Future<void> alternarAleatorio() => _manejador.alternarAleatorio();

  Future<void> alternarRepetir() async {
    repetir = switch (repetir) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    await reproductor.setLoopMode(repetir);
    notifyListeners();
  }

  @override
  void dispose() {
    _suscripcionIndice.cancel();
    _manejador.aleatorio.removeListener(notifyListeners);
    // OJO: no se destruye el reproductor, para que la música siga
    // sonando aunque cierres la pantalla de la app.
    super.dispose();
  }
}