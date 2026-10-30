import 'package:flutter/material.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

/// Un conjunto de colores para la app.
class Paleta {
  const Paleta({
    required this.acento,
    required this.fondoOscuro,
    required this.degradado,
  });

  final Color acento;
  final Color fondoOscuro;
  final List<Color> degradado;
}

const paletaAzul = Paleta(
  acento: Color(0xFF9AA5FF),
  fondoOscuro: Color(0xFF0D0E2B),
  degradado: [Color(0xFF4B5068), Color(0xFF23265A), Color(0xFF0D0E2B)],
);

const paletaOscura = Paleta(
  acento: Color(0xFFE0E0E0),
  fondoOscuro: Color(0xFF000000),
  degradado: [Color(0xFF2B2B2B), Color(0xFF141414), Color(0xFF000000)],
);

/// La paleta que se está usando ahora. Los ajustes la cambian.
Paleta paletaActual = paletaAzul;

// Con estos dos "getters", todo el código que ya usa colorAcento y
// colorFondoOscuro sigue funcionando, pero ahora el color depende de la paleta.
Color get colorAcento => paletaActual.acento;
Color get colorFondoOscuro => paletaActual.fondoOscuro;

/// Fondo en degradado, con los colores de la paleta actual.
class FondoDegradado extends StatelessWidget {
  const FondoDegradado({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: paletaActual.degradado,
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// Carátula pequeña con esquinas redondeadas (o circular).
class MiniCaratula extends StatelessWidget {
  const MiniCaratula({
    super.key,
    required this.id,
    this.tamano = 52,
    this.redonda = false,
  });

  final int id;
  final double tamano;
  final bool redonda;

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(redonda ? tamano / 2 : 12);
    return QueryArtworkWidget(
      id: id,
      type: ArtworkType.AUDIO,
      artworkWidth: tamano,
      artworkHeight: tamano,
      artworkFit: BoxFit.cover,
      artworkBorder: radio,
      keepOldArtwork: true,
      nullArtworkWidget: Container(
        width: tamano,
        height: tamano,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: radio,
        ),
        child: Icon(Icons.music_note, color: Colors.white70, size: tamano * 0.5),
      ),
    );
  }
}