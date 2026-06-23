"""MelodyBox Cloud Server - Render/Railway deploy"""
import os, re, json, html as hmod, urllib.request, urllib.parse, http.cookiejar
from flask import Flask, request, jsonify, send_from_directory

app = Flask(__name__, static_folder='build/web', static_url_path='')
GEQUHAI = "https://www.gequhai.com"

# Cookie session for gequhai.com
_cj = http.cookiejar.CookieJar()
_opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(_cj))

def fetch(url, data=None):
    req = urllib.request.Request(url, data=data)
    req.add_header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120")
    if data:
        req.add_header("Content-Type", "application/x-www-form-urlencoded")
        req.add_header("X-Requested-With", "Http")
        req.add_header("X-Custom-Header", "Key")
    req.add_header("Referer", GEQUHAI + "/")
    with _opener.open(req, timeout=20) as resp:
        return resp.read().decode('utf-8', errors='ignore')

# ===== API Routes =====
@app.route('/api/search')
def api_search():
    q = request.args.get('q', '').strip()
    if not q: return jsonify({"tracks": [], "total": 0})
    try:
        html = fetch(f"{GEQUHAI}/s/{urllib.parse.quote(q)}")
        tracks = parse_results(html)
        return jsonify({"tracks": tracks, "total": len(tracks)})
    except Exception as e:
        return jsonify({"error": str(e), "tracks": [], "total": 0})

@app.route('/api/hot')
def api_hot():
    tracks = []
    for kw in ['周杰伦', '抖音', '热门', '新歌', '流行']:
        if len(tracks) >= 20: break
        try:
            html = fetch(f"{GEQUHAI}/s/{urllib.parse.quote(kw)}")
            tracks.extend(parse_results(html)[:6])
        except: pass
    return jsonify({"tracks": tracks[:30], "total": len(tracks)})

@app.route('/api/play/<int:song_id>')
def api_play(song_id):
    try:
        html = fetch(f"{GEQUHAI}/play/{song_id}")
        result = {"song_name": "", "artist": "", "cover_url": "", "audio_url": ""}
        for key in ['mp3_title', 'mp3_author', 'mp3_cover']:
            m = re.search(rf"window\.{key}\s*=\s*'([^']*)'", html)
            if m: result[key.replace('mp3_', '')] = hmod.unescape(m.group(1)).replace('song_name', 'title')
        # Get audio URL
        pid = re.search(r"window\.play_id\s*=\s*'([^']*)'", html)
        mtype = re.search(r"window\.mp3_type\s*=\s*(\d+)", html)
        if pid:
            data = urllib.parse.urlencode({"id": pid.group(1), "type": mtype.group(1) if mtype else "0"}).encode()
            resp = fetch(f"{GEQUHAI}/api/music", data=data)
            d = json.loads(resp)
            if d.get("code") == 200:
                result["audio_url"] = d["data"].get("url", "")
        # Title/artist
        t = re.search(r"window\.mp3_title\s*=\s*'([^']*)'", html)
        a = re.search(r"window\.mp3_author\s*=\s*'([^']*)'", html)
        c = re.search(r"window\.mp3_cover\s*=\s*'([^']*)'", html)
        if t: result["song_name"] = hmod.unescape(t.group(1))
        if a: result["artist"] = hmod.unescape(a.group(1))
        if c: result["cover_url"] = c.group(1)
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e), "audio_url": ""})

# ===== Static files =====
@app.route('/')
def index():
    return send_from_directory(app.static_folder, 'index.html')

@app.route('/<path:path>')
def static_files(path):
    return send_from_directory(app.static_folder, path)

# ===== Helpers =====
def parse_results(html):
    tracks = []
    rows = re.findall(r"<tr>\s*<td[^>]*?>(\d+)</td>\s*<td>\s*<a\s+href=\"(/play/(\d+))\"[^>]*?>\s*(.*?)\s*</a>", html, re.DOTALL)
    for m in rows:
        name = hmod.unescape(re.sub(r'<[^>]+>', '', m[3])).strip()
        artist_m = re.search(re.escape(m[1]) + r'.*?<td[^>]*?style="color:\s*#666[^"]*"[^>]*?>(.*?)</td>', html, re.DOTALL)
        artist = hmod.unescape(artist_m.group(1)).strip() if artist_m else ""
        artist = re.sub(r'<[^>]+>', '', artist)
        tracks.append({"id": int(m[2]), "name": name, "artist_name": artist, "album_name": "", "image_url": "", "rank": int(m[0])})
    return tracks

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8090))
    app.run(host='0.0.0.0', port=port)
