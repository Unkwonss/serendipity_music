# 🎵 Serendipity Music Player

> *"Break the filter bubble. Discover music you never knew you needed."*

Ứng dụng nghe nhạc phá vỡ thuật toán gợi ý — mang đến những bài hát bất ngờ từ khắp nơi trên thế giới.

---

## ✨ Tính năng nổi bật

| Tính năng | Mô tả |
|-----------|-------|
| ⚡ **Anti-Algorithm Shuffle** | Nhảy bài hoàn toàn ngẫu nhiên, không theo thuật toán |
| 🎲 **Chaos Filters** | 8 bộ lọc: Thể loại, Tâm trạng, Thập niên, Quốc gia, Ngôn ngữ, Nhạc cụ, Soundtrack, BPM |
| 🔊 **Background Playback** | Phát nhạc khi tắt màn hình, điều khiển qua notification |
| 📱 **Mini Player** | Mini player cố định phía trên bottom navigation |
| 📜 **Lịch sử nghe** | Ghi lại toàn bộ bài đã nghe theo thứ tự thời gian |
| 🗺️ **Odyssey Graph** | Biểu đồ node hiển thị hành trình nghe nhạc của bạn |
| ⏱️ **Sleep Timer** | Hẹn giờ tắt nhạc, kể cả tùy chọn "hết bài mới tắt" |
| 🔄 **Pre-buffering** | Tải trước bài kế tiếp để không bị gián đoạn |

---

## 🚀 Cài đặt & Chạy

### Yêu cầu
- Flutter 3.x+
- Android SDK 21+ / iOS 12+
- YouTube Data API v3 Key

### Chạy app ngay (Không bắt buộc API Key!)
Ứng dụng được tích hợp sẵn cơ chế **tự động fallback sang công cụ trích xuất YouTube không cần API Key**. Bạn có thể chạy app và nghe nhạc ngay lập tức:

```bash
cd serendipity_music
flutter pub get
flutter run
```

### (Tùy chọn) Setup Google Cloud YouTube Data API v3
Nếu bạn muốn sử dụng API chính thức của Google để tăng tốc độ tìm kiếm:
1. Truy cập [Google Cloud Console](https://console.cloud.google.com)
2. Tạo project mới → Enable **YouTube Data API v3**
3. Tạo API Key
4. Điền vào [`lib/core/constants/app_constants.dart`](lib/core/constants/app_constants.dart):
```dart
static const String youtubeApiKey = 'YOUR_API_KEY_HERE';
```

---

## 🏗️ Kiến trúc

```
lib/
├── core/
│   ├── constants/       # App constants, Chaos filter constants
│   └── theme/           # Dark theme, colors
├── domain/
│   └── entities/        # TrackEntity
├── data/
│   ├── models/          # Data models
│   └── repositories/    # Repository implementations
├── services/
│   ├── audio/           # AudioHandler (just_audio + audio_service)
│   └── youtube/         # YouTubeSearchService, YouTubeStreamService
└── presentation/
    ├── pages/
    │   ├── search/       # 🔍 Tìm kiếm
    │   ├── chaos_filter/ # 🎲 Bộ lọc
    │   ├── now_playing/  # 🎵 Đang phát
    │   ├── history/      # 📜 Lịch sử
    │   └── odyssey/      # 🗺️ Hành trình
    ├── widgets/
    │   └── mini_player/  # Mini player widget
    └── providers/        # Riverpod state management
```

## 📦 Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| Audio Engine | `just_audio` + `audio_service` |
| Music Source | YouTube Data API v3 + `youtube_explode_dart` |
| State Management | Riverpod |
| Local Storage | Hive |
| Image Cache | `cached_network_image` |
| Graph View | `graphview` |

---

## 🎲 Chaos Filters

| Filter | Options |
|--------|---------|
| 🎸 Thể loại | Pop, Rock, Jazz, Classical, Hip-hop, Lo-fi, Indie, Metal... (20 thể loại) |
| 😊 Tâm trạng | Happy, Sad, Chill, Energetic, Romantic, Focus, Sleep, Party |
| 🕰️ Thập niên | 60s, 70s, 80s, 90s, 2000s, 2010s, 2020s |
| 🌍 Quốc gia | VN, KR, JP, US, GB, FR, BR, IN, MX, NG... (15 quốc gia) |
| 🔤 Ngôn ngữ | Tiếng Việt, English, 한국어, 日本語, Français... (10 ngôn ngữ) |
| 🎹 Nhạc cụ | Guitar, Piano, Violin, Saxophone, Drums, Synth... |
| 🎬 Soundtrack | Anime OST, Movie, Game OST, K-Drama, Disney |
| ⏱️ BPM | Slow (~60), Medium (~100), Fast (~140), Very Fast (~180) |
