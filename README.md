<div align="center">

<img src="https://raw.githubusercontent.com/TuanDu-cyber/hsk-dict/main/assets/icons/app_icon.png" width="120" alt="HSK Dict Logo"/>

# 📚 HSK Dict

### Ứng dụng hỗ trợ học từ vựng tiếng Trung HSK

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Riverpod](https://img.shields.io/badge/Riverpod-2.x-00BCD4?style=for-the-badge)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

</div>

---

## 📱 Demo

<div align="center">
  <img src="https://raw.githubusercontent.com/TuanDu-cyber/hsk-dict/main/assets/images/trangchu.png" width="300" alt="App Demo"/>
</div>

---

## ✨ Tính năng

| Tính năng | Mô tả |
|-----------|-------|
| 🔐 **Xác thực** | Đăng nhập bằng Email/Password hoặc Google Sign In |
| 📖 **Flashcard** | Lật thẻ từ vựng, đánh dấu đã nhớ / chưa nhớ, theo dõi tiến độ |
| 📝 **Quiz** | Trắc nghiệm 4 lựa chọn, chấm điểm tự động, xem lại kết quả |
| ✍️ **Luyện viết** | Hiển thị thứ tự nét chữ Hán, canvas luyện viết tương tác |
| 🎤 **Luyện phát âm** | Nghe phát âm mẫu TTS, ghi âm và tự đánh giá |
| 🔍 **Tra cứu từ vựng** | Tìm kiếm theo Hán tự, Pinyin hoặc nghĩa tiếng Việt |
| ❤️ **Yêu thích** | Lưu và quản lý danh sách từ vựng yêu thích |
| 🔥 **Daily Streak** | Theo dõi chuỗi ngày học liên tiếp, nhắc học hàng ngày |
| 🎮 **Matching Game** | Trò chơi nối từ Hán–Việt có tính giờ và tính điểm |

---

## 📷 Screenshots

<div align="center">

| Home | Flashcard | Quiz |
|:----:|:---------:|:----:|
| <img src="https://raw.githubusercontent.com/TuanDu-cyber/hsk-dict/main/assets/images/trangchu.png" width="200"/> | <img src="https://raw.githubusercontent.com/TuanDu-cyber/hsk-dict/main/assets/images/flashcard.png" width="200"/> | <img src="https://raw.githubusercontent.com/TuanDu-cyber/hsk-dict/main/assets/images/quiz.png" width="200"/> |

| Writing | Speaking | Search |
|:-------:|:--------:|:------:|
| <img src="https://raw.githubusercontent.com/TuanDu-cyber/hsk-dict/main/assets/images/writing.png" width="200"/> | <img src="https://raw.githubusercontent.com/TuanDu-cyber/hsk-dict/main/assets/images/speaking.png" width="200"/> | <img src="https://raw.githubusercontent.com/TuanDu-cyber/hsk-dict/main/assets/images/timkiem.png" width="200"/> |

| Matching Game | Favorites | Account |
|:-------------:|:---------:|:-------:|
| <img src="https://raw.githubusercontent.com/TuanDu-cyber/hsk-dict/main/assets/images/noitu.png" width="200"/> | <img src="https://raw.githubusercontent.com/TuanDu-cyber/hsk-dict/main/assets/images/word_fav.png" width="200"/> | <img src="https://raw.githubusercontent.com/TuanDu-cyber/hsk-dict/main/assets/images/account.png" width="200"/> |

</div>



## 🛠 Tech Stack

| Công nghệ | Vai trò |
|-----------|---------|
| **Flutter / Dart** | Cross-platform mobile development |
| **Riverpod** | State management |
| **Go Router** | Navigation & deep linking |
| **Firebase Authentication** | Xác thực Email/Password & Google Sign In |
| **Cloudinary** | Upload & phục vụ ảnh đại diện |
| **SharedPreferences** | Cache cài đặt và dữ liệu tạm |
| **flutter_tts** | Text-to-Speech phát âm tiếng Trung |
| **audioplayers + record** | Phát âm thanh & ghi âm giọng người dùng |
| **flutter_local_notifications** | Thông báo nhắc học hàng ngày |
| **image_picker** | Chọn ảnh đại diện từ thư viện / camera |

---


## 🗄 Lưu trữ dữ liệu

```
┌─────────────────────────────────────────────────────┐
│                    HSK Dict App                      │
├──────────────┬──────────────────┬───────────────────┤
│   Json       │    Firestore     │    Cloudinary      │
│  (Offline)   │    (Online)      │    (Media)         │
├──────────────┼──────────────────┼───────────────────┤
│ - Từ vựng    │ - Hồ sơ user     │ - Ảnh đại diện    │
│              │ - Streak học     │                   │
│              │ - Lịch sử quiz   │                   │
│              │ - Tiến độ sync   │                   │
└──────────────┴──────────────────┴───────────────────┘
          SharedPreferences: cache 
```

---

## 🚀 Bắt đầu

### Yêu cầu

- Flutter SDK `>= 3.0.0`
- Dart SDK `>= 3.0.0`
- Tài khoản Firebase
- Tài khoản Cloudinary

### Cài đặt

```bash
# 1. Clone repository
git clone https://github.com/TuanDu-cyber/HSK-dict.git

# 2. Cài đặt dependencies
flutter pub get

# 3. Cấu hình Firebase
flutterfire configure

# 4. Thêm google.json của firebase

# 5. Chạy ứng dụng
flutter run
```

### Cấu hình Firebase

1. Tạo project trên [Firebase Console](https://console.firebase.google.com)
2. Bật **Authentication** → Email/Password & Google Sign In
3. Tạo **Firestore Database** (production mode)
4. Chạy `flutterfire configure` để tạo `firebase_options.dart`

### Cấu hình Cloudinary

Thêm vào file`lib/core/config/cloudinary_config.dart:

```dart
static const cloudinaryCloudName = 'YOUR_CLOUD_NAME';
static const cloudinaryUploadPreset = 'YOUR_UPLOAD_PRESET';
```

---

## 📦 Dependencies chính

```yaml
dependencies:
  flutter_riverpod: ^2.x.x
  go_router: ^x.x.x
  firebase_core: ^x.x.x
  firebase_auth: ^x.x.x
  cloud_firestore: ^x.x.x
  sqflite: ^x.x.x
  shared_preferences: ^x.x.x
  flutter_tts: ^x.x.x
  audioplayers: ^x.x.x
  record: ^x.x.x
  flutter_local_notifications: ^x.x.x
  image_picker: ^x.x.x
  cloudinary_public: ^x.x.x
```

> Xem đầy đủ tại [`pubspec.yaml`](pubspec.yaml)

---

## 📋 Roadmap

- [x] Quản lý tài khoản (Email + Google)
- [x] Từ vựng HSK 1–3 với Hán tự, Pinyin, nghĩa tiếng Việt
- [x] Flashcard với theo dõi tiến độ
- [x] Quiz trắc nghiệm
- [x] Luyện viết thứ tự nét
- [x] Luyện phát âm với ghi âm
- [x] Matching Game
- [x] Yêu thích & Daily Streak
- [ ] Spaced Repetition System (SRS)
- [ ] Leaderboard & học nhóm
- [ ] Hỗ trợ HSK 7–9 (chuẩn mới)
- [ ] Flutter Web

---

## 👨‍💻 Tác giả

<div align="center">

**[TuanDu-cyber]**

Flutter Developer

[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/yourname)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/yourname)

</div>

---

## 📄 License

Distributed under the MIT License. See [`LICENSE`](LICENSE) for more information.

---

<div align="center">

⭐ **Nếu dự án hữu ích, hãy để lại một star nhé!** ⭐

</div>