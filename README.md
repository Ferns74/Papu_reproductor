# Papu Reproductor :V 

Reproductor de música local para Android, hecho con Flutter. Reproduce los archivos de audio del almacenamiento interno del teléfono y de la tarjeta SD.

## Características y funciones

- Lee la música del almacenamiento interno y de la tarjeta SD
- Búsqueda por nombre o artista, y orden por nombre o fecha
- Navegación por carpetas y subcarpetas
- Siguiente, anterior, modo aleatorio, repetir y reproducción continua
- Controles en la barra de notificaciones y en la pantalla de bloqueo, con la música en segundo plano
- Pantalla de reproducción con carátula tipo vinilo o cuadrada, y vista ampliada de la imagen
- Tema azul o modo oscuro, configurable en Ajustes

## Instalación

1. Ve a la sección [Releases](../../releases) y descarga el archivo `.apk` de la última versión.
2. Ábrelo en tu celular. Si Android lo pide, permite la instalación desde esta fuente.
3. Al abrir la app, acepta los permisos de audio y de notificaciones.

## Compilar desde el código

Es necesario descargar el SDK de Flutter y el SDK de Android.

```bash
flutter pub get
flutter run
flutter build apk --release
```

## Tecnologías

Flutter, Dart, just_audio, audio_service, on_audio_query_forked, permission_handler y shared_preferences.

## Versión actual 

1.0.0s