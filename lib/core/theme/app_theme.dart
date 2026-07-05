import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // =========================
  // COLORS
  // =========================

  /// Màu đỏ chính dùng cho heading, icon active, nút chính.
  static const Color primary = Color(0xFFC0272D);

  /// Đỏ đậm hơn, dùng khi cần nhấn mạnh hoặc shadow nhẹ.
  static const Color primaryDark = Color(0xFFA51B22);

  /// Đỏ nhạt dùng cho progress track, badge, nền phụ.
  static const Color primaryLight = Color(0xFFE8A0A2);

  /// Nền chính toàn app: kem hồng rất nhạt.
  static const Color background = Color(0xFFFDF0EC);

  /// Nền card, input, bottom nav.
  static const Color surface = Color(0xFFFFFFFF);

  /// Text chính.
  static const Color textPrimary = Color(0xFF1A1A1A);

  /// Text phụ, placeholder, inactive label.
  static const Color textSecondary = Color(0xFF888888);

  /// Text đỏ dùng cho pinyin, active label.
  static const Color textRed = primary;

  /// Màu đúng / kết quả tốt.
  static const Color success = Color(0xFF4CAF50);

  /// Màu nền chip/tag.
  static const Color tagBg = Color(0xFFFDE8E8);

  /// Màu nền bottom navigation.
  static const Color navBg = Color(0xFFFFFFFF);

  /// Border nhẹ trong input, option, card phụ.
  static const Color border = Color(0xFFE8DAD5);

  /// Border đậm hơn một chút.
  static const Color borderMedium = Color(0xFFE0CFC9);

  /// Màu inactive icon.
  static const Color iconInactive = Color(0xFF7D716E);

  /// Nền icon tròn nhạt.
  static const Color iconSoftBg = Color(0xFFFFF1EE);

  /// Nền pill nhạt.
  static const Color pillBg = Color(0xFFFFE9E3);

  /// Nền progress track.
  static const Color progressTrack = Color(0xFFE8A0A2);

  /// Màu shadow rất nhẹ.
  static const Color shadow = Color(0x14000000);

  /// Màu overlay của núi/mây/hoa trang trí.
  static const Color decorationSoft = Color(0x1AC0272D);

  // =========================
  // TEXT STYLES
  // =========================

  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: primary,
    height: 1.25,
    letterSpacing: 0.2,
  );

  static const TextStyle headingXLarge = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    color: primary,
    height: 1.15,
    letterSpacing: 0.4,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: primary,
    height: 1.3,
    letterSpacing: 0.2,
  );

  static const TextStyle appBarTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: primary,
    height: 1.2,
    letterSpacing: 0.3,
  );

  static const TextStyle hanziLarge = TextStyle(
    fontSize: 52,
    fontWeight: FontWeight.bold,
    color: primary,
    height: 1.1,
  );

  static const TextStyle hanziMedium = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    color: primary,
    height: 1.15,
  );

  static const TextStyle hanziSmall = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    color: primary,
    height: 1.2,
  );

  static const TextStyle pinyin = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: primary,
    height: 1.35,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.45,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.35,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle subtitleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle tag = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: primary,
    height: 1.2,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    height: 1.2,
  );

  static const TextStyle navLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  static const TextStyle progressNumber = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primary,
    height: 1.2,
  );

  // =========================
  // BORDER RADIUS
  // =========================

  static const double radiusCard = 16;
  static const double radiusCardLarge = 24;
  static const double radiusButton = 28;
  static const double radiusButtonSmall = 20;
  static const double radiusInput = 12;
  static const double radiusTag = 20;
  static const double radiusAppBarButton = 12;
  static const double radiusTopicCard = 16;
  static const double radiusBottomNav = 20;

  static BorderRadius get cardRadius => BorderRadius.circular(radiusCard);

  static BorderRadius get cardLargeRadius =>
      BorderRadius.circular(radiusCardLarge);

  static BorderRadius get buttonRadius => BorderRadius.circular(radiusButton);

  static BorderRadius get buttonSmallRadius =>
      BorderRadius.circular(radiusButtonSmall);

  static BorderRadius get inputRadius => BorderRadius.circular(radiusInput);

  static BorderRadius get tagRadius => BorderRadius.circular(radiusTag);

  static BorderRadius get appBarButtonRadius =>
      BorderRadius.circular(radiusAppBarButton);

  static BorderRadius get topicCardRadius =>
      BorderRadius.circular(radiusTopicCard);

  static const BorderRadius bottomNavRadius = BorderRadius.only(
    topLeft: Radius.circular(radiusBottomNav),
    topRight: Radius.circular(radiusBottomNav),
  );

  // =========================
  // SPACING
  // =========================

  static const double spacing2 = 2;
  static const double spacing4 = 4;
  static const double spacing6 = 6;
  static const double spacing8 = 8;
  static const double spacing10 = 10;
  static const double spacing12 = 12;
  static const double spacing14 = 14;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing28 = 28;
  static const double spacing32 = 32;
  static const double spacing40 = 40;

  /// Padding ngang chuẩn toàn màn.
  static const double screenPadding = 16;

  /// Khoảng cách giữa các card.
  static const double cardGap = 12;

  /// Padding trong card.
  static const double cardPadding = 16;

  /// Icon size bottom nav.
  static const double bottomNavIconSize = 24;

  /// Chiều cao nút chính.
  static const double primaryButtonHeight = 56;

  /// Size nút appbar.
  static const double appBarButtonSize = 48;

  static const EdgeInsets screenHorizontalPadding = EdgeInsets.symmetric(
    horizontal: screenPadding,
  );

  static const EdgeInsets screenPaddingAll = EdgeInsets.all(screenPadding);

  static const EdgeInsets cardPaddingAll = EdgeInsets.all(cardPadding);

  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 14,
  );

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );

  static const EdgeInsets tagPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );

  // =========================
  // SHADOWS
  // =========================

  static const List<BoxShadow> softShadow = [
    BoxShadow(color: shadow, blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> redShadow = [
    BoxShadow(color: Color(0x33C0272D), blurRadius: 18, offset: Offset(0, 8)),
  ];

  // =========================
  // COMMON DECORATIONS
  // =========================

  static BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: cardRadius,
    boxShadow: cardShadow,
  );

  static BoxDecoration largeCardDecoration = BoxDecoration(
    color: surface,
    borderRadius: cardLargeRadius,
    boxShadow: softShadow,
  );

  static BoxDecoration tagDecoration = BoxDecoration(
    color: tagBg,
    borderRadius: tagRadius,
  );

  static BoxDecoration primaryButtonDecoration = BoxDecoration(
    color: primary,
    borderRadius: buttonRadius,
    boxShadow: redShadow,
  );

  static BoxDecoration inputDecoration = BoxDecoration(
    color: surface,
    borderRadius: inputRadius,
    border: Border.all(color: border),
  );

  // =========================
  // THEME DATA
  // =========================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: null,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primaryLight,
        surface: surface,
        error: primary,
        onPrimary: Colors.white,
        onSecondary: textPrimary,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: appBarTitle,
        iconTheme: IconThemeData(color: primary, size: 22),
      ),
      textTheme: const TextTheme(
        headlineLarge: headingLarge,
        headlineMedium: headingMedium,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: subtitle,
        labelSmall: tag,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: inputPadding,
        border: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: subtitleMedium,
      ),
    );
  }
}
