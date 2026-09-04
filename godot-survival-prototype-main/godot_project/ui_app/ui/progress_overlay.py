from pathlib import Path
import math

from PyQt6.QtCore import pyqtSignal, Qt, QPropertyAnimation, QEasingCurve
from PyQt6.QtGui import QMovie, QPainter, QPen, QColor
from PyQt6.QtWidgets import QWidget, QVBoxLayout, QLabel, QPushButton


class ProgressOverlay(QWidget):
    sig_cancel = pyqtSignal()

    def __init__(self, parent=None, icon_dir: Path | None = None):
        super().__init__(parent)
        self.setAttribute(Qt.WidgetAttribute.WA_TransparentForMouseEvents, False)
        self.setWindowFlags(Qt.WindowType.FramelessWindowHint | Qt.WindowType.SubWindow)
        self.setStyleSheet("background-color: rgba(0, 0, 0, 180); color: #e0e0e0;")
        self.percent = 0

        self.spinner = QLabel(self)
        gif_path = None
        if icon_dir:
            candidate = icon_dir / "gear.gif"
            if candidate.exists():
                gif_path = candidate
        self.movie = QMovie(str(gif_path)) if gif_path else None
        if self.movie:
            self.spinner.setMovie(self.movie)

        self.progress_label = QLabel("Generating asset... 0%", self)
        self.progress_label.setAlignment(Qt.AlignmentFlag.AlignCenter)

        self.cancel_btn = QPushButton("Cancel Render", self)
        self.cancel_btn.clicked.connect(self.sig_cancel)
        self.cancel_btn.setStyleSheet("border: 1px solid #00E5FF;")

        layout = QVBoxLayout()
        layout.addWidget(self.spinner, alignment=Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(self.progress_label)
        layout.addWidget(self.cancel_btn)
        self.setLayout(layout)
        self.hide()

        self._pulse = QPropertyAnimation(self.progress_label, b"windowOpacity", self)
        self._pulse.setDuration(800)
        self._pulse.setStartValue(0.6)
        self._pulse.setEndValue(1.0)
        self._pulse.setEasingCurve(QEasingCurve.Type.InOutQuad)
        self._pulse.setLoopCount(-1)

    def show_overlay(self):
        if self.parent():
            self.setGeometry(self.parent().rect())
        if self.movie:
            self.movie.start()
        self._pulse.start()
        self.show()
        self.raise_()

    def hide_overlay(self):
        if self.movie:
            self.movie.stop()
        self._pulse.stop()
        self.hide()

    def set_progress(self, percent: int):
        self.percent = max(0, min(100, percent))
        self.progress_label.setText(f"Generating asset... {self.percent}%")
        self.update()

    def paintEvent(self, event):
        super().paintEvent(event)
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        center = self.rect().center()
        radius = min(self.width(), self.height()) // 4
        rect = self.rect().center()
        ring_rect = self.rect().adjusted(
            center.x() - radius,
            center.y() - radius,
            -(self.width() - (center.x() + radius)),
            -(self.height() - (center.y() + radius)),
        )
        pen = QPen(QColor("#00E5FF"), 8)
        painter.setPen(pen)
        painter.setBrush(Qt.BrushStyle.NoBrush)
        span_angle = int(360 * 16 * (self.percent / 100.0))
        painter.drawArc(ring_rect, 90 * 16, -span_angle)
        painter.end()


__all__ = ["ProgressOverlay"]
