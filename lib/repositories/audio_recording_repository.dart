import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

final audioRecordingRepositoryProvider = Provider<AudioRecordingRepository>((
  ref,
) {
  final repository = AudioRecordingRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

class AudioRecordingRepository {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  String? _currentPath;

  Future<String?> startRecording({required String wordId}) async {
    final hasPermission = await _recorder.hasPermission();

    if (!hasPermission) {
      throw Exception('Chưa có quyền micro.');
    }

    final dir = await getTemporaryDirectory();

    final path =
        '${dir.path}/speaking_${wordId}_${DateTime.now().millisecondsSinceEpoch}.m4a';

    _currentPath = path;

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    return path;
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();

    if (path != null && path.trim().isNotEmpty) {
      _currentPath = path;
    }

    return _currentPath;
  }

  Future<void> play(String path) async {
    final file = File(path);

    if (!file.existsSync()) {
      throw Exception('Không tìm thấy file ghi âm.');
    }

    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  Future<void> stopPlayback() async {
    await _player.stop();
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
