import sys
from pathlib import Path

CURRENT_FILE = Path(__file__).resolve()
PROJECT_ROOT = CURRENT_FILE.parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

import os
from pathlib import Path

from PyQt6.QtWidgets import QApplication
from PyQt6.QtGui import QPixmap, QIcon

from ui_app.ui.main_window import MainWindow
from ui_app.ui.splash_screen import SplashScreen
from ui_app.backend.config import PREVIEW_PATH


MAIN_WINDOW = None


def load_placeholder_if_needed():
    if PREVIEW_PATH.exists():
        return
    placeholder = PROJECT_ROOT / "ui_app" / "assets" / "preview_placeholder.png"
    if placeholder.exists():
        PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
        placeholder_pix = QPixmap(str(placeholder))
        if not placeholder_pix.isNull():
            placeholder_pix.save(str(PREVIEW_PATH))


def main():
    if os.name == "nt":
        try:
            import ctypes

            ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID("AXC.AssetGenerator")
        except Exception:
            pass

    app = QApplication(sys.argv)
    icons_dir = PROJECT_ROOT / "ui_app" / "assets" / "icons"
    icons_dir.mkdir(parents=True, exist_ok=True)
    icon_path = icons_dir / "AXC.ico"
    if icon_path.exists():
        app.setWindowIcon(QIcon(str(icon_path)))
    load_placeholder_if_needed()
    splash = SplashScreen(icon_path if icon_path.exists() else None)

    def continue_startup():
        global MAIN_WINDOW
        MAIN_WINDOW = MainWindow()
        if icon_path.exists():
            MAIN_WINDOW.setWindowIcon(QIcon(str(icon_path)))
        MAIN_WINDOW.show()
        splash.finish(MAIN_WINDOW)

    splash.show_for(1500, continue_startup)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
