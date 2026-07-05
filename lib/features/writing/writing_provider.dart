import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/word_model.dart';
import '../../repositories/handwriting_recognition_repository.dart';
import '../../repositories/learning_activity_repository.dart';
import '../../repositories/tts_repository.dart';
import '../../repositories/word_repository.dart';
import '../../repositories/writing_progress_repository.dart';
import 'writing_state.dart';

final writingProvider = StateNotifierProvider.autoDispose
    .family<WritingNotifier, WritingState, String>((ref, topic) {
      return WritingNotifier(
        topic: topic,
        wordRepository: ref.watch(wordRepositoryProvider),
        progressRepository: ref.watch(writingProgressRepositoryProvider),
        recognitionRepository: ref.watch(
          handwritingRecognitionRepositoryProvider,
        ),
        ttsRepository: ref.watch(ttsRepositoryProvider),
        learningActivityRepository: ref.watch(
          learningActivityRepositoryProvider,
        ),
      )..loadWritingByTopic();
    });

class WritingNotifier extends StateNotifier<WritingState> {
  WritingNotifier({
    required String topic,
    required WordRepository wordRepository,
    required WritingProgressRepository progressRepository,
    required HandwritingRecognitionRepository recognitionRepository,
    required TtsRepository ttsRepository,
    required LearningActivityRepository learningActivityRepository,
  }) : _wordRepository = wordRepository,
       _progressRepository = progressRepository,
       _recognitionRepository = recognitionRepository,
       _ttsRepository = ttsRepository,
       _learningActivityRepository = learningActivityRepository,
       super(WritingState(topic: topic));

  static const int maxWordCount = 20;

  final WordRepository _wordRepository;
  final WritingProgressRepository _progressRepository;
  final HandwritingRecognitionRepository _recognitionRepository;
  final TtsRepository _ttsRepository;
  final LearningActivityRepository _learningActivityRepository;

