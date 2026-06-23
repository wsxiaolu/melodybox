"""
MelodyBox Server — 一体化服务器
- 提供 Flutter Web 静态文件
- 代理搜索请求到 gequhai.com
- 解析 HTML 返回结构化 JSON
- 获取歌曲播放/下载链接
"""
import http.server
import socketserver
import urllib.request
import urllib.parse
import json
import re
import os
import sys
import html as html_mod
import http.cookiejar
import uuid
import hashlib
import time

# PyInstaller 打包后资源路径
def _get_web_dir():
    if getattr(sys, 'frozen', False):
        return os.path.join(sys._MEIPASS, "build", "web")
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), "build", "web")

_WEB_DIR = _get_web_dir()

PORT = 8090
GEQUHAI = "https://www.gequhai.com"

# ==================== 用户系统 ====================
_USERS_FILE = "users.json"
_PLAYLISTS_FILE = "playlists.json"
_SESSIONS = {}  # token -> username

def _load_users():
    if not os.path.exists(_USERS_FILE):
        return {}
    with open(_USERS_FILE, "r", encoding="utf-8") as f:
        return json.load(f)

def _save_users(users):
    with open(_USERS_FILE, "w", encoding="utf-8") as f:
        json.dump(users, f, ensure_ascii=False, indent=2)

def _hash_password(pw):
    return hashlib.sha256(pw.encode()).hexdigest()

# 全局 cookie 会话（所有请求共享）
_COOKIE_JAR = http.cookiejar.CookieJar()
_OPENER = urllib.request.build_opener(
    urllib.request.HTTPCookieProcessor(_COOKIE_JAR)
)

