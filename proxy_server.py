"""
MelodyBox 本地代理服务器
转发请求到 Deezer API，解决浏览器 CORS 跨域问题
"""
import http.server
import urllib.request
import urllib.parse
import json
import sys

PORT = 8081
DEEZER_API = "https://api.deezer.com"

class CORSProxy(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        # 构建目标 URL
        target_url = DEEZER_API + self.path
        print(f"[代理] GET {target_url}")

        try:
            req = urllib.request.Request(target_url)
            req.add_header("Accept", "application/json")

            with urllib.request.urlopen(req, timeout=15) as response:
                data = response.read()

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
            self.send_header("Access-Control-Allow-Headers", "*")
            self.end_headers()
            self.wfile.write(data)
            print(f"[代理] 成功: {len(data)} bytes")
        except Exception as e:
            print(f"[代理] 失败: {e}")
            self.send_response(502)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            error_json = json.dumps({"error": str(e), "data": []})
            self.wfile.write(error_json.encode())

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()

    def log_message(self, format, *args):
        pass  # 安静模式

if __name__ == "__main__":
    print(f"MelodyBox API Proxy: http://localhost:{PORT}")
    print(f"Forwarding to: {DEEZER_API}")
    server = http.server.HTTPServer(("0.0.0.0", PORT), CORSProxy)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n代理已关闭")
        server.shutdown()
