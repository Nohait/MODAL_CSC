from PyQt6.QtWidgets import QSplashScreen
from PyQt6.QtGui import QPixmap
from PyQt6.QtCore import Qt, QTimer


class SplashScreen(QSplashScreen):
    def __init__(self, pixmap_path):
        pixmap = QPixmap(str(pixmap_path)) if pixmap_path else QPixmap()
        super().__init__(pixmap)
        self.setWindowFlag(Qt.WindowType.FramelessWindowHint)
        self.setWindowModality(Qt.WindowModality.ApplicationModal)

    def show_for(self, ms, on_finish):
        self.show()
        QTimer.singleShot(ms, on_finish)


__all__ = ["SplashScreen"]
