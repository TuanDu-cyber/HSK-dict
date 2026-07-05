import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/word_model.dart';
import '../../repositories/learning_activity_repository.dart';
import '../../repositories/speaking_progress_repository.dart';
import '../../repositories/speech_recognition_repository.dart';
import '../../repositories/tts_repository.dart';
import '../../repositories/word_repository.dart';
import 'speaking_state.dart';
import '../../repositories/audio_recording_repository.dart';

final speakingProvider = StateNotifierProvider.autoDispose
    .family<SpeakingNotifier, SpeakingState, String>((ref, topic) {
      final notifier = SpeakingNotifier(
        topic: topic,
        wordRepository: ref.watch(wordRepositoryProvider),
        progressRepository: ref.watch(speakingProgressRepositoryProvider),
        speechRepository: ref.watch(speechRecognitionRepositoryProvider),
        ttsRepository: ref.watch(ttsRepositoryProvider),
        audioRepository: ref.watch(audioRecordingRepositoryProvider),
        learningActivityRepository: ref.watch(
          learningActivityRepositoryProvider,
        ),
      );

      ref.onDispose(notifier.dispose);

      return notifier..loadSpeakingByTopic();
    });

class SpeakingNotifier extends StateNotifier<SpeakingState> {
  SpeakingNotifier({
    required String topic,
    required WordRepository wordRepository,
    required SpeakingProgressRepository progressRepository,
    required SpeechRecognitionRepository speechRepository,
    required TtsRepository ttsRepository,
    required AudioRecordingRepository audioRepository,
    required LearningActivityRepository learningActivityRepository,
  }) : _wordRepository = wordRepository,
       _progressRepository = progressRepository,
       _speechRepository = speechRepository,
       _ttsRepository = ttsRepository,
       _audioRepository = audioRepository,
       _learningActivityRepository = learningActivityRepository,
       super(SpeakingState(topic: topic));

  static const int maxQuestionCount = 20;

  final WordRepository _wordRepository;
  final SpeakingProgressRepository _progressRepository;
  final SpeechRecognitionRepository _speechRepository;
  final TtsRepository _ttsRepository;
  final AudioRecordingRepository _audioRepository;
  final LearningActivityRepository _learningActivityRepository;

  Timer? _recordTimer;

  Future<void> loadSpeakingByTopic() async {
    try {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        isCompleted: false,
        clearRecognizedText: true,
      );

      final topicWords = await _wordRepository.getWordsByTopic(state.topic);

      if (topicWords.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          words: const [],
          error: 'Chưa có dữ liệu luyện nói cho chủ đề này.',
        );
        return;
      }

      final progress = await _progressRepository.loadProgress(state.topic);

      int sessionSeed = progress?.sessionSeed ?? 0;

      if (sessionSeed == 0 || progress?.isCompleted == true) {
        sessionSeed = DateTime.now().millisecondsSinceEpoch;
      }

      final words = _buildSessionWords(
        topicWords: topicWords,
        seed: sessionSeed,
        savedWordIds: progress?.wordIds ?? const [],
      );

      final maxIndex = words.isEmpty ? 0 : words.length - 1;
      final savedIndex = progress?.currentIndex ?? 0;
      final safeIndex = savedIndex.clamp(0, maxIndex);

