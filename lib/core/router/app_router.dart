import 'package:go_router/go_router.dart';

import '../../features/account/account_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/flashcard/flashcard_screen.dart';
import '../../features/flashcard/topic_select_provider.dart';
import '../../features/flashcard/topic_select_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/quiz/quiz_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/speaking/speaking_screen.dart';
import '../../features/translate/translate_screen.dart';
import '../../features/vocabulary/vocab_screen.dart';
import '../../features/writing/writing_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const home = '/';
  static const search = '/search';
  static const vocabulary = '/vocabulary';

  static const flashcardTopics = '/flashcard/topics';
  static const flashcard = '/flashcard';

  static const quizTopics = '/quiz/topics';
  static const quiz = '/quiz';

  static const writingTopics = '/writing/topics';
  static const writing = '/writing';

  static const speakingTopics = '/speaking/topics';
  static const speaking = '/speaking';

  static const translate = '/translate';
  static const favorites = '/favorites';
  static const account = '/account';
}

class AppRouteNames {
  AppRouteNames._();

  static const home = 'home';
  static const search = 'search';
  static const vocabulary = 'vocabulary';

  static const flashcardTopics = 'flashcardTopics';
  static const flashcard = 'flashcard';

  static const quizTopics = 'quizTopics';
  static const quiz = 'quiz';

  static const writingTopics = 'writingTopics';
  static const writing = 'writing';

  static const speakingTopics = 'speakingTopics';
  static const speaking = 'speaking';

  static const translate = 'translate';
  static const favorites = 'favorites';
  static const account = 'account';
}

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: AppRouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),

      GoRoute(
        path: AppRoutes.search,
        name: AppRouteNames.search,
        builder: (context, state) => const SearchScreen(),
      ),

      GoRoute(
        path: AppRoutes.vocabulary,
        name: AppRouteNames.vocabulary,
        builder: (context, state) => const VocabScreen(),
      ),

      // =========================
      // FLASHCARD
      // =========================
      GoRoute(
        path: AppRoutes.flashcardTopics,
        name: AppRouteNames.flashcardTopics,
        builder: (context, state) =>
            const TopicSelectScreen(mode: TopicSelectMode.flashcard),
      ),
      GoRoute(
        path: AppRoutes.flashcard,
        name: AppRouteNames.flashcard,
        builder: (context, state) {
          final topic = state.uri.queryParameters['topic'] ?? '';

          return FlashcardScreen(topic: topic);
        },
      ),

      // =========================
      // QUIZ
      // =========================
      GoRoute(
        path: AppRoutes.quizTopics,
        name: AppRouteNames.quizTopics,
        builder: (context, state) =>
            const TopicSelectScreen(mode: TopicSelectMode.quiz),
      ),
      GoRoute(
        path: AppRoutes.quiz,
        name: AppRouteNames.quiz,
        builder: (context, state) => const QuizScreen(),
      ),

      // =========================
      // WRITING
      // =========================
      GoRoute(
        path: AppRoutes.writingTopics,
        name: AppRouteNames.writingTopics,
        builder: (context, state) =>
            const TopicSelectScreen(mode: TopicSelectMode.writing),
      ),
      GoRoute(
        path: AppRoutes.writing,
        name: AppRouteNames.writing,
        builder: (context, state) => const WritingScreen(),
      ),

      // =========================
      // SPEAKING
      // =========================
      GoRoute(
        path: AppRoutes.speakingTopics,
        name: AppRouteNames.speakingTopics,
        builder: (context, state) =>
            const TopicSelectScreen(mode: TopicSelectMode.speaking),
      ),
      GoRoute(
        path: AppRoutes.speaking,
        name: AppRouteNames.speaking,
        builder: (context, state) => const SpeakingScreen(),
      ),

      GoRoute(
        path: AppRoutes.translate,
        name: AppRouteNames.translate,
        builder: (context, state) => const TranslateScreen(),
      ),

      GoRoute(
        path: AppRoutes.favorites,
        name: AppRouteNames.favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),

      GoRoute(
        path: AppRoutes.account,
        name: AppRouteNames.account,
        builder: (context, state) => const AccountScreen(),
      ),
    ],
  );
}
