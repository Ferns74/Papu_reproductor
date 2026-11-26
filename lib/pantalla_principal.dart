import 'package:flutter/material.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'settings.dart';
import 'carpeta.dart';
import 'controlador_music.dart';
import 'style.dart';
import 'control_audio.dart';
import 'pantalla_settings.dart';
import 'pantalla_reproduccion.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({
    super.key,
    required this.manejador,
    required this.ajustes,
  });
  final ManejadorAudio manejador;
  final Ajustes ajustes;

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  late final ControladorMusica c =
      ControladorMusica(widget.manejador, widget.ajustes);
  int _seccion = 0;

  // Navegación y búsqueda de la pestaña Carpetas. Viven aquí (y no dentro
  // de la pestaña) para poder manejar el botón de retroceso del teléfono.
  final List<Carpeta> _subniveles = [];
  final TextEditingController _textoCarpetas = TextEditingController();
  String _busquedaCarpetas = '';

  @override
  void initState() {
    super.initState();
    c.iniciar();
  }

  @override
  void dispose() {
    _textoCarpetas.dispose();
    c.dispose();
    super.dispose();
  }

  void _limpiarBusquedaCarpetas() {
    _textoCarpetas.clear();
    _busquedaCarpetas = '';
  }

  void _buscarEnCarpetas(String texto) =>
      setState(() => _busquedaCarpetas = texto.trim().toLowerCase());

  void _entrar(Carpeta carpeta) => setState(() {
        _limpiarBusquedaCarpetas();
        _subniveles.add(carpeta);
      });

  void _volver() {
    if (_subniveles.isEmpty) return;
    setState(() {
      _limpiarBusquedaCarpetas();
      _subniveles.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    const titulos = ['Mis canciones', 'Carpetas', 'Ajustes'];

    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        // El retroceso del teléfono solo se intercepta en la pestaña
        // Carpetas, cuando hay algo que deshacer (búsqueda o subcarpeta).
        final puedeSalir = !(_seccion == 1 &&
            (_subniveles.isNotEmpty || _busquedaCarpetas.isNotEmpty));

        return PopScope(
          canPop: puedeSalir,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (_busquedaCarpetas.isNotEmpty) {
              setState(_limpiarBusquedaCarpetas);
            } else {
              _volver();
            }
          },
          child: FondoDegradado(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                title: Text(
                  titulos[_seccion],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 26),
                ),
                actions: [
                  if (_seccion != 2)
                    PopupMenuButton<Orden>(
                      icon: const Icon(Icons.sort),
                      tooltip: 'Ordenar',
                      initialValue: c.orden,
                      onSelected: c.cambiarOrden,
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: Orden.nombreAsc,
                            child: Text('Nombre (A-Z)')),
                        PopupMenuItem(
                            value: Orden.nombreDesc,
                            child: Text('Nombre (Z-A)')),
                        PopupMenuItem(
                            value: Orden.fechaReciente,
                            child: Text('Fecha: más recientes')),
                        PopupMenuItem(
                            value: Orden.fechaAntigua,
                            child: Text('Fecha: más antiguas')),
                      ],
                    ),
                ],
              ),
              body: _cuerpo(),
              bottomNavigationBar: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MiniReproductor(c: c),
                  NavigationBar(
                    backgroundColor: Colors.black.withValues(alpha: 0.25),
                    indicatorColor: colorAcento.withValues(alpha: 0.25),
                    selectedIndex: _seccion,
                    onDestinationSelected: (i) =>
                        setState(() => _seccion = i),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.music_note_outlined),
                        selectedIcon: Icon(Icons.music_note),
                        label: 'Canciones',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.folder_outlined),
                        selectedIcon: Icon(Icons.folder),
                        label: 'Carpetas',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings),
                        label: 'Ajustes',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cuerpo() {
    return IndexedStack(
      index: _seccion,
      children: [
        _conEstado(_TabCanciones(c: c)),
        _conEstado(_TabCarpetas(
          c: c,
          subniveles: _subniveles,
          texto: _textoCarpetas,
          busqueda: _busquedaCarpetas,
          onBuscar: _buscarEnCarpetas,
          onEntrar: _entrar,
          onVolver: _volver,
        )),
        PantallaAjustes(ajustes: widget.ajustes),
      ],
    );
  }

  /// Muestra la carga, el aviso de permiso o el contenido, según el estado.
  /// Ajustes no pasa por aquí: se puede abrir aunque no haya música.
  Widget _conEstado(Widget contenido) {
    if (c.cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!c.tienePermiso) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Necesito permiso para ver tu música'),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: c.iniciar, child: const Text('Dar permiso')),
          ],
        ),
      );
    }
    if (c.todas.isEmpty) {
      return const Center(child: Text('No se encontraron canciones'));
    }
    return contenido;
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.child, this.resaltada = false});
  final Widget child;
  final bool resaltada;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: resaltada
            ? colorAcento.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

// ---------------- Pestaña: Canciones ----------------

class _TabCanciones extends StatefulWidget {
  const _TabCanciones({required this.c});
  final ControladorMusica c;

  @override
  State<_TabCanciones> createState() => _TabCancionesState();
}

