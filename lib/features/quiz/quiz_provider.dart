import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/word_model.dart';
import '../../repositories/learning_activity_repository.dart';
import '../../repositories/quiz_progress_repository.dart';
import '../../repositories/word_repository.dart';
import 'quiz_state.dart';

// Provider tạo session kiểm tra và lưu tiến trình để user có thể học tiếp.
final quizProvider = StateNotifierProvider.autoDispose
    .family<QuizNotifier, QuizState, String>((ref, topic) {
      final notifier = QuizNotifier(
        topic: topic,
        wordRepository: ref.watch(wordRepositoryProvider),
        progressRepository: ref.watch(quizProgressRepositoryProvider),
        learningActivityRepository: ref.watch(
          learningActivityRepositoryProvider,
        ),
      );

      ref.onDispose(notifier.disposeTimer);

      return notifier..loadQuizByTopic();
    });

class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier({
    required String topic,
    required WordRepository wordRepository,
    required QuizProgressRepository progressRepository,
    required LearningActivityRepository learningActivityRepository,
  }) : _wordRepository = wordRepository,
       _progressRepository = progressRepository,
       _learningActivityRepository = learningActivityRepository,
       super(QuizState(topic: topic));

  static const int secondsPerQuestion = 25;
  static const int maxQuestionCount = 20;

  final WordRepository _wordRepository;
  final QuizProgressRepository _progressRepository;
  final LearningActivityRepository _learningActivityRepository;

  Timer? _timer;
  int _sessionSeed = 0;
  Future<void> loadQuizByTopic() async {
    try {
      stopTimer();

      state = state.copyWith(
        isLoading: true,
        clearError: true,
        isCompleted: false,
        remainingSeconds: secondsPerQuestion,
      );

      final topicWords = await _wordRepository.getWordsByTopic(state.topic);
      final allWords = await _wordRepository.getAllWords();

      if (topicWords.isEmpty || allWords.length < 4) {
        state = state.copyWith(
          isLoading: false,
          questions: const [],
          error: 'Chưa đủ dữ liệu để tạo quiz cho chủ đề này.',
        );
        return;
      }

      final progress = await _progressRepository.loadProgress(state.topic);

      _sessionSeed = progress?.sessionSeed ?? 0;

      if (_sessionSeed == 0 || progress?.isCompleted == true) {
        _sessionSeed = DateTime.now().millisecondsSinceEpoch;
      }

      final questions = _buildQuestions(
        topicWords: topicWords,
        allWords: allWords,
        seed: _sessionSeed,
        savedWordIds: progress?.wordIds ?? const [],
      );

      final maxIndex = questions.isEmpty ? 0 : questions.length - 1;
      final savedIndex = progress?.currentQuestionIndex ?? 0;
      final safeIndex = savedIndex.clamp(0, maxIndex);

      state = state.copyWith(
        isLoading: false,
        questions: questions,
        currentIndex: safeIndex,
        selectedAnswerIds: progress?.selectedAnswerIds ?? {},
        correctQuestionIndexes: progress?.correctQuestionIndexes ?? {},
        wrongQuestionIndexes: progress?.wrongQuestionIndexes ?? {},
        skippedQuestionIndexes: progress?.skippedQuestionIndexes ?? {},
        isCompleted: progress?.isCompleted ?? false,
        remainingSeconds: secondsPerQuestion,
      );

      if (!state.isCompleted) {
        startTimer();
      }
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Không thể tải quiz. Vui lòng kiểm tra dữ liệu.',
      );
    }
  }

  List<QuizQuestion> _buildQuestions({
    required List<WordModel> topicWords,
    required List<WordModel> allWords,
    required int seed,
    List<String> savedWordIds = const [],
  }) {
    final random = Random(seed);
    final selectedWords = _buildSessionWords(
      topicWords: topicWords,
      random: random,
      savedWordIds: savedWordIds,
    );

    final optionRandom = Random(seed);

    return selectedWords.map((word) {
      final options = _buildOptions(
        correctWord: word,
        topicWords: topicWords,
        allWords: allWords,
        random: optionRandom,
      );

      return QuizQuestion(
        id: 'quiz_${word.id}',
        correctWord: word,
        questionZh: _buildQuestionZh(word),
        questionVi: _buildQuestionVi(word),
        options: options,
      );
    }).toList();
  }

  List<WordModel> _buildSessionWords({
    required List<WordModel> topicWords,
    required Random random,
    required List<String> savedWordIds,
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

    final shuffledTopicWords = [...topicWords]..shuffle(random);

    return shuffledTopicWords.take(maxQuestionCount).toList();
  }

  List<WordModel> _buildOptions({
    required WordModel correctWord,
    required List<WordModel> topicWords,
    required List<WordModel> allWords,
    required Random random,
  }) {
    final wrongOptions = <WordModel>[];

    final sameTopicPool =
        topicWords.where((word) => word.id != correctWord.id).toList()
          ..shuffle(random);

    wrongOptions.addAll(sameTopicPool.take(3));

    if (wrongOptions.length < 3) {
      final allPool = allWords.where((word) {
        final alreadyUsed = wrongOptions.any((item) => item.id == word.id);
        return word.id != correctWord.id && !alreadyUsed;
      }).toList()..shuffle(random);

      wrongOptions.addAll(allPool.take(3 - wrongOptions.length));
    }

    final options = <WordModel>[correctWord, ...wrongOptions.take(3)];

    options.shuffle(random);

    return options;
  }

  String _buildQuestionZh(WordModel word) {
    final example = word.exampleZh.trim();

    if (example.isNotEmpty && example.contains(word.hanzi)) {
      return example.replaceFirst(word.hanzi, '_____');
    }

    return 'Từ nào có nghĩa là: ${word.meaningVi}?';
  }

  String _buildQuestionVi(WordModel word) {
    final example = word.exampleVi.trim();
    final meaning = word.meaningVi.trim();

    if (example.isNotEmpty && meaning.isNotEmpty && example.contains(meaning)) {
      return example.replaceFirst(meaning, '_____');
    }

    if (example.isNotEmpty) {
      return example;
    }

    return 'Chọn đáp án đúng.';
  }

  Future<void> selectAnswer(String wordId) async {
    if (state.isCompleted) return;

    await _learningActivityRepository.markStudiedToday();

    final selected = {...state.selectedAnswerIds};
    selected[state.currentIndex] = wordId;

    state = state.copyWith(selectedAnswerIds: selected);

    await saveProgress();
  }

  Future<void> nextQuestion() async {
    submitCurrentQuestion();

    if (state.isLastQuestion) {
      await finishQuiz();
      return;
    }

    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      remainingSeconds: secondsPerQuestion,
    );

    await saveProgress();

    startTimer();
  }

  Future<void> previousQuestion() async {
    if (state.currentIndex <= 0) return;

    state = state.copyWith(
      currentIndex: state.currentIndex - 1,
      remainingSeconds: secondsPerQuestion,
    );

    await saveProgress();

    startTimer();
  }

  Future<void> goToQuestion(int index) async {
    if (index < 0 || index >= state.totalQuestions) return;

    state = state.copyWith(
      currentIndex: index,
      remainingSeconds: secondsPerQuestion,
    );

    await saveProgress();

    startTimer();
  }

  Future<void> skipQuestion() async {
    await _learningActivityRepository.markStudiedToday();

    final skipped = {...state.skippedQuestionIndexes};
    final correct = {...state.correctQuestionIndexes};
    final wrong = {...state.wrongQuestionIndexes};
    final selected = {...state.selectedAnswerIds};

    selected.remove(state.currentIndex);
    correct.remove(state.currentIndex);
    wrong.remove(state.currentIndex);
    skipped.add(state.currentIndex);

    state = state.copyWith(
      selectedAnswerIds: selected,
      correctQuestionIndexes: correct,
      wrongQuestionIndexes: wrong,
      skippedQuestionIndexes: skipped,
    );

    if (state.isLastQuestion) {
      await finishQuiz();
      return;
    }

    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      remainingSeconds: secondsPerQuestion,
    );

    await saveProgress();

    startTimer();
  }

  void submitCurrentQuestion() {
    final question = state.currentQuestion;
    if (question == null) return;

    final selectedWordId = state.selectedAnswerIds[state.currentIndex];

    final correct = {...state.correctQuestionIndexes};
    final wrong = {...state.wrongQuestionIndexes};
    final skipped = {...state.skippedQuestionIndexes};

    correct.remove(state.currentIndex);
    wrong.remove(state.currentIndex);
    skipped.remove(state.currentIndex);

    if (selectedWordId == null) {
      skipped.add(state.currentIndex);
    } else if (selectedWordId == question.correctWordId) {
      correct.add(state.currentIndex);
    } else {
      wrong.add(state.currentIndex);
    }

    state = state.copyWith(
      correctQuestionIndexes: correct,
      wrongQuestionIndexes: wrong,
      skippedQuestionIndexes: skipped,
    );
  }

  Future<void> finishQuiz() async {
    submitCurrentQuestion();
    stopTimer();

    state = state.copyWith(
      isCompleted: true,
      completionDialogVersion: state.completionDialogVersion + 1,
    );

    await saveProgress();
  }

  Future<void> resetQuiz() async {
    stopTimer();

    await _progressRepository.clearProgress(state.topic);

    _sessionSeed = DateTime.now().millisecondsSinceEpoch;

    final topicWords = await _wordRepository.getWordsByTopic(state.topic);
    final allWords = await _wordRepository.getAllWords();

    final questions = _buildQuestions(
      topicWords: topicWords,
      allWords: allWords,
      seed: _sessionSeed,
    );

    state = state.copyWith(
      questions: questions,
      currentIndex: 0,
      remainingSeconds: secondsPerQuestion,
      selectedAnswerIds: {},
      correctQuestionIndexes: {},
      wrongQuestionIndexes: {},
      skippedQuestionIndexes: {},
      isCompleted: false,
    );

    await saveProgress();

    startTimer();
  }

  Future<void> reviewWrongQuestions() async {
    final reviewIndexes = {
      ...state.wrongQuestionIndexes,
      ...state.skippedQuestionIndexes,
    }.toList()..sort();

    if (reviewIndexes.isEmpty) {
      await resetQuiz();
      return;
    }

    final reviewQuestions = reviewIndexes
        .where((index) => index >= 0 && index < state.questions.length)
        .map((index) => state.questions[index])
        .toList();

    state = state.copyWith(
      questions: reviewQuestions,
      currentIndex: 0,
      remainingSeconds: secondsPerQuestion,
      selectedAnswerIds: {},
      correctQuestionIndexes: {},
      wrongQuestionIndexes: {},
      skippedQuestionIndexes: {},
      isCompleted: false,
    );

    await saveProgress();

    startTimer();
  }

  void startTimer() {
    stopTimer();

    if (state.isCompleted || state.questions.isEmpty) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (state.remainingSeconds <= 1) {
        await skipQuestion();
        return;
      }

      state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
    });
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void disposeTimer() {
    stopTimer();
  }

  Future<void> saveProgress() async {
    await _progressRepository.saveProgress(
      topic: state.topic,
      data: QuizProgressData(
        currentQuestionIndex: state.currentIndex,
        wordIds: state.questions
            .map((question) => question.correctWord.id)
            .toList(),
        selectedAnswerIds: state.selectedAnswerIds,
        correctQuestionIndexes: state.correctQuestionIndexes,
        wrongQuestionIndexes: state.wrongQuestionIndexes,
        skippedQuestionIndexes: state.skippedQuestionIndexes,
        isCompleted: state.isCompleted,
        sessionSeed: _sessionSeed,
      ),
    );
  }
}
