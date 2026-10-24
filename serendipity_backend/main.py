import os
import re
import random
import time
from typing import Optional, List, Dict, Any
from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
import yt_dlp
import requests

app = FastAPI(title="Serendipity Music YouTube Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Common yt-dlp options
YDL_SEARCH_OPTS = {
    "quiet": True,
    "no_warnings": True,
    "extract_flat": True,
    "skip_download": True,
    "js_runtimes": {"node": {}},
}

YDL_STREAM_OPTS = {
    "quiet": True,
    "no_warnings": True,
    "format": "bestaudio[ext=m4a]/bestaudio/best",
    "skip_download": True,
    "js_runtimes": {"node": {}},
}

# In-memory cache for stream URLs: { videoId: { "url": str, "expires": float, "data": dict } }
STREAM_CACHE: Dict[str, Dict[str, Any]] = {}
CACHE_TTL = 3600 * 4  # 4 hours


COMPILATION_REGEX = re.compile(
    r"(full\s*(album|ep|playlist|experience)|tuyển\s*tập|tổng\s*hợp|những\s*bài\s*hát|các\s*bài\s*hát|"
    r"liên\s*khúc|mashup|medley|playlist|greatest\s*hits|best\s*songs|top\s*hits|"
    r"nonstop|non-stop|\d+\s*(hours?|tiếng|h|bài|hits)|nghe\s*để\s*ngủ|thâu\s*đêm|suốt\s*đêm|"
    r"audiobook|sách\s*nói)",
    re.IGNORECASE
)


def _is_compilation(title: str, duration_sec: int) -> bool:
    # Bất kỳ video nào dài hơn 8 phút (480s) hoặc ngắn dưới 50s (Shorts/teaser)
    if duration_sec > 480 or (0 < duration_sec < 50):
        return True
    # Hoặc tiêu đề chứa các từ khóa biểu thị album/tổng hợp/mashup/playlist gộp
    if COMPILATION_REGEX.search(title):
        return True
    return False


def _clean_track(entry: dict) -> Optional[dict]:
    video_id = entry.get("id") or ""
    # Filter out channel IDs
    if video_id.startswith("UC") or entry.get("_type") == "channel":
        return None

    duration = entry.get("duration") or 0
    thumbnails = entry.get("thumbnails") or []
    thumbnail_url = ""
    if thumbnails:
        thumbnail_url = thumbnails[-1].get("url") or ""
    elif entry.get("thumbnail"):
        thumbnail_url = entry.get("thumbnail")

    title = entry.get("title") or "Unknown Title"
    is_combo = _is_compilation(title, int(duration))

    return {
        "id": video_id,
        "title": title,
        "artist": entry.get("uploader") or entry.get("channel") or "Unknown Artist",
        "thumbnailUrl": thumbnail_url,
        "durationMs": int(duration * 1000),
        "source": "youtube",
        "isCompilation": is_combo,
    }


@app.get("/api/health")
def health_check():
    return {
        "status": "ok",
        "service": "serendipity-youtube-backend",
        "version": "1.0.0",
        "cached_streams": len(STREAM_CACHE),
    }


@app.get("/api/search")
def search_tracks(
    q: str = Query(..., min_length=1, description="Từ khóa tìm kiếm"),
    limit: int = Query(20, ge=1, le=50, description="Số lượng kết quả"),
):
    query = q.strip()
    fetch_count = min(limit + 10, 50)
    search_query = f"ytsearch{fetch_count}:{query}"
    try:
        with yt_dlp.YoutubeDL(YDL_SEARCH_OPTS) as ydl:
            res = ydl.extract_info(search_query, download=False)
            entries = res.get("entries") or []
            singles = []
            combos = []
            for e in entries:
                if not e or not e.get("id"):
                    continue
                track = _clean_track(e)
                if track is not None:
                    if track.get("isCompilation"):
                        combos.append(track)
                    else:
                        singles.append(track)

            # Ưu tiên bài lẻ trước, sau đó mới tới album/combo
            results = (singles + combos)[:limit]
            return {
                "success": True,
                "count": len(results),
                "results": results,
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi tìm kiếm YouTube: {str(e)}")


@app.get("/api/stream")
def get_stream_url(id: str = Query(..., description="YouTube Video ID")):
    video_id = id.strip()
    now = time.time()

    # Check cache
    if video_id in STREAM_CACHE:
        cached = STREAM_CACHE[video_id]
        if cached["expires"] > now:
            return {
                "success": True,
                "cached": True,
                **cached["data"],
            }

    video_url = f"https://www.youtube.com/watch?v={video_id}"
    try:
        with yt_dlp.YoutubeDL(YDL_STREAM_OPTS) as ydl:
            info = ydl.extract_info(video_url, download=False)
            stream_url = info.get("url")
            if not stream_url:
                raise HTTPException(status_code=404, detail="Không tìm thấy stream audio hợp lệ")

            track_info = _clean_track(info)
            data = {
                "id": video_id,
                "title": track_info["title"],
                "artist": track_info["artist"],
                "thumbnailUrl": track_info["thumbnailUrl"],
                "durationMs": track_info["durationMs"],
                "streamUrl": stream_url,
                "mimeType": "audio/mp4",
                "format": info.get("ext") or "m4a",
                "abr": info.get("abr") or 128,
            }

            STREAM_CACHE[video_id] = {
                "expires": now + CACHE_TTL,
                "data": data,
            }

            return {
                "success": True,
                "cached": False,
                **data,
            }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi bóc tách audio YouTube: {str(e)}")


POPULAR_SEED_KEYWORDS = [
    "vietnamese chill acoustic music",
    "lofi chill beats",
    "pop ballad hits",
    "indie viet nam hay nhat",
    "us uk pop hits",
    "acoustic guitar chill songs",
    "piano chill instrumental",
    "rock ballad classics",
    "r&b soul chill music",
    "synthwave retro chill",
]


@app.get("/api/random")
def get_random_track(
    genre: Optional[str] = None,
    mood: Optional[str] = None,
    decade: Optional[str] = None,
):
    keywords = []
    if genre:
        keywords.append(genre)
    if mood:
        keywords.append(mood)
    if decade:
        keywords.append(decade)

    if keywords:
        query = " ".join(keywords) + " songs"
    else:
        query = random.choice(POPULAR_SEED_KEYWORDS)

    # Search top 25 results và ưu tiên chọn bài lẻ (single track)
    search_query = f"ytsearch25:{query}"
    try:
        with yt_dlp.YoutubeDL(YDL_SEARCH_OPTS) as ydl:
            res = ydl.extract_info(search_query, download=False)
            entries = [e for e in (res.get("entries") or []) if e and e.get("id")]
            if not entries:
                raise HTTPException(status_code=404, detail="Không tìm thấy bài hát ngẫu nhiên")

            singles = [
                e for e in entries
                if not _is_compilation(e.get("title") or "", int(e.get("duration") or 0))
            ]
            chosen = random.choice(singles) if singles else random.choice(entries)
            # Resolve stream for the chosen track
            return get_stream_url(id=chosen["id"])
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi lấy bài ngẫu nhiên: {str(e)}")


def _clean_artist_name(artist: str) -> str:
    cleaned = artist or ""
    for suffix in ["- Topic", "Official", "VEVO", "Channel", "Music", "Official Channel"]:
        cleaned = re.sub(re.escape(suffix), "", cleaned, flags=re.IGNORECASE)
    return cleaned.strip()


def _extract_context_keywords(title: str) -> str:
    patterns = [
        r"Anh Trai Say Hi", r"Anh Trai Vượt Ngàn Chông Gai", r"Rap Việt",
        r"Ca Sĩ Mặt Nạ", r"The Masked Singer", r"Sing My Song", r"Giọng Hát Việt",
        r"Acoustic", r"Lofi", r"Remix", r"Live Session", r"Ballad", r"Cover",
        r"Chill", r"EDM", r"Indie"
    ]
    matched = []
    for pat in patterns:
        if re.search(pat, title, flags=re.IGNORECASE):
            matched.append(pat)
    return " ".join(matched)


@app.get("/api/related")
def get_related_tracks(
    id: str = Query(..., description="Current Video ID"),
    title: Optional[str] = Query(None, description="Current Title"),
    artist: Optional[str] = Query(None, description="Current Artist"),
    limit: int = Query(15, ge=1, le=30),
):
    current_id = id.strip()
    clean_artist = _clean_artist_name(artist or "")
    context = _extract_context_keywords(title or "")

    query_parts = []
    if clean_artist:
        query_parts.append(clean_artist)
    if context:
        query_parts.append(context)

    if not query_parts:
        if title:
            clean_title = re.sub(r"[\[\(].*?[\]\)]", "", title).strip()
            query_parts.append(clean_title)
        else:
            query_parts.append("vietnamese chill hits")

    # Lấy số lượng nhiều hơn để bóc tách và ưu tiên tuyệt đối bài đơn lẻ
    fetch_count = min(limit * 2 + 5, 50)
    search_query = f"ytsearch{fetch_count}:{' '.join(query_parts)} songs"
    try:
        with yt_dlp.YoutubeDL(YDL_SEARCH_OPTS) as ydl:
            res = ydl.extract_info(search_query, download=False)
            entries = res.get("entries") or []
            
            singles = []
            combos = []

            for e in entries:
                if not e or not e.get("id"):
                    continue
                if e.get("id") == current_id:
                    continue
                track = _clean_track(e)
                if track is None:
                    continue

                if track.get("isCompilation"):
                    combos.append(track)
                else:
                    singles.append(track)

            # ƯU TIÊN TUYỆT ĐỐI các bài lẻ (singles) trước, chỉ lấy combo khi thiếu bài
            ordered_results = (singles + combos)[:limit]

            return {
                "success": True,
                "count": len(ordered_results),
                "singles_count": len([t for t in ordered_results if not t.get("isCompilation")]),
                "combos_count": len([t for t in ordered_results if t.get("isCompilation")]),
                "query": " ".join(query_parts),
                "results": ordered_results,
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi lấy bài liên quan: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    # Bind to 0.0.0.0 so both localhost and Android Emulator (10.0.2.2) can access
    uvicorn.run(app, host="0.0.0.0", port=8000)
