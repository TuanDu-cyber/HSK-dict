# HSK Dict - Luồng app và cấu hình

## 1. Tổng quan app

HSK Dict là app Flutter học từ vựng tiếng Trung HSK.

Chức năng chính:

- Đăng nhập, đăng ký, quên mật khẩu
- Home
- Thẻ từ
- Kiểm tra
- Tập viết
- Luyện nói
- Tìm kiếm
- Từ đã lưu
- Nối từ
- Tài khoản
- Nhắc học mỗi ngày

## 2. Công nghệ

- Flutter/Dart: xây app.
- Riverpod: quản lý state.
- go_router: điều hướng.
- Firebase Auth: tài khoản.
- Firestore: lưu dữ liệu online.
- shared_preferences: lưu local/cache.
- Cloudinary: lưu avatar.
- flutter_tts: phát âm.
- speech_to_text: nhận diện giọng nói.
- flutter_local_notifications + timezone: thông báo nhắc học.

## 3. Luồng khởi động

`main.dart` -> `Firebase.initializeApp` -> `ProviderScope` -> `App` -> `AppRouter` -> kiểm tra đăng nhập -> `Login/Register` hoặc `Home`.

## 4. Luồng dữ liệu từ vựng

`assets/data/hsk1.json`, `assets/data/hsk2.json`, `assets/data/hsk3.json` -> `WordRepository` -> `WordModel` -> `Provider` -> `Screen`.

Từ vựng gốc nằm trong JSON local, không lưu lên Firestore.

## 5. Luồng đăng nhập

`Login/Register Screen` -> `AuthProvider` -> `AuthRepository` -> `Firebase Auth` -> `Firestore users/{uid}` -> `Home`.

Screen chỉ hiển thị UI, Provider xử lý state, Repository gọi Firebase.

## 6. Lưu trữ dữ liệu

| Dữ liệu        | Lưu ở đâu                      |
| -------------- | ------------------------------ |
| Từ vựng        | `assets/data/*.json`           |
| Tài khoản      | Firebase Auth                  |
| Hồ sơ user     | Firestore `users/{uid}`        |
| Avatar         | Cloudinary                     |
| Link avatar    | Firestore `avatarUrl`          |
| Từ đã lưu      | Firestore + shared_preferences |
| Tiến trình học | Firestore + shared_preferences |
| Game stats     | Firestore + shared_preferences |
| Notification   | Local device                   |

## 7. Luồng chức năng chính

- Flashcard lưu `currentIndex`, từ đã thuộc/chưa thuộc.
- Quiz random 20 từ, lưu session để thoát vào lại vẫn tiếp tục.
- Writing hiển thị chữ Hán, stroke order nếu có, canvas fallback nếu không có.
- Speaking dùng TTS đọc mẫu và speech_to_text để nhận diện.
- Search tìm trong dữ liệu local.
- Favorites lưu `wordId` rồi map lại `WordModel`.
- Game nối chữ Hán với nghĩa.
- Avatar upload Cloudinary, lưu `secure_url` vào Firestore.
- Notification là local notification theo giờ Việt Nam.

## 8. Cấu hình cần nhớ

- Cần `android/app/google-services.json`.
- Firebase Auth bật Email/Password.
- Firestore paths:
  - `users/{uid}`
  - `users/{uid}/favorites`
  - `users/{uid}/progress`
  - `users/{uid}/stats`
- Cloudinary dùng unsigned upload preset, không dùng API secret trong app.

## 9. Cách chạy

```bash
flutter pub get
flutter analyze --no-pub
flutter test
flutter run
flutter build apk --debug
```

## 10. Quy tắc code

- Không khai báo Model trong Screen.
- Screen chỉ làm UI.
- Provider quản lý state.
- Repository xử lý dữ liệu/Firebase/local/API.
- Không hardcode API secret.
