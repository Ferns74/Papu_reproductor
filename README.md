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

## Estructura del proyecto

```
papu_reprod/
├── android/                          Configuración nativa de Android
│   └── app/src/main/
│       ├── AndroidManifest.xml       Permisos, servicio de audio y nombre de la app
│       └── res/
│           ├── drawable/             Íconos del botón aleatorio de la notificación
│           ├── mipmap-*/             Ícono de la app
│           └── raw/keep.xml          Evita que Android borre los íconos al compilar
├── assets/
│   ├── fonts/                        Fuente Roboto (Regular, Medium y Bold)
│   └── icon/icono.png                Imagen base del ícono de la app
├── lib/                              Código de la app (Dart)
│   ├── main.dart                     Punto de entrada: ajustes, audio y tema
│   ├── ajustes.dart                  Modo oscuro y estilo de carátula (se guardan en el teléfono)
│   ├── carpeta.dart                  Árbol de carpetas armado con las rutas de las canciones
│   ├── controlador_musica.dart       Biblioteca, búsqueda, orden y cola de reproducción
│   ├── estilo.dart                   Paletas de color, fondo degradado y carátulas pequeñas
│   ├── manejador_audio.dart          Reproductor y controles de la notificación
│   ├── pantalla_principal.dart       Pestañas Canciones, Carpetas y Ajustes, y mini reproductor
│   ├── pantalla_reproduccion.dart    Pantalla completa de reproducción
│   └── pantalla_ajustes.dart         Pantalla de ajustes
├── pubspec.yaml                      Dependencias, versión, fuente e ícono
└── README.md
```

## Tecnologías

Flutter, Dart, just_audio, audio_service, on_audio_query_forked, permission_handler y shared_preferences.

## Versión actual 

1.1.0