  Future<void> loadWritingByTopic() async {
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
          error: 'Chưa có ký tự cho chủ đề này.',
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

      final maxWordIndex = words.isEmpty ? 0 : words.length - 1;
      final savedWordIndex = progress?.currentIndex ?? 0;
      final safeWordIndex = savedWordIndex.clamp(0, maxWordIndex);

      final maxCharIndex = words.isEmpty
          ? 0
          : words[safeWordIndex].hanzi.characters.length - 1;

      final savedCharIndex = progress?.currentCharIndex ?? 0;
      final safeCharIndex = savedCharIndex.clamp(0, maxCharIndex);

      state = state.copyWith(
        isLoading: false,
        words: words,
        currentIndex: safeWordIndex,
        currentCharIndex: safeCharIndex,
        sessionSeed: sessionSeed,
        completedCharIds: progress?.completedCharIds ?? {},
        wrongCharIds: progress?.wrongCharIds ?? {},
        skippedCharIds: progress?.skippedCharIds ?? {},
        attemptCountByCharId: progress?.attemptCountByCharId ?? {},
        isCompleted: progress?.isCompleted ?? false,
        strokes: const [],
        showAnswer: false,
        clearRecognizedText: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Không thể tải luyện viết. Vui lòng kiểm tra dữ liệu.',
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

    return shuffled.take(maxWordCount).toList();
  }

  Future<void> selectCharacter(int index) async {
    final chars = state.currentCharacters;

    if (index < 0 || index >= chars.length) return;

    state = state.copyWith(
      currentCharIndex: index,
      strokes: const [],
      showAnswer: false,
      clearRecognizedText: true,
    );

    await saveProgress();
  }

  void startStroke(Offset point) {
    if (state.isCompleted) return;

    final strokes = state.strokes.map((stroke) => [...stroke]).toList();
    strokes.add([point]);

    state = state.copyWith(strokes: strokes, clearRecognizedText: true);
  }

  void addStrokePoint(Offset point) {
    if (state.isCompleted || state.strokes.isEmpty) return;

    final strokes = state.strokes.map((stroke) => [...stroke]).toList();
    strokes.last.add(point);

    state = state.copyWith(strokes: strokes);
  }

  void endStroke() {}

  void clearCanvas() {
    state = state.copyWith(strokes: const [], clearRecognizedText: true);
  }

  void rewriteCurrent() {
    clearCanvas();
  }

  void toggleShowAnswer() {
    state = state.copyWith(showAnswer: !state.showAnswer);
  }

  Future<void> speakCurrentWord() async {
    final word = state.currentWord;
    if (word == null) return;

    await _ttsRepository.speakChinese(word.hanzi);
  }

  Future<void> speakCurrentCharacter() async {
    final character = state.currentCharacter;
    if (character == null) return;

    await _ttsRepository.speakChinese(character);
  }

  Future<void> recognizeCurrentWriting() async {
    final character = state.currentCharacter;

    if (character == null || state.isRecognizing) return;

    if (state.strokes.isEmpty) {
      state = state.copyWith(
        recognizedText: 'Hãy viết chữ trước khi kiểm tra.',
      );
      return;
    }

    await _learningActivityRepository.markStudiedToday();

    state = state.copyWith(isRecognizing: true, clearRecognizedText: true);

    final result = await _recognitionRepository.recognizeChinese(
      strokes: state.strokes,
      expectedText: character,
    );

    final best = result.bestCandidate;

    state = state.copyWith(
      isRecognizing: false,
      recognizedText: best ?? 'Chưa nhận diện được chữ viết.',
    );

    if (best == null) {
      return;
    }

    if (best == character) {
      await markCorrectAndNext();
    } else {
      await markWrong();
    }
  }

  Future<void> markCorrectAndNext() async {
    final charId = state.currentCharId;
    if (charId == null) return;

    final completed = {...state.completedCharIds};
    final wrong = {...state.wrongCharIds};
    final skipped = {...state.skippedCharIds};

    completed.add(charId);
    wrong.remove(charId);
    skipped.remove(charId);

    if (!state.isLastCharacterInWord) {
      state = state.copyWith(
        completedCharIds: completed,
        wrongCharIds: wrong,
        skippedCharIds: skipped,
        currentCharIndex: state.currentCharIndex + 1,
        strokes: const [],
        showAnswer: false,
        clearRecognizedText: true,
      );

      await saveProgress();
      return;
    }

    if (state.isLastWord) {
      state = state.copyWith(
        completedCharIds: completed,
        wrongCharIds: wrong,
        skippedCharIds: skipped,
        isCompleted: true,
        completionDialogVersion: state.completionDialogVersion + 1,
      );

      await saveProgress();
      return;
    }

    state = state.copyWith(
      completedCharIds: completed,
      wrongCharIds: wrong,
      skippedCharIds: skipped,
      currentIndex: state.currentIndex + 1,
      currentCharIndex: 0,
      strokes: const [],
      showAnswer: false,
      clearRecognizedText: true,
    );

    await saveProgress();
  }

  Future<void> markWrong() async {
    final charId = state.currentCharId;
    if (charId == null) return;

    final wrong = {...state.wrongCharIds};
    final completed = {...state.completedCharIds};
    final attempts = {...state.attemptCountByCharId};

    wrong.add(charId);
    completed.remove(charId);
    attempts[charId] = (attempts[charId] ?? 0) + 1;

    state = state.copyWith(
      wrongCharIds: wrong,
      completedCharIds: completed,
      attemptCountByCharId: attempts,
    );

    await saveProgress();
  }

  Future<void> skipCurrent() async {
    final charId = state.currentCharId;
    if (charId == null) return;

    await _learningActivityRepository.markStudiedToday();

    final skipped = {...state.skippedCharIds};
    final completed = {...state.completedCharIds};
    final wrong = {...state.wrongCharIds};

    skipped.add(charId);
    completed.remove(charId);
    wrong.remove(charId);

    if (!state.isLastCharacterInWord) {
      state = state.copyWith(
        skippedCharIds: skipped,
        completedCharIds: completed,
        wrongCharIds: wrong,
        currentCharIndex: state.currentCharIndex + 1,
        strokes: const [],
        showAnswer: false,
        clearRecognizedText: true,
      );

      await saveProgress();
      return;
    }

    if (state.isLastWord) {
      state = state.copyWith(
        skippedCharIds: skipped,
        completedCharIds: completed,
        wrongCharIds: wrong,
        isCompleted: true,
        completionDialogVersion: state.completionDialogVersion + 1,
      );

      await saveProgress();
      return;
    }

    state = state.copyWith(
      skippedCharIds: skipped,
      completedCharIds: completed,
      wrongCharIds: wrong,
      currentIndex: state.currentIndex + 1,
      currentCharIndex: 0,
      strokes: const [],
      showAnswer: false,
      clearRecognizedText: true,
    );

    await saveProgress();
  }

  Future<void> nextWord() async {
    await _learningActivityRepository.markStudiedToday();

    if (state.isLastWord) {
      await finishWriting();
      return;
    }

    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      currentCharIndex: 0,
      strokes: const [],
      showAnswer: false,
      clearRecognizedText: true,
    );

    await saveProgress();
  }