      state = state.copyWith(
        isLoading: false,
        words: words,
        currentIndex: safeIndex,
        sessionSeed: sessionSeed,
        scoreByWordId: progress?.scoreByWordId ?? {},
        initialScoreByWordId: progress?.initialScoreByWordId ?? {},
        finalScoreByWordId: progress?.finalScoreByWordId ?? {},
        toneScoreByWordId: progress?.toneScoreByWordId ?? {},
        feedbackByWordId: progress?.feedbackByWordId ?? {},
        recognizedTextByWordId: progress?.recognizedTextByWordId ?? {},
        completedWordIds: progress?.completedWordIds ?? {},
        lowScoreWordIds: progress?.lowScoreWordIds ?? {},
        skippedWordIds: progress?.skippedWordIds ?? {},
        isCompleted: progress?.isCompleted ?? false,
        recordDuration: Duration.zero,
        clearRecognizedText: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Không thể tải luyện nói. Vui lòng kiểm tra dữ liệu.',
      );
    }
  }

  List<WordModel> _buildSessionWords({
    required List<WordModel> topicWords,
    required int seed,
    List<String> savedWordIds = const [],
  }) {
    if (savedWordIds.isNotEmpty) {
      final wordsById = {for (final word in topicWords) word.id: word};
      final savedWords = savedWordIds
          .map((wordId) => wordsById[wordId])
          .whereType<WordModel>()
          .toList();

      if (savedWords.isNotEmpty) {
        return savedWords;
      }
    }

    final random = Random(seed);
    final shuffled = [...topicWords]..shuffle(random);
    return shuffled.take(maxQuestionCount).toList();
  }

  Future<void> speakCurrentWord() async {
    final word = state.currentWord;
    if (word == null) return;

    await _ttsRepository.speakChinese(word.hanzi);
  }

  Future<void> toggleRecording() async {
    if (state.isRecording) {
      await stopRecordingAndRecognize();
    } else {
      await startRecording();
    }
  }

  Future<void> startRecording() async {
    if (state.isRecording || state.isRecognizing) return;

    try {
      await _learningActivityRepository.markStudiedToday();

      state = state.copyWith(
        isRecording: true,
        recordDuration: Duration.zero,
        clearRecognizedText: true,
      );

      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        state = state.copyWith(
          recordDuration:
              state.recordDuration + const Duration(milliseconds: 100),
        );
      });
      final word = state.currentWord;
      if (word != null) {
        await _audioRepository.startRecording(wordId: word.id);
      }

      await _speechRepository.startListening(
        localeId: 'zh_CN',
        onResult: (text) {
          state = state.copyWith(recognizedText: text);
        },
      );
    } catch (e) {
      _recordTimer?.cancel();

      state = state.copyWith(
        isRecording: false,
        error: 'Bạn cần cấp quyền micro hoặc thiết bị chưa hỗ trợ nhận diện.',
      );
    }
  }

  Future<void> stopRecordingAndRecognize() async {
    if (!state.isRecording) return;

    await _learningActivityRepository.markStudiedToday();

    _recordTimer?.cancel();
    final audioPath = await _audioRepository.stopRecording();

    state = state.copyWith(isRecording: false, isRecognizing: true);

    final text = await _speechRepository.stopListening();

    final recognized = text.isNotEmpty ? text : state.recognizedText ?? '';

    final word = state.currentWord;

    if (word == null) {
      state = state.copyWith(isRecognizing: false, recognizedText: recognized);
      return;
    }
    if (audioPath != null && audioPath.isNotEmpty) {
      final paths = {...state.audioPathByWordId};
      paths[word.id] = audioPath;

      state = state.copyWith(audioPathByWordId: paths);
    }

    final score = calculatePronunciationScore(
      word: word,
      recognizedText: recognized,
    );

    await _saveScoreForCurrentWord(score: score, recognizedText: recognized);

    state = state.copyWith(isRecognizing: false, recognizedText: recognized);
  }

  SpeakingScore calculatePronunciationScore({
    required WordModel word,
    required String recognizedText,
  }) {
    final expectedHanzi = _normalizeText(word.hanzi);
    final expectedPinyin = _normalizePinyin(word.pinyin);
    final recognized = _normalizeText(recognizedText);
    final recognizedPinyinLike = _normalizePinyin(recognizedText);

    int totalScore;

    if (recognized.isEmpty) {
      totalScore = 0;
    } else if (recognized.contains(expectedHanzi)) {
      totalScore = 95;
    } else if (expectedHanzi.contains(recognized) && recognized.isNotEmpty) {
      totalScore = 75;
    } else {
      final hanziSimilarity = _similarity(expectedHanzi, recognized);
      final pinyinSimilarity = _similarity(
        expectedPinyin,
        recognizedPinyinLike,
      );
      totalScore = (max(hanziSimilarity, pinyinSimilarity) * 100).round();
    }

    totalScore = totalScore.clamp(0, 100);

    final initialScore = (totalScore + 4).clamp(0, 100);
    final finalScore = (totalScore - 2).clamp(0, 100);
    final toneScore = (totalScore - 4).clamp(0, 100);

    final feedback = totalScore >= 80
        ? 'Âm đầu rõ, thanh điệu khá chính xác.'
        : 'Bạn nên nghe lại mẫu và ghi âm lại.';

    return SpeakingScore(
      totalScore: totalScore,
      initialScore: initialScore,
      finalScore: finalScore,
      toneScore: toneScore,
      feedback: feedback,
    );
  }

  Future<void> _saveScoreForCurrentWord({
    required SpeakingScore score,
    required String recognizedText,
  }) async {
    final word = state.currentWord;
    if (word == null) return;

    final scores = {...state.scoreByWordId};
    final initialScores = {...state.initialScoreByWordId};
    final finalScores = {...state.finalScoreByWordId};
    final toneScores = {...state.toneScoreByWordId};
    final feedbacks = {...state.feedbackByWordId};
    final recognizedTexts = {...state.recognizedTextByWordId};

    final completed = {...state.completedWordIds};
    final lowScore = {...state.lowScoreWordIds};
    final skipped = {...state.skippedWordIds};

    scores[word.id] = score.totalScore;
    initialScores[word.id] = score.initialScore;
    finalScores[word.id] = score.finalScore;
    toneScores[word.id] = score.toneScore;
    feedbacks[word.id] = score.feedback;
    recognizedTexts[word.id] = recognizedText;

    skipped.remove(word.id);

    if (score.isGood) {
      completed.add(word.id);
      lowScore.remove(word.id);
    } else {
      lowScore.add(word.id);
      completed.remove(word.id);
    }

    state = state.copyWith(
      scoreByWordId: scores,
      initialScoreByWordId: initialScores,
      finalScoreByWordId: finalScores,
      toneScoreByWordId: toneScores,
      feedbackByWordId: feedbacks,
      recognizedTextByWordId: recognizedTexts,
      completedWordIds: completed,
      lowScoreWordIds: lowScore,
      skippedWordIds: skipped,
    );

    await saveProgress();
  }

  Future<void> replayRecording() async {
    final path = state.currentAudioPath;

    if (path == null || path.isEmpty) {
      await speakCurrentWord();
      return;
    }

    try {
      await _audioRepository.play(path);
    } catch (_) {
      await speakCurrentWord();
    }
  }

  Future<void> recordAgain() async {
    final word = state.currentWord;
    if (word == null) return;

    final scores = {...state.scoreByWordId};
    final initialScores = {...state.initialScoreByWordId};
    final finalScores = {...state.finalScoreByWordId};
    final toneScores = {...state.toneScoreByWordId};
    final feedbacks = {...state.feedbackByWordId};
    final recognizedTexts = {...state.recognizedTextByWordId};

    final completed = {...state.completedWordIds};
    final lowScore = {...state.lowScoreWordIds};
    final skipped = {...state.skippedWordIds};

    scores.remove(word.id);
    initialScores.remove(word.id);
    finalScores.remove(word.id);
    toneScores.remove(word.id);
    feedbacks.remove(word.id);
    recognizedTexts.remove(word.id);

    completed.remove(word.id);
    lowScore.remove(word.id);
    skipped.remove(word.id);

    state = state.copyWith(
      recordDuration: Duration.zero,
      scoreByWordId: scores,
      initialScoreByWordId: initialScores,
      finalScoreByWordId: finalScores,
      toneScoreByWordId: toneScores,
      feedbackByWordId: feedbacks,
      recognizedTextByWordId: recognizedTexts,
      completedWordIds: completed,
      lowScoreWordIds: lowScore,
      skippedWordIds: skipped,
      clearRecognizedText: true,
    );

    await saveProgress();
  }

  Future<void> skipCurrent() async {
    final word = state.currentWord;
    if (word == null) return;

    await _learningActivityRepository.markStudiedToday();

    final skipped = {...state.skippedWordIds};
    final completed = {...state.completedWordIds};
    final lowScore = {...state.lowScoreWordIds};

    skipped.add(word.id);
    completed.remove(word.id);
    lowScore.remove(word.id);

    state = state.copyWith(
      skippedWordIds: skipped,
      completedWordIds: completed,
      lowScoreWordIds: lowScore,
    );

    if (state.isLastQuestion) {
      await finishSpeaking();
      return;
    }

    await nextQuestion();
  }

  Future<void> nextQuestion() async {
    await _learningActivityRepository.markStudiedToday();

    if (state.isLastQuestion) {
      await finishSpeaking();
      return;
    }

    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      recordDuration: Duration.zero,
      clearRecognizedText: true,
    );

    await saveProgress();
  }

  Future<void> previousQuestion() async {
    if (state.currentIndex <= 0) return;

    state = state.copyWith(
      currentIndex: state.currentIndex - 1,
      recordDuration: Duration.zero,
      clearRecognizedText: true,
    );

    await saveProgress();
  }

  Future<void> goToQuestion(int index) async {
    if (index < 0 || index >= state.totalWords) return;

    state = state.copyWith(
      currentIndex: index,
      recordDuration: Duration.zero,
      clearRecognizedText: true,
    );

    await saveProgress();
  }

  Future<void> finishSpeaking() async {
    state = state.copyWith(
      isCompleted: true,
      completionDialogVersion: state.completionDialogVersion + 1,
    );

    await saveProgress();
  }

  Future<void> resetSpeaking() async {
    await _progressRepository.clearProgress(state.topic);

    final topicWords = await _wordRepository.getWordsByTopic(state.topic);
    final sessionSeed = DateTime.now().millisecondsSinceEpoch;

    final words = _buildSessionWords(topicWords: topicWords, seed: sessionSeed);

    state = state.copyWith(
      words: words,
      currentIndex: 0,
      sessionSeed: sessionSeed,
      recordDuration: Duration.zero,
      scoreByWordId: {},
      initialScoreByWordId: {},
      finalScoreByWordId: {},
      toneScoreByWordId: {},
      feedbackByWordId: {},
      recognizedTextByWordId: {},
      completedWordIds: {},
      lowScoreWordIds: {},
      skippedWordIds: {},
      isCompleted: false,
      clearRecognizedText: true,
    );

    await saveProgress();
  }

  Future<void> reviewLowScoreWords() async {
    final reviewIds = {...state.lowScoreWordIds, ...state.skippedWordIds};

    if (reviewIds.isEmpty) {
      await resetSpeaking();
      return;
    }

    final reviewWords = state.words
        .where((word) => reviewIds.contains(word.id))
        .toList();

    state = state.copyWith(
      words: reviewWords,
      currentIndex: 0,
      recordDuration: Duration.zero,
      scoreByWordId: {},
      initialScoreByWordId: {},
      finalScoreByWordId: {},
      toneScoreByWordId: {},
      feedbackByWordId: {},
      recognizedTextByWordId: {},
      completedWordIds: {},
      lowScoreWordIds: {},
      skippedWordIds: {},
      isCompleted: false,
      clearRecognizedText: true,
    );

    await saveProgress();
  }

  Future<void> saveProgress() async {
    await _progressRepository.saveProgress(
      topic: state.topic,
      data: SpeakingProgressData(
        currentIndex: state.currentIndex,
        sessionSeed: state.sessionSeed,
        wordIds: state.words.map((word) => word.id).toList(),
        scoreByWordId: state.scoreByWordId,
        initialScoreByWordId: state.initialScoreByWordId,
        finalScoreByWordId: state.finalScoreByWordId,
        toneScoreByWordId: state.toneScoreByWordId,
        feedbackByWordId: state.feedbackByWordId,
        recognizedTextByWordId: state.recognizedTextByWordId,
        completedWordIds: state.completedWordIds,
        lowScoreWordIds: state.lowScoreWordIds,
        skippedWordIds: state.skippedWordIds,
        isCompleted: state.isCompleted,
      ),
    );
  }

  String _normalizeText(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  String _normalizePinyin(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[āáǎà]'), 'a')
        .replaceAll(RegExp(r'[ēéěè]'), 'e')
        .replaceAll(RegExp(r'[īíǐì]'), 'i')
        .replaceAll(RegExp(r'[ōóǒò]'), 'o')
        .replaceAll(RegExp(r'[ūúǔù]'), 'u')
        .replaceAll(RegExp(r'[ǖǘǚǜü]'), 'v')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  double _similarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;

    final maxLength = max(a.length, b.length);
    final distance = _levenshteinDistance(a, b);

    return ((maxLength - distance) / maxLength).clamp(0.0, 1.0);
  }

  int _levenshteinDistance(String a, String b) {
    final matrix = List.generate(
      a.length + 1,
      (_) => List<int>.filled(b.length + 1, 0),
    );

    for (var i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }

    for (var j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;

        matrix[i][j] = min(
          min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1),
          matrix[i - 1][j - 1] + cost,
        );
      }
    }

    return matrix[a.length][b.length];
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _speechRepository.cancel();
    super.dispose();
  }
}
