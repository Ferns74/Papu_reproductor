import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'settings.dart';
import 'style.dart';
import 'control_audio.dart';
import 'pantalla_principal.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Se cargan los ajustes antes de dibujar nada, para que el tema
  // correcto aparezca desde el primer momento.
  final ajustes = Ajustes();
  await ajustes.cargar();

  final manejador = await AudioService.init(
    builder: () => ManejadorAudio(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.mireproductor.canal.audio',
      androidNotificationChannelName: 'Reproducción de música',
      androidNotificationOngoing: true,
    ),
  );
  runApp(MiReproductorApp(manejador: manejador, ajustes: ajustes));
}

class MiReproductorApp extends StatelessWidget {
  const MiReproductorApp({
    super.key,
    required this.manejador,
    required this.ajustes,
  });

  final ManejadorAudio manejador;
  final Ajustes ajustes;

  @override
  Widget build(BuildContext context) {
    // Cuando cambian los ajustes, se redibuja toda la app con la nueva paleta.
    return ListenableBuilder(
      listenable: ajustes,
      builder: (context, _) {
        return MaterialApp(
          title: 'Papu Reproductor :v',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(
              seedColor: colorAcento,
              brightness: Brightness.dark,
            ),
          ),
          home: PantallaPrincipal(manejador: manejador, ajustes: ajustes),
        );
      },
    );
  }
}