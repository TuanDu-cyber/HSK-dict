# HSK Dict Project Guide

HSK Dict là app Flutter dùng để học từ vựng tiếng Trung HSK.

## Chức năng chính

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

## Công nghệ

- Flutter
- Riverpod
- go_router
- Firebase Auth
- Firestore
- shared_preferences
- Cloudinary
- TTS
- speech_to_text
- Local notification

## Dữ liệu và kiến trúc

- Dữ liệu từ vựng nằm ở `assets/data/hsk1.json`, `assets/data/hsk2.json`, `assets/data/hsk3.json`.
- Repository đọc dữ liệu và lưu dữ liệu.
- Provider quản lý state.
- Screen chỉ hiển thị UI và gọi provider.
- Firebase Auth dùng cho tài khoản.
- Firestore lưu user, favorites, progress, stats.
- Cloudinary lưu avatar.

## Cách chạy

```bash
flutter pub get
flutter analyze --no-pub
flutter test
flutter run
flutter build apk --debug
```
