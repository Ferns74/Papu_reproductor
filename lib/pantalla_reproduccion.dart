import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'controlador_music.dart';
import 'style.dart';

class PantallaReproduccion extends StatefulWidget {
  const PantallaReproduccion({super.key, required this.c});
  final ControladorMusica c;

  @override
  State<PantallaReproduccion> createState() => _PantallaReproduccionState();
}

class _PantallaReproduccionState extends State<PantallaReproduccion>
    with SingleTickerProviderStateMixin {
  // Hace girar la carátula (solo en modo vinilo), una vuelta cada 20 segundos.
  late final AnimationController _giro = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );
  StreamSubscription<bool>? _subSonando;

  @override
  void initState() {
    super.initState();
    _subSonando = widget.c.reproductor.playingStream.listen((sonando) {
      if (sonando && widget.c.ajustes.vinilo) {
        _giro.repeat();
      } else {
        _giro.stop();
      }
    });
  }

  @override
  void dispose() {
    _subSonando?.cancel();
    _giro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final cancion = c.actual;
        if (cancion == null) return const Scaffold();

        final pantalla = MediaQuery.of(context).size;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Fondo: la carátula ampliada, desenfocada y teñida
              _Caratula(
                id: cancion.id,
                ancho: pantalla.width,
                alto: pantalla.height,
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        colorFondoOscuro.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 56),
                      _construirCaratula(context, cancion, pantalla),
                      const SizedBox(height: 28),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          cancion.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          nombreArtista(cancion),
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _BarraProgreso(reproductor: c.reproductor),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Aleatorio a la IZQUIERDA
                         _Boton(
                            icono: Icons.shuffle,
                            activo: c.aleatorio,
                            onPressed: c.alternarAleatorio,
                          ),
                          IconButton(
                            iconSize: 40,
                            icon: const Icon(Icons.skip_previous),
                            onPressed: c.anterior,
                          ),
                          StreamBuilder<bool>(
                            stream: c.reproductor.playingStream,
                            builder: (context, snapshot) {
                              final sonando = snapshot.data ?? false;
                              return Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    width: 3,
                                  ),
                                ),
                                child: IconButton.filled(
                                  iconSize: 40,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: colorFondoOscuro,
                                  ),
                                  icon: Icon(sonando
                                      ? Icons.pause
                                      : Icons.play_arrow),
                                  onPressed: () => sonando
                                      ? c.reproductor.pause()
                                      : c.reproductor.play(),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            iconSize: 40,
                            icon: const Icon(Icons.skip_next),
                            onPressed: c.siguiente,
                          ),
                          // Repetir a la DERECHA
                          _Boton(
                            icono: c.repetir == LoopMode.one
                                ? Icons.repeat_one
                                : Icons.repeat,
                            activo: c.repetir != LoopMode.off,
                            onPressed: c.alternarRepetir,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Devuelve la carátula según lo elegido en Ajustes: vinilo o cuadrada.
  Widget _construirCaratula(
      BuildContext context, SongModel cancion, Size pantalla) {
    if (widget.c.ajustes.vinilo) {
      final lado = (pantalla.width - 96).clamp(180.0, pantalla.height * 0.40);
      final relleno = lado * 0.05;
      final interior = lado - 2 * relleno - 6;

      return GestureDetector(
        onTap: () => _verGrande(context, cancion.id),
        child: Container(
          width: lado,
          height: lado,
          padding: EdgeInsets.all(relleno),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: RotationTransition(
            turns: _giro,
            child: ClipOval(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _Caratula(id: cancion.id, ancho: interior, alto: interior),
                  Container(
                    width: interior * 0.12,
                    height: interior * 0.12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorFondoOscuro,
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Modo cuadrada: la foto de siempre, con esquinas redondeadas.
    final lado = (pantalla.width - 48).clamp(180.0, pantalla.height * 0.42);
    return GestureDetector(
      onTap: () => _verGrande(context, cancion.id),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _Caratula(id: cancion.id, ancho: lado, alto: lado),
        ),
      ),
    );
  }

  void _verGrande(BuildContext context, int id) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) {
          final ancho = MediaQuery.of(ctx).size.width;
          return Scaffold(
            backgroundColor: Colors.black,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: InteractiveViewer(
                maxScale: 5,
                child: _Caratula(
                  id: id,
                  ancho: ancho,
                  alto: ancho,
                  ajuste: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Caratula extends StatelessWidget {
  const _Caratula({
    required this.id,
    required this.ancho,
    required this.alto,
    this.ajuste = BoxFit.cover,
  });

  final int id;
  final double ancho;
  final double alto;
  final BoxFit ajuste;

  @override
  Widget build(BuildContext context) {
    return QueryArtworkWidget(
      id: id,
      type: ArtworkType.AUDIO,
      format: ArtworkFormat.JPEG,
      size: 1000,
      quality: 100,
      artworkWidth: ancho,
      artworkHeight: alto,
      artworkFit: ajuste,
      artworkBorder: BorderRadius.zero,
      keepOldArtwork: true,
      nullArtworkWidget: Container(
        width: ancho,
        height: alto,
        color: const Color(0xFF23265A),
        child: Icon(Icons.music_note, size: ancho * 0.4, color: Colors.white54),
      ),
    );
  }
}

class _BarraProgreso extends StatelessWidget {
  const _BarraProgreso({required this.reproductor});
  final AudioPlayer reproductor;

  String _formato(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: reproductor.durationStream,
      builder: (context, snapDuracion) {
        final total = snapDuracion.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: reproductor.positionStream,
          builder: (context, snapPosicion) {
            var pos = snapPosicion.data ?? Duration.zero;
            if (pos > total) pos = total;
            final maxMs = total.inMilliseconds.toDouble();

            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    activeTrackColor: colorAcento,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: maxMs <= 0
                        ? 0
                        : pos.inMilliseconds
                            .toDouble()
                            .clamp(0.0, maxMs)
                            .toDouble(),
                    max: maxMs <= 0 ? 1 : maxMs,
                    onChanged: (v) =>
                        reproductor.seek(Duration(milliseconds: v.round())),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formato(pos),
                          style: const TextStyle(color: Colors.white70)),
                      Text(_formato(total),
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Boton extends StatelessWidget {
  const _Boton({
    required this.icono,
    required this.activo,
    required this.onPressed,
  });

  final IconData icono;
  final bool activo;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Espacio arriba igual al de la bolita de abajo, para que el
        // ícono quede alineado con los demás botones de la fila.
        const SizedBox(height: 7),
        IconButton(
          icon: Icon(icono, color: activo ? colorAcento : Colors.white54),
          onPressed: onPressed,
        ),
        const SizedBox(height: 2),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: activo ? colorAcento : Colors.transparent,
          ),
        ),
      ],
    );
  }
}