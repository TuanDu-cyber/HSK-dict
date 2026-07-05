# Task for Codex: Audit and optimize HSK Dict

Hãy đọc trước:

- CODEX_CONTEXT.md
- pubspec.yaml
- lib/main.dart
- lib/app.dart
- lib/core/router/app_router.dart
- lib/core/theme/app_theme.dart
- lib/core/widgets/
- lib/models/
- lib/repositories/
- lib/features/

Nhiệm vụ: audit toàn bộ project, CHƯA sửa code ngay.

Hãy báo cáo theo format:

## P0 - Lỗi nghiêm trọng

Các lỗi làm app không chạy, crash, route sai, Firebase/Auth sai, màn không mở được.

## P1 - Lỗi logic

Các lỗi lưu progress, đọc JSON, random session, timer, search, favorites, uid prefix.

## P2 - Lỗi kiến trúc

Business logic nằm trong UI, repository sai trách nhiệm, code trùng lặp, provider quá dài.

## P3 - UI/UX

Responsive, overflow, màu hardcode, spacing không đồng bộ, bottom nav sai label/icon.

Với mỗi lỗi, ghi rõ:

- File bị lỗi
- Đoạn logic có vấn đề
- Vì sao lỗi
- Cách sửa đề xuất
- Có nên sửa ngay không

Sau báo cáo, hãy đưa kế hoạch sửa theo từng bước nhỏ.

Không sửa code trước khi tôi đồng ý.