  Future<void> previousWord() async {
    if (state.currentIndex <= 0) return;

    state = state.copyWith(
      currentIndex: state.currentIndex - 1,
      currentCharIndex: 0,
      strokes: const [],
      showAnswer: false,
      clearRecognizedText: true,
    );

    await saveProgress();
  }

  Future<void> goToWord(int index) async {
    if (index < 0 || index >= state.totalWords) return;

    state = state.copyWith(
      currentIndex: index,
      currentCharIndex: 0,
      strokes: const [],
      showAnswer: false,
      clearRecognizedText: true,
    );

    await saveProgress();
  }

  Future<void> finishWriting() async {
    state = state.copyWith(
      isCompleted: true,
      completionDialogVersion: state.completionDialogVersion + 1,
    );

    await saveProgress();
  }

  Future<void> resetWriting() async {
    await _progressRepository.clearProgress(state.topic);

    final topicWords = await _wordRepository.getWordsByTopic(state.topic);
    final sessionSeed = DateTime.now().millisecondsSinceEpoch;

    final words = _buildSessionWords(topicWords: topicWords, seed: sessionSeed);

    state = state.copyWith(
      words: words,
      currentIndex: 0,
      currentCharIndex: 0,
      sessionSeed: sessionSeed,
      completedCharIds: {},
      wrongCharIds: {},
      skippedCharIds: {},
      attemptCountByCharId: {},
      strokes: const [],
      showAnswer: false,
      isCompleted: false,
      clearRecognizedText: true,
    );

    await saveProgress();
  }

  Future<void> reviewWrongWords() async {
    final reviewIds = {...state.wrongCharIds, ...state.skippedCharIds};

    if (reviewIds.isEmpty) {
      await resetWriting();
      return;
    }

    final reviewWords = <WordModel>[];

    for (var wordIndex = 0; wordIndex < state.words.length; wordIndex++) {
      final charIds = state.charIdsOfWord(wordIndex);

      final shouldReview = charIds.any(reviewIds.contains);

      if (shouldReview) {
        reviewWords.add(state.words[wordIndex]);
      }
    }

    state = state.copyWith(
      words: reviewWords,
      currentIndex: 0,
      currentCharIndex: 0,
      completedCharIds: {},
      wrongCharIds: {},
      skippedCharIds: {},
      attemptCountByCharId: {},
      strokes: const [],
      showAnswer: false,
      isCompleted: false,
      clearRecognizedText: true,
    );

    await saveProgress();
  }

  Future<void> saveProgress() async {
    await _progressRepository.saveProgress(
      topic: state.topic,
      data: WritingProgressData(
        currentIndex: state.currentIndex,
        currentCharIndex: state.currentCharIndex,
        sessionSeed: state.sessionSeed,
        wordIds: state.words.map((word) => word.id).toList(),
        completedCharIds: state.completedCharIds,
        wrongCharIds: state.wrongCharIds,
        skippedCharIds: state.skippedCharIds,
        attemptCountByCharId: state.attemptCountByCharId,
        isCompleted: state.isCompleted,
      ),
    );
  }
}
