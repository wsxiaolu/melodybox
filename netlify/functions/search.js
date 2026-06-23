const BASE = "https://www.gequhai.com";
exports.handler = async (event) => {
  const q = event.queryStringParameters.q || "";
  const path = event.path;
  
  try {
    // Search endpoint
    if (path.includes("/api/search")) {
      const resp = await fetch(BASE + "/s/" + encodeURIComponent(q));
      const html = await resp.text();
      const tracks = parseResults(html);
      return { statusCode: 200, headers: {"content-type":"application/json","access-control-allow-origin":"*"}, body: JSON.stringify({tracks, total: tracks.length}) };
    }
    // Hot endpoint
    if (path.includes("/api/hot")) {
      let tracks = [];
      for (let kw of ["周杰伦","抖音","热门","新歌"]) {
        if (tracks.length >= 20) break;
        try {
          const resp = await fetch(BASE + "/s/" + encodeURIComponent(kw));
          const html = await resp.text();
          tracks.push(...parseResults(html).slice(0,6));
        } catch(e) {}
      }
      return { statusCode: 200, headers: {"content-type":"application/json","access-control-allow-origin":"*"}, body: JSON.stringify({tracks: tracks.slice(0,30), total: tracks.length}) };
    }
    // Play endpoint
    if (path.includes("/api/play/")) {
      const id = path.split("/").pop();
      const resp = await fetch(BASE + "/play/" + id);
      const html = await resp.text();
      const pid = (html.match(/window\.play_id\s*=\s*'([^']*)'/) || [])[1];
      let audio_url = "", song_name = "", cover_url = "";
      if (pid) {
        const r2 = await fetch(BASE + "/api/music", {
          method: "POST",
          headers: {"X-Requested-With":"Http","X-Custom-Header":"Key","Content-Type":"application/x-www-form-urlencoded"},
          body: "id=" + pid + "&type=0"
        });
        const d = await r2.json();
        if (d.code === 200) audio_url = d.data.url || "";
      }
      let t = html.match(/window\.mp3_title\s*=\s*'([^']*)'/);
      let a = html.match(/window\.mp3_author\s*=\s*'([^']*)'/);
      let c = html.match(/window\.mp3_cover\s*=\s*'([^']*)'/);
      if (t) song_name = t[1];
      if (a) /* artist from match */;
      if (c) cover_url = c[1];
      return { statusCode: 200, headers: {"content-type":"application/json","access-control-allow-origin":"*"}, body: JSON.stringify({audio_url, song_name, cover_url}) };
    }
    return { statusCode: 404, body: "Not found" };
  } catch(e) {
    return { statusCode: 500, body: JSON.stringify({error: e.message}) };
  }
};

function parseResults(html) {
  let tracks = [];
  let re = /<tr>\s*<td[^>]*?>(\d+)<\/td>\s*<td>\s*<a\s+href="\/play\/(\d+)"[^>]*?>\s*(.*?)\s*<\/a>/gs;
  let m;
  while (m = re.exec(html)) {
    let name = m[3].replace(/<[^>]+>/g,'').trim();
    // find artist in next td
    let idx = m.index + m[0].length;
    let rest = html.slice(idx, idx + 500);
    let am = rest.match(/<td[^>]*?style="color:\s*#666[^"]*"[^>]*?>(.*?)<\/td>/);
    let artist = am ? am[1].replace(/<[^>]+>/g,'').trim() : "";
    tracks.push({id: parseInt(m[2]), name, artist_name: artist, rank: parseInt(m[1]), image_url:"", audio_url:"", album_name:""});
  }
  return tracks;
}
