import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class ManejadorAudio extends BaseAudioHandler with SeekHandler {
  ManejadorAudio() {
    // Cada cambio del reproductor se refleja en la notificación.
    reproductor.playbackEventStream.listen(_publicarEstado);
    reproductor.playingStream.listen((_) => _publicarEstado());
    reproductor.currentIndexStream.listen((i) {
      if (i != null && i >= 0 && i < _items.length) {
        mediaItem.add(_items[i]);
      }
    });
  }

  final AudioPlayer reproductor = AudioPlayer();
  final ValueNotifier<bool> aleatorio = ValueNotifier(false);
  List<MediaItem> _items = [];

  /// Carga una lista de canciones y empieza a reproducir la del índice dado.
  Future<void> cargar(List<MediaItem> items, int indice) async {
    _items = items;
    await reproductor.setAudioSources(
      items.map((m) => AudioSource.uri(Uri.parse(m.extras!['uri'] as String))).toList(),
      initialIndex: indice,
      initialPosition: Duration.zero,
    );
    mediaItem.add(items[indice]);
    unawaited(reproductor.play());
  }

  Future<void> alternarAleatorio() async {
    final nuevo = !aleatorio.value;
    if (nuevo && _items.isNotEmpty) await reproductor.shuffle();
    await reproductor.setShuffleModeEnabled(nuevo);
    aleatorio.value = nuevo;
    _publicarEstado(); // para que cambie el ícono del botón
  }

  void _publicarEstado([PlaybackEvent? evento]) {
    final sonando = reproductor.playing;
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.custom(
          androidIcon:
              aleatorio.value ? 'drawable/ic_aleatorio' : 'drawable/ic_normal',
          label: aleatorio.value ? 'Aleatorio' : 'Normal',
          name: 'alternar_aleatorio',
        ),
        MediaControl.skipToPrevious,
        if (sonando) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [1, 2, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[reproductor.processingState]!,
      playing: sonando,
      updatePosition: reproductor.position,
      bufferedPosition: reproductor.bufferedPosition,
      speed: reproductor.speed,
      queueIndex: reproductor.currentIndex,
    ));
  }

  // Lo que pasa cuando el usuario toca un botón de la notificación:
  @override
  Future<void> play() => reproductor.play();

  @override
  Future<void> pause() => reproductor.pause();

  @override
  Future<void> seek(Duration position) => reproductor.seek(position);

  @override
  Future<void> skipToNext() => reproductor.seekToNext();

  @override
  Future<void> skipToPrevious() => reproductor.seekToPrevious();

  @override
  Future<void> stop() async {
    await reproductor.stop();
    return super.stop();
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'alternar_aleatorio') {
      await alternarAleatorio();
    }
    return super.customAction(name, extras);
  }
}