"""
MelodyBox Windows 桌面应用
- 内置服务器
- 原生窗口，不跳浏览器
- 使用 Windows WebView2 控件
"""
import os
import sys
import json
import threading
import time
import ctypes
import ctypes.wintypes

PORT = 8090

def get_base_dir():
    if getattr(sys, 'frozen', False):
        return sys._MEIPASS
    return os.path.dirname(os.path.abspath(__file__))

def start_server():
    """后台线程启动 HTTP 服务器"""
    base = get_base_dir()
    os.chdir(base)
    sys.path.insert(0, base)

    import socketserver
    from server import MelodyServer

    server = socketserver.ThreadingTCPServer(("0.0.0.0", PORT), MelodyServer)
    server.daemon_threads = True
    print(f"服务器: http://localhost:{PORT}")
    server.serve_forever()

def create_window():
    """使用 Win32 API 创建带 WebView 的原生窗口"""
    user32 = ctypes.windll.user32
    kernel32 = ctypes.windll.kernel32

    # 注册窗口类
    WNDPROC = ctypes.WINFUNCTYPE(ctypes.c_long, ctypes.wintypes.HWND, ctypes.wintypes.UINT, ctypes.wintypes.WPARAM, ctypes.wintypes.LPARAM)

    wc = ctypes.wintypes.WNDCLASSEXW()
    wc.cbSize = ctypes.sizeof(wc)
    wc.lpfnWndProc = WNDPROC(_wnd_proc)
    wc.hInstance = kernel32.GetModuleHandleW(None)
    wc.lpszClassName = "MelodyBoxWindow"
    wc.hbrBackground = user32.GetSysColorBrush(1)  # COLOR_BACKGROUND

    atom = user32.RegisterClassExW(ctypes.byref(wc))

    # 创建窗口
    hwnd = user32.CreateWindowExW(
        0, atom, "MelodyBox - 音乐下载器",
        0xCF0000,  # WS_OVERLAPPEDWINDOW
        ctypes.wintypes.CW_USEDEFAULT, ctypes.wintypes.CW_USEDEFAULT,
        420, 800,
        None, None, kernel32.GetModuleHandleW(None), None
    )

    # 创建 WebBrowser OLE 控件
    _create_webview(hwnd)

    user32.ShowWindow(hwnd, 5)  # SW_SHOW
    user32.UpdateWindow(hwnd)

    # 消息循环
    msg = ctypes.wintypes.MSG()
    while user32.GetMessageW(ctypes.byref(msg), None, 0, 0):
        user32.TranslateMessage(ctypes.byref(msg))
        user32.DispatchMessageW(ctypes.byref(msg))

def _create_webview(parent_hwnd):
    """使用 IE WebBrowser 控件（Windows 自带，无需安装）"""
    try:
        import comtypes.client as cc
        cc.GetModule(('{EAB22AC0-30C1-11CF-A7EB-0000C05BAE0B}', 1, 1))
        import comtypes.gen.SHDocVw as ie

        # 获取窗口尺寸
        user32 = ctypes.windll.user32
        rect = ctypes.wintypes.RECT()
        user32.GetClientRect(parent_hwnd, ctypes.byref(rect))

        ie_ctrl = cc.CreateObject("Shell.Explorer.2", interface=ie.IWebBrowser2)
        ie_ctrl.Visible = True
        ie_ctrl.Left = 0
        ie_ctrl.Top = 0
        ie_ctrl.Width = 420
        ie_ctrl.Height = 800

        url = f"http://localhost:{PORT}"
        ie_ctrl.Navigate(url)
        print(f"WebView 加载: {url}")
    except Exception as e:
        print(f"WebView 创建失败: {e}")
        # 备选：用 Edge 的 app 模式
        import subprocess
        subprocess.Popen([
            "cmd", "/c", "start", "msedge",
            f"--app=http://localhost:{PORT}",
            "--new-window",
            f"--window-size=420,800"
        ], shell=True)

_wnd_proc = None

@ctypes.WINFUNCTYPE(ctypes.c_long, ctypes.wintypes.HWND, ctypes.wintypes.UINT, ctypes.wintypes.WPARAM, ctypes.wintypes.LPARAM)
def _wnd_proc(hwnd, msg, wparam, lparam):
    WM_DESTROY = 0x0002
    if msg == WM_DESTROY:
        ctypes.windll.user32.PostQuitMessage(0)
        return 0
    return ctypes.windll.user32.DefWindowProcW(hwnd, msg, wparam, lparam)

def main():
    # 启动服务器线程
    t = threading.Thread(target=start_server, daemon=True)
    t.start()
    time.sleep(2)

    # 尝试用 Edge App 模式（最可靠的方式）
    try:
        import subprocess
        subprocess.Popen([
            "cmd", "/c", "start", "msedge",
            f"--app=http://localhost:{PORT}",
            "--new-window",
            f"--window-size=420,800"
        ], shell=True)
        print("已打开应用窗口")
    except:
        pass

    # 保持运行
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("已退出")

if __name__ == "__main__":
    main()
