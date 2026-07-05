import 'package:firebase_auth/firebase_auth.dart';
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
import '../../features/writing/writing_screen.dart';
import '../../features/game/matching_game_screen.dart';
import '../../features/auth/auth_gate.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/auth/register_screen.dart';

// Khai báo toàn bộ route tập trung để screen không hardcode đường dẫn.
class AppRoutes {
  // Private named constructor nhằm ngăn chặn việc Instantiation (khởi tạo thực thể).
  // Đảm bảo class AppRoutes hoạt động thuần túy như một tiện  Class chứa hằng số.
  //Constructor riêng tư để ngăn tạo đối tượng.
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
  static const gameTopics = '/game/topics';
  static const game = '/game';

  static const authGate = '/auth-gate';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
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
  static const gameTopics = 'gameTopics';
  static const game = 'game';

  static const authGate = 'authGate';
  static const onboarding = 'onboarding';
  static const login = 'login';
  static const register = 'register';
}

// Lớp quản lý toàn bộ cấu hình điều hướng của ứng dụng.
// Constructor private để ngăn tạo đối tượng.
class AppRouter {
  AppRouter._();
// Danh sách các trang công khai.
// Người dùng chưa đăng nhập vẫn có thể truy cập.
  // Auth guard(bộ bảo vệ xác ) đơn giản: route học yêu cầu user Firebase đã đăng nhập.
  static const Set<String> _publicRoutes = {
    AppRoutes.authGate,
    AppRoutes.onboarding,
    AppRoutes.login,
    AppRoutes.register,
  };
  // Router chính của ứng dụng.
  static final GoRouter router = GoRouter(
    // Trang đầu tiên được mở khi khởi động ứng dụng.
    initialLocation: AppRoutes.authGate,
    redirect: (context, state) {

      // Đường dẫn (URL) của trang người dùng đang muốn truy cập.
      final path = state.uri.path;

      // Kiểm tra trang hiện tại có phải là trang công khai hay không.
      final isPublicRoute = _publicRoutes.contains(path);

      // Kiểm tra người dùng đã đăng nhập Firebase hay chưa.
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;

      // Nếu chưa đăng nhập nhưng cố truy cập trang yêu cầu đăng nhập,chuyển về AuthGate.
      if (!isLoggedIn && !isPublicRoute) {
        return AppRoutes.authGate;
      }
      
     // Nếu đã đăng nhập mà truy cập trang công khai (Login, Register...), chuyển về trang chủ.
      if (isLoggedIn && isPublicRoute) {
        return AppRoutes.home;
      }

      // Không cần chuyển hướng. Cho phép truy cập trang yêu cầu.
      return null;
    },
    // Danh sách tất cả các route trong ứng dụng.
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: AppRouteNames.home,
        // Widget sẽ được hiển thị khi truy cập route này.
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
        redirect: (context, state) => AppRoutes.search,
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
        builder: (context, state) {
          final topic = state.uri.queryParameters['topic'] ?? '';
          return QuizScreen(topic: topic);
        },
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
        builder: (context, state) {
          final topic = state.uri.queryParameters['topic'] ?? '';
          return WritingScreen(topic: topic);
        },
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
        builder: (context, state) {
          final topic = state.uri.queryParameters['topic'] ?? '';
          return SpeakingScreen(topic: topic);
        },
      ),

      GoRoute(
        path: AppRoutes.translate,
        name: AppRouteNames.translate,
        redirect: (context, state) => AppRoutes.gameTopics,
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
      /////game
      GoRoute(
        path: AppRoutes.gameTopics,
        name: AppRouteNames.gameTopics,
        builder: (context, state) {
          return const TopicSelectScreen(mode: TopicSelectMode.game);
        },
      ),
      GoRoute(
        path: AppRoutes.game,
        name: AppRouteNames.game,
        builder: (context, state) {
          final topic = state.uri.queryParameters['topic'];
          return MatchingGameScreen(topic: topic);
        },
      ),

      ///////////auth
      GoRoute(
        path: AppRoutes.authGate,
        name: AppRouteNames.authGate,
        builder: (context, state) => const AuthGate(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: AppRouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
    ],
  );
}