def _fetch_url(url, timeout=20):
    req = urllib.request.Request(url)
    req.add_header("User-Agent",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    req.add_header("Accept", "text/html,application/xhtml+xml")
    req.add_header("Referer", GEQUHAI + "/")
    with _OPENER.open(req, timeout=timeout) as resp:
        return resp.read().decode('utf-8', errors='ignore')

def _fetch_api(url, data=None, referer=None):
    req = urllib.request.Request(url, data=data)
    req.add_header("User-Agent",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    req.add_header("X-Requested-With", "Http")
    req.add_header("X-Custom-Header", "Key")
    req.add_header("Referer", referer or GEQUHAI + "/")
    if data:
        req.add_header("Content-Type", "application/x-www-form-urlencoded")
    with _OPENER.open(req, timeout=15) as resp:
        return resp.read().decode('utf-8', errors='ignore')

class MelodyServer(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        # API 路由
        if self.path.startswith("/api/search"):
            self._api_search()
        elif self.path.startswith("/api/play/"):
            self._api_play()
        elif self.path.startswith("/api/hot"):
            self._api_hot()
        elif self.path == "/api/user":
            self._api_user()
        elif self.path.startswith("/api/playlists"):
            self._api_playlists()
        else:
            self._serve_static()

    def do_POST(self):
        if self.path == "/api/login":
            self._api_login()
        elif self.path == "/api/register":
            self._api_register()
        elif self.path == "/api/logout":
            self._api_logout()
        elif self.path.startswith("/api/playlist"):
            self._api_playlist_action()
        elif self.path.startswith("/api/search"):
            self._api_search_post()
        else:
            self.send_error(404)

    def do_OPTIONS(self):
        self._cors_headers()

    # ==================== API ====================

    def _api_search(self):
        """GET /api/search?q=关键词"""
        qs = urllib.parse.urlparse(self.path).query
        params = urllib.parse.parse_qs(qs)
        keyword = params.get('q', [''])[0].strip()
        if not keyword:
            self._json({"error": "Missing keyword", "tracks": []})
            return
        self._do_search(keyword)

    def _api_search_post(self):
        """POST /api/search"""
        length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(length).decode('utf-8')
        try:
            data = urllib.parse.parse_qs(body)
            keyword = data.get('keyword', [''])[0].strip()
        except:
            keyword = ''
        if not keyword:
            self._json({"error": "Missing keyword", "tracks": []})
            return
        self._do_search(keyword)

    def _do_search(self, keyword):
        """搜索歌曲"""
        encoded = urllib.parse.quote(keyword)
        url = f"{GEQUHAI}/s/{encoded}"
        try:
            html = self._fetch(url)
            tracks = self._parse_search_results(html)
            print(f"[搜索] '{keyword}' -> {len(tracks)} 首")
            self._json({"tracks": tracks, "total": len(tracks)})
        except Exception as e:
            print(f"[搜索] 失败: {e}")
            self._json({"error": str(e), "tracks": [], "total": 0})

    def _api_play(self):
        """GET /api/play/{id} — 获取歌曲播放/下载链接"""
        match = re.match(r'/api/play/(\d+)', self.path)
        if not match:
            self._json({"error": "Invalid ID", "url": ""})
            return
        song_id = match.group(1)
        url = f"{GEQUHAI}/play/{song_id}"

        try:
            html = self._fetch(url)
            play_data = self._parse_play_page(html, song_id)
            print(f"[播放] id={song_id} -> {play_data.get('song_name', '?')} url={play_data.get('audio_url', '')[:60]}")
            self._json(play_data)
        except Exception as e:
            print(f"[播放] 失败: {e}")
            self._json({"error": str(e), "url": "", "song_name": "", "cover_url": ""})

    def _api_hot(self):
        """GET /api/hot — 热门歌曲（搜索流行关键词）"""
        tracks = []
        keywords = ['周杰伦', '热门', '抖音', '新歌', '流行']
        for kw in keywords:
            try:
                encoded = urllib.parse.quote(kw)
                html = _fetch_url(f"{GEQUHAI}/s/{encoded}")
                result = self._parse_search_results(html)
                tracks.extend(result[:6])
                if len(tracks) >= 20:
                    break
            except Exception as e:
                print(f"[热门] {kw} 失败: {e}")
        print(f"[热门] -> {len(tracks)} 首")
        self._json({"tracks": tracks[:20], "total": len(tracks)})

    # ==================== 账号 ====================

    def _api_user(self):
        """GET /api/user — 检查登录状态"""
        token = self._get_token()
        if token and token in _SESSIONS:
            self._json({"logged_in": True, "username": _SESSIONS[token]})
        else:
            self._json({"logged_in": False, "username": ""})

    def _api_login(self):
        """POST /api/login"""
        body = self._read_body()
        username = (body.get("username") or "").strip()
        password = body.get("password") or ""
        if not username or not password:
            self._json({"ok": False, "msg": "用户名和密码不能为空"})
            return
        users = _load_users()
        if username not in users:
            self._json({"ok": False, "msg": "账号不存在"})
            return
        if users[username]["password"] != _hash_password(password):
            self._json({"ok": False, "msg": "密码错误"})
            return
        token = str(uuid.uuid4())
        _SESSIONS[token] = username
        self._json({"ok": True, "username": username, "token": token})

    def _api_register(self):
        """POST /api/register"""
        body = self._read_body()
        username = (body.get("username") or "").strip()
        password = body.get("password") or ""
        if not username or len(username) < 2:
            self._json({"ok": False, "msg": "用户名至少2个字符"})
            return
        if len(password) < 4:
            self._json({"ok": False, "msg": "密码至少4位"})
            return
        users = _load_users()
        if username in users:
            self._json({"ok": False, "msg": "用户名已被注册"})
            return
        users[username] = {
            "password": _hash_password(password),
            "created_at": time.strftime("%Y-%m-%d %H:%M:%S"),
        }
        _save_users(users)
        token = str(uuid.uuid4())
        _SESSIONS[token] = username
        self._json({"ok": True, "username": username, "token": token})

    def _api_logout(self):
        """POST /api/logout"""
        token = self._get_token()
        _SESSIONS.pop(token, None)
        self._json({"ok": True})

    def _get_token(self):
        """从 Cookie 或 Authorization header 中获取 token"""
        cookie = self.headers.get("Cookie", "")
        m = re.search(r'token=([^;]+)', cookie)
        if m:
            return m.group(1)
        auth = self.headers.get("Authorization", "")
        if auth.startswith("Bearer "):
            return auth[7:]
        return None

    def _read_body(self):
        length = int(self.headers.get("Content-Length", 0))
        if length == 0:
            return {}
        body = self.rfile.read(length).decode("utf-8")
        if "application/json" in self.headers.get("Content-Type", ""):
            return json.loads(body)
        return dict(urllib.parse.parse_qsl(body))

    # ==================== 歌单 ====================

    def _require_login(self):
        token = self._get_token()
        if not token or token not in _SESSIONS:
            self._json({"ok": False, "msg": "请先登录"}, 401)
            return None
        return _SESSIONS[token]

    def _api_playlists(self):
        """GET /api/playlists?username=xxx"""
        qs = urllib.parse.urlparse(self.path).query
        params = urllib.parse.parse_qs(qs)
        username = params.get("username", [""])[0]
        if not username:
            username = self._require_login()
            if not username: return

        playlists = self._load_playlists()
        user_pls = playlists.get(username, [])
        self._json({"playlists": user_pls})

    def _api_playlist_action(self):
        """POST /api/playlist/create|add|remove|delete"""
        username = self._require_login()
        if not username: return

        body = self._read_body()
        action = body.get("action", "")
        playlists = self._load_playlists()
        user_pls = playlists.get(username, [])

        if action == "create":
            name = (body.get("name") or "新歌单").strip()
            pl = {"id": str(int(time.time()*1000)), "name": name, "songs": [], "created": time.strftime("%Y-%m-%d")}
            user_pls.append(pl)
            playlists[username] = user_pls
            self._save_playlists(playlists)
            self._json({"ok": True, "playlist": pl})

        elif action == "add":
            pl_id = body.get("playlist_id", "")
            song = {
                "id": body.get("song_id"),
                "name": body.get("song_name", ""),
                "artist": body.get("artist", ""),
                "cover": body.get("cover", ""),
            }
            for pl in user_pls:
                if pl["id"] == pl_id:
                    if not any(s["id"] == song["id"] for s in pl["songs"]):
                        pl["songs"].append(song)
                    break
            playlists[username] = user_pls
            self._save_playlists(playlists)
            self._json({"ok": True})

        elif action == "remove":
            pl_id = body.get("playlist_id", "")
            song_id = body.get("song_id")
            for pl in user_pls:
                if pl["id"] == pl_id:
                    pl["songs"] = [s for s in pl["songs"] if str(s["id"]) != str(song_id)]
                    break
            playlists[username] = user_pls
            self._save_playlists(playlists)
            self._json({"ok": True})

        elif action == "delete":
            pl_id = body.get("playlist_id", "")
            playlists[username] = [pl for pl in user_pls if pl["id"] != pl_id]
            self._save_playlists(playlists)
            self._json({"ok": True})

    def _load_playlists(self):
        if not os.path.exists(_PLAYLISTS_FILE):
            return {}
        with open(_PLAYLISTS_FILE, "r", encoding="utf-8") as f:
            return json.load(f)

    def _save_playlists(self, data):
        with open(_PLAYLISTS_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

    # ==================== 解析 ====================

    def _parse_search_results(self, html_str):
        """从搜索结果 HTML 中提取歌曲列表"""
        tracks = []
        # 匹配每一行: <tr> ... <td>序号</td> <td><a href="/play/ID">歌名</a></td> <td>歌手</td> ... </tr>
        rows = re.findall(
            r'<tr>\s*<td[^>]*?>(\d+)</td>\s*<td>\s*<a\s+href="(/play/(\d+))"[^>]*?>\s*(.*?)\s*</a>',
            html_str, re.DOTALL
        )

        for row_match in rows:
            rank = row_match[0]
            play_path = row_match[1]
            play_id = row_match[2]
            song_name = html_mod.unescape(re.sub(r'<[^>]+>', '', row_match[3])).strip()

            # 找歌手（下一个 <td>）
            pattern = re.escape(play_path) + r'.*?<td[^>]*?>\s*(.*?)\s*</td>'
            artist_match = re.search(pattern, html_str, re.DOTALL)
            artist = ""
            if artist_match:
                # 从匹配中提取下一个 <td>
                next_td = re.search(
                    r'<td[^>]*?style="color:\s*#666[^"]*"[^>]*?>(.*?)</td>',
                    html_str[artist_match.end():artist_match.end()+500],
                    re.DOTALL
                )
                if next_td:
                    artist = html_mod.unescape(next_td.group(1)).strip()
                    artist = re.sub(r'<[^>]+>', '', artist)

            if song_name and play_id:
                tracks.append({
                    "id": int(play_id),
                    "name": song_name,
                    "artist_name": artist or "未知",
                    "album_name": "",
                    "image_url": "",
                    "rank": int(rank),
                    "play_path": play_path,
                })

        return tracks

    def _parse_play_page(self, html_str, song_id):
        """从播放页面提取音频链接 — 模拟 /api/music 调用"""
        result = {
            "song_name": "",
            "artist": "",
            "cover_url": "",
            "audio_url": "",
            "download_url": "",
        }

        # 提取页面变量
        title = re.search(r"window\.mp3_title\s*=\s*'([^']*)'", html_str)
        author = re.search(r"window\.mp3_author\s*=\s*'([^']*)'", html_str)
        play_id = re.search(r"window\.play_id\s*=\s*'([^']*)'", html_str)
        mp3_type = re.search(r"window\.mp3_type\s*=\s*(\d+)", html_str)
        cover = re.search(r"window\.mp3_cover\s*=\s*'([^']*)'", html_str)
        extra_url = re.search(r"window\.mp3_extra_url\s*=\s*'([^']*)'", html_str)

        if title:
            result["song_name"] = html_mod.unescape(title.group(1))
        if author:
            result["artist"] = html_mod.unescape(author.group(1))
        if cover:
            result["cover_url"] = cover.group(1)

        # 调用 /api/music 获取真实 MP3 URL（使用 cookie session）
        if play_id:
            try:
                api_data = urllib.parse.urlencode({
                    "id": play_id.group(1),
                    "type": mp3_type.group(1) if mp3_type else "0"
                }).encode()
                api_resp = self._fetch_api(f"{GEQUHAI}/api/music", data=api_data)
                music_data = json.loads(api_resp)
                if music_data.get("code") == 200:
                    result["audio_url"] = music_data["data"].get("url", "")
            except Exception as e:
                print(f"  [api/music] 失败: {e}")

        # 解码 extra_url 作为下载备选
        if extra_url and not result["audio_url"]:
            try:
                decoded = self._decode_extra_url(extra_url.group(1))
                if decoded:
                    result["audio_url"] = decoded
                    result["download_url"] = decoded
            except:
                pass

        # 从页面直接搜索 mp3 URL (备选)
        if not result["audio_url"]:
            mp3_match = re.search(r'(?:src|href)=["\']([^"\']*\.mp3[^"\']*)["\']', html_str)
            if mp3_match:
                result["audio_url"] = mp3_match.group(1)

        return result

    @staticmethod
    def _decode_extra_url(encoded):
        """解码 mp3_extra_url（修改过的 base64）"""
        import base64
        fixed = encoded.replace("#", "H").replace("%", "S")
        padding = 4 - len(fixed) % 4
        if padding != 4:
            fixed += "=" * padding
        try:
            return base64.b64decode(fixed).decode('utf-8')
        except:
            return None

    # ==================== 工具 ====================

    def _fetch(self, url):
        return _fetch_url(url)

    def _fetch_api(self, url, data=None, referer=None):
        return _fetch_api(url, data=data, referer=referer)

    def _json(self, data, code=200):
        body = json.dumps(data, ensure_ascii=False).encode('utf-8')
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self._cors_headers()
        self.end_headers()
        self.wfile.write(body)

    def _cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")

    # ==================== 静态文件 ====================

    def _serve_static(self):
        path = self.path.lstrip("/")
        if path == "":
            path = "index.html"
        filepath = os.path.join(_WEB_DIR, path)

        if os.path.exists(filepath) and os.path.isfile(filepath):
            ct = "text/html"
            if path.endswith(".js"): ct = "application/javascript"
            elif path.endswith(".css"): ct = "text/css"
            elif path.endswith(".wasm"): ct = "application/wasm"
            elif path.endswith(".png"): ct = "image/png"
            elif path.endswith(".svg"): ct = "image/svg+xml"
            elif path.endswith(".otf"): ct = "font/otf"
            elif path.endswith(".ttf"): ct = "font/ttf"

            with open(filepath, "rb") as f:
                data = f.read()
            self.send_response(200)
            self.send_header("Content-Type", ct)
            self.send_header("Cache-Control", "no-cache")
            self.end_headers()
            self.wfile.write(data)
        else:
            with open(os.path.join(_WEB_DIR, "index.html"), "rb") as f:
                data = f.read()
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(data)

    def log_message(self, format, *args):
        pass

if __name__ == "__main__":
    print(f"MelodyBox Server: http://localhost:{PORT}")
    print(f"Music source: {GEQUHAI}")
    server = socketserver.ThreadingTCPServer(("0.0.0.0", PORT), MelodyServer)
    server.daemon_threads = True
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped")
        server.shutdown()
