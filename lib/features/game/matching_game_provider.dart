import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/word_model.dart';
import '../../repositories/learning_activity_repository.dart';
import '../../repositories/matching_game_progress_repository.dart';
import '../../repositories/word_repository.dart';
import 'matching_game_state.dart';

final matchingGameProvider = StateNotifierProvider.autoDispose
    .family<MatchingGameNotifier, MatchingGameState, String?>((ref, topic) {
      final notifier = MatchingGameNotifier(
        topic: topic,
        wordRepository: ref.watch(wordRepositoryProvider),
        progressRepository: ref.watch(matchingGameProgressRepositoryProvider),
        learningActivityRepository: ref.watch(
          learningActivityRepositoryProvider,
        ),
      );

      ref.onDispose(notifier.dispose);

      return notifier..loadGame();
    });

class MatchingGameNotifier extends StateNotifier<MatchingGameState> {
  MatchingGameNotifier({
    required String? topic,
    required WordRepository wordRepository,
    required MatchingGameProgressRepository progressRepository,
    required LearningActivityRepository learningActivityRepository,
  }) : _wordRepository = wordRepository,
       _progressRepository = progressRepository,
       _learningActivityRepository = learningActivityRepository,
       super(MatchingGameState(topic: topic));

  final WordRepository _wordRepository;
  final MatchingGameProgressRepository _progressRepository;
  final LearningActivityRepository _learningActivityRepository;

  Timer? _timer;
  final Random _random = Random();

  Future<void> loadGame() async {
    try {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        elapsedSeconds: 0,
        isCompleted: false,
      );

      final words = await _loadWords();

      if (words.length < 4) {
        state = state.copyWith(
          isLoading: false,
          selectedWords: words,
          error: 'Chủ đề này chưa đủ từ để chơi.',
        );
        return;
      }

      _generateRoundFromWords(words);

      await _progressRepository.saveRoundStarted(topic: state.topic);

      _startTimer();
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Không thể tải game nối từ.',
      );
    }
  }

  Future<List<WordModel>> _loadWords() async {
    final topic = state.topic;

    if (topic != null && topic.trim().isNotEmpty) {
      return _wordRepository.getWordsByTopic(topic);
    }

    return _wordRepository.getAllWords();
  }

  void _generateRoundFromWords(List<WordModel> sourceWords) {
    final words = [...sourceWords]..shuffle(_random);
    final selected = words.take(4).toList();

    final hanziItems =
        selected
            .map(
              (word) => MatchingItem(
                wordId: word.id,
                text: word.hanzi,
                type: MatchingItemType.hanzi,
              ),
            )
            .toList()
          ..shuffle(_random);

    final meaningItems =
        selected
            .map(
              (word) => MatchingItem(
                wordId: word.id,
                text: word.meaningVi,
                type: MatchingItemType.meaning,
              ),
            )
            .toList()
          ..shuffle(_random);

    state = state.copyWith(
      isLoading: false,
      selectedWords: selected,
      hanziItems: hanziItems,
      meaningItems: meaningItems,
      clearSelectedHanziId: true,
      clearSelectedMeaningId: true,
      matchedWordIds: {},
      clearWrongHanziId: true,
      clearWrongMeaningId: true,
      clearHintWordId: true,
      hintCount: 3,
      elapsedSeconds: 0,
      isCompleted: false,
      clearError: true,
    );
  }

  Future<void> selectHanzi(String wordId) async {
    if (state.isCompleted || state.isMatched(wordId)) return;

    state = state.copyWith(
      selectedHanziId: wordId,
      clearWrongHanziId: true,
      clearWrongMeaningId: true,
      clearHintWordId: true,
    );

    await _checkSelectedPair();
  }

  Future<void> selectMeaning(String wordId) async {
    if (state.isCompleted || state.isMatched(wordId)) return;

    state = state.copyWith(
      selectedMeaningId: wordId,
      clearWrongHanziId: true,
      clearWrongMeaningId: true,
      clearHintWordId: true,
    );

    await _checkSelectedPair();
  }

  Future<void> _checkSelectedPair() async {
    final hanziId = state.selectedHanziId;
    final meaningId = state.selectedMeaningId;

    if (hanziId == null || meaningId == null) return;

    await _learningActivityRepository.markStudiedToday();

    if (hanziId == meaningId) {
      final matched = {...state.matchedWordIds, hanziId};

      state = state.copyWith(
        matchedWordIds: matched,
        clearSelectedHanziId: true,
        clearSelectedMeaningId: true,
        clearWrongHanziId: true,
        clearWrongMeaningId: true,
      );

      if (matched.length == state.totalPairs) {
        finishGame();
      }

      return;
    }

    state = state.copyWith(wrongHanziId: hanziId, wrongMeaningId: meaningId);

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      clearWrongSelection();
    });
  }

  void clearWrongSelection() {
    state = state.copyWith(
      clearSelectedHanziId: true,
      clearSelectedMeaningId: true,
      clearWrongHanziId: true,
      clearWrongMeaningId: true,
    );
  }

  void useHint() {
    if (state.hintCount <= 0 || state.isCompleted) return;

    final remaining = state.selectedWords
        .where((word) => !state.matchedWordIds.contains(word.id))
        .toList();

    if (remaining.isEmpty) return;

    final word = remaining.first;

    state = state.copyWith(
      hintCount: state.hintCount - 1,
      hintWordId: word.id,
      selectedHanziId: word.id,
      selectedMeaningId: word.id,
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      state = state.copyWith(
        clearHintWordId: true,
        clearSelectedHanziId: true,
        clearSelectedMeaningId: true,
      );
    });
  }

  Future<void> resetRound() async {
    _stopTimer();

    final words = await _loadWords();

    if (words.length < 4) {
      state = state.copyWith(
        selectedWords: words,
        error: 'Chủ đề này chưa đủ từ để chơi.',
      );
      return;
    }

    _generateRoundFromWords(words);

    await _progressRepository.saveRoundStarted(topic: state.topic);

    _startTimer();
  }

  Future<void> finishGame() async {
    _stopTimer();

    state = state.copyWith(
      isCompleted: true,
      completionDialogVersion: state.completionDialogVersion + 1,
    );

    await _progressRepository.saveRoundWon(
      topic: state.topic,
      elapsedSeconds: state.elapsedSeconds,
      correctPairs: state.score,
    );
  }

  void _startTimer() {
    _stopTimer();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isCompleted) return;

      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
