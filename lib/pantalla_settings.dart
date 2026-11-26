import 'package:flutter/material.dart';
import 'settings.dart';

class PantallaAjustes extends StatelessWidget {
  const PantallaAjustes({super.key, required this.ajustes});
  final Ajustes ajustes;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ajustes,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          children: [
            const _Titulo('Tema'),
            _Panel(
              child: SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text('Modo oscuro'),
                value: ajustes.temaOscuro,
                onChanged: ajustes.cambiarTemaOscuro,
              ),
            ),
            const SizedBox(height: 24),
            const _Titulo('Carátula al reproducir'),
            _Panel(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.album),
                          label: Text('Vinilo'),
                        ),
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.crop_square),
                          label: Text('Cuadrada'),
                        ),
                      ],
                      selected: {ajustes.vinilo},
                      onSelectionChanged: (seleccion) =>
                          ajustes.cambiarVinilo(seleccion.first),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ajustes.vinilo
                          ? 'La carátula es circular, con aro, y gira mientras suena la canción.'
                          : 'La carátula se muestra como una foto cuadrada, sin giro.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}