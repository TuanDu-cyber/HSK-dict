import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'repositories/notification_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo dịch vụ nền trước khi dựng giao diện Flutter.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationRepository().init();

  runApp(const ProviderScope(child: HskDictApp()));
}