class _TabCancionesState extends State<_TabCanciones> {
  final TextEditingController _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            controller: _texto,
            onChanged: c.buscar,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o artista',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _texto.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _texto.clear();
                        c.buscar('');
                      },
                    ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: c.visibles.isEmpty
              ? const Center(child: Text('Sin resultados'))
              : ListView.builder(
                  itemCount: c.visibles.length,
                  itemBuilder: (context, i) {
                    final cancion = c.visibles[i];
                    return _FilaCancion(
                      cancion: cancion,
                      sonando: cancion.id == c.actual?.id,
                      onTap: () => _reproducir(context, c.visibles, i),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _reproducir(
      BuildContext context, List<SongModel> lista, int i) async {
    final ok = await widget.c.reproducirLista(lista, i);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo reproducir esta canción')),
      );
    }
  }
}

// ---------------- Pestaña: Carpetas ----------------

class _TabCarpetas extends StatelessWidget {
  const _TabCarpetas({
    required this.c,
    required this.subniveles,
    required this.texto,
    required this.busqueda,
    required this.onBuscar,
    required this.onEntrar,
    required this.onVolver,
  });

  final ControladorMusica c;
  final List<Carpeta> subniveles;
  final TextEditingController texto;
  final String busqueda;
  final ValueChanged<String> onBuscar;
  final ValueChanged<Carpeta> onEntrar;
  final VoidCallback onVolver;

  bool _coincide(SongModel s) =>
      s.title.toLowerCase().contains(busqueda) ||
      nombreArtista(s).toLowerCase().contains(busqueda);

  @override
  Widget build(BuildContext context) {
    // La carpeta actual es la última de la lista; si está vacía, la raíz.
    final carpeta = subniveles.isEmpty ? c.raiz : subniveles.last;
    final buscando = busqueda.isNotEmpty;

    final resultados = buscando
        ? c.ordenar(carpeta.todasLasCanciones().where(_coincide).toList())
        : <SongModel>[];
    final subs = carpeta.subcarpetas.values.toList()
      ..sort(
          (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    final canciones = c.ordenar(carpeta.canciones);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            controller: texto,
            onChanged: onBuscar,
            decoration: InputDecoration(
              hintText: subniveles.isEmpty
                  ? 'Buscar en todas las carpetas'
                  : 'Buscar en ${carpeta.nombre}',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: buscando
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        texto.clear();
                        onBuscar('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (subniveles.isNotEmpty)
          _Tarjeta(
            child: ListTile(
              leading: const Icon(Icons.arrow_back),
              title: const Text('Volver'),
              subtitle: Text(carpeta.ruta,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: onVolver,
            ),
          ),
        Expanded(
          child: buscando
              ? _listaResultados(resultados)
              : _listaCarpeta(subs, canciones),
        ),
      ],
    );
  }

  Widget _listaResultados(List<SongModel> resultados) {
    if (resultados.isEmpty) {
      return const Center(child: Text('Sin resultados'));
    }
    return ListView.builder(
      itemCount: resultados.length,
      itemBuilder: (context, i) {
        final cancion = resultados[i];
        return _FilaCancion(
          cancion: cancion,
          sonando: cancion.id == c.actual?.id,
          onTap: () => c.reproducirLista(resultados, i),
        );
      },
    );
  }

  Widget _listaCarpeta(List<Carpeta> subs, List<SongModel> canciones) {
    return ListView.builder(
      itemCount: subs.length + canciones.length,
      itemBuilder: (context, i) {
        if (i < subs.length) {
          final sub = subs[i];
          return _Tarjeta(
            child: ListTile(
              leading: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorAcento.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.folder, color: colorAcento),
              ),
              title: Text(sub.nombre,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${sub.total} canciones'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onEntrar(sub),
            ),
          );
        }
        final j = i - subs.length;
        final cancion = canciones[j];
        return _FilaCancion(
          cancion: cancion,
          sonando: cancion.id == c.actual?.id,
          onTap: () => c.reproducirLista(canciones, j),
        );
      },
    );
  }
}

// ---------------- Fila de canción (compartida) ----------------

class _FilaCancion extends StatelessWidget {
  const _FilaCancion({
    required this.cancion,
    required this.sonando,
    required this.onTap,
  });

  final SongModel cancion;
  final bool sonando;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      resaltada: sonando,
      child: ListTile(
        leading: MiniCaratula(id: cancion.id),
        title: Text(
          cancion.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: sonando ? colorAcento : null,
            fontWeight: sonando ? FontWeight.bold : null,
          ),
        ),
        subtitle: Text(nombreArtista(cancion),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: sonando ? Icon(Icons.equalizer, color: colorAcento) : null,
        onTap: onTap,
      ),
    );
  }
}

// ---------------- Mini reproductor ----------------

class MiniReproductor extends StatelessWidget {
  const MiniReproductor({super.key, required this.c});
  final ControladorMusica c;

  @override
  Widget build(BuildContext context) {
    final cancion = c.actual;
    if (cancion == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PantallaReproduccion(c: c)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                MiniCaratula(id: cancion.id, tamano: 52, redonda: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cancion.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(nombreArtista(cancion),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.skip_previous),
                  onPressed: c.anterior,
                ),
                StreamBuilder<bool>(
                  stream: c.reproductor.playingStream,
                  builder: (context, snapshot) {
                    final sonando = snapshot.data ?? false;
                    return IconButton.filled(
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: colorAcento,
                        foregroundColor: colorFondoOscuro,
                      ),
                      icon: Icon(sonando ? Icons.pause : Icons.play_arrow),
                      onPressed: () => sonando
                          ? c.reproductor.pause()
                          : c.reproductor.play(),
                    );
                  },
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.skip_next),
                  onPressed: c.siguiente,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}