## Mục tiêu audit project

Codex cần đọc toàn bộ project và kiểm tra:

1. App có file/thư mục nào không còn cần thiết không?
2. Có màn nào route sai hoặc không còn dùng nữa không?
3. Màn Translate đã được thay bằng Game Nối từ chưa?
4. BottomNav tab thứ 3 đã đổi đúng thành Nối từ/Game chưa?
5. Các progress Flashcard/Quiz/Writing/Speaking/Search/Favorites/Game có bị lưu lẫn giữa nhiều user Firebase không?
6. Dữ liệu JSON hsk1.json, hsk2.json, hsk3.json có được đọc qua repository không?
7. Có chỗ nào đọc JSON lặp lại quá nhiều không?
8. Có chỗ nào hardcode dữ liệu thay vì lấy từ JSON không?
9. Có chỗ nào hardcode màu thay vì lấy từ AppTheme không?
10. Có màn nào chứa business logic trong UI không?
11. Có package nào trong pubspec.yaml không dùng nữa không?
12. Có lỗi responsive/overflow tiềm ẩn không?
13. Có lỗi null safety khi JSON thiếu field không?
14. Có lỗi timer không dispose trong Quiz/Speaking/Writing không?
15. Có lỗi use_build_context_synchronously không?

## Quy tắc kiến trúc bắt buộc

- Screen chỉ hiển thị UI.
- Provider xử lý state và gọi repository.
- Repository xử lý đọc JSON, Firebase, shared_preferences, TTS, speech recognition.
- Không để business logic trong Screen.
- Không hardcode màu ngoài AppTheme.
- Không tạo thêm SettingScreen riêng vì AccountScreen chính là Cài đặt.
- Không lưu dữ liệu HSK lên Firebase.
- Dữ liệu từ vựng vẫn lấy từ JSON local.
- Firebase chỉ dùng cho Auth/Profile.
- Progress học tập hiện tại ưu tiên lưu local bằng shared_preferences, nhưng key phải có uid để không bị lẫn user.

## Quy tắc lưu dữ liệu theo user

Tất cả key shared_preferences phải có prefix uid.

Ví dụ:

{uid}_flashcard_{topic}
{uid}_quiz_{topic}
{uid}_writing_{topic}
{uid}_speaking_{topic}
{uid}\_favorites
{uid}\_search_recent_queries
{uid}\_matching_game_stats

Nếu chưa đăng nhập thì dùng prefix:

guest\_

## Màn Translate

Màn Translate cũ không còn là chức năng chính.

Yêu cầu mới:

- Thay Translate bằng Game Nối từ.
- BottomNav tab thứ 3 nên đổi thành “Nối từ” hoặc “Trò chơi”.
- Route ưu tiên là /game.
- Nếu project vẫn còn /translate thì kiểm tra xem có cần xóa, redirect hoặc đổi sang /game không.

## Game Nối từ

Cách hoạt động:

- Random 4 từ từ JSON theo topic hoặc toàn bộ dữ liệu.
- Cột trái là hanzi.
- Cột phải là meaning_vi.
- Xáo trộn hai cột.
- User chọn một hanzi và một nghĩa.
- Nếu đúng thì 2 ô biến mất.
- Nếu sai thì báo sai và cho chọn lại.
- Hết 4 cặp thì hiện dialog thắng.
