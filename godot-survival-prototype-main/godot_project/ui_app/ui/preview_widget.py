from pathlib import Path

from PyQt6.QtCore import QTimer, QPropertyAnimation, Qt
from PyQt6.QtWidgets import (
    QLabel,
    QWidget,
    QVBoxLayout,
    QHBoxLayout,
    QFrame,
    QTabWidget,
    QSizePolicy,
    QGraphicsOpacityEffect,
    QGraphicsDropShadowEffect,
)
from PyQt6.QtGui import QPixmap, QMovie, QColor

try:
    import imageio.v2 as imageio
except ImportError:  # graceful fallback if imageio not installed
    imageio = None



class SpinnerWidget(QWidget):
    def __init__(self, icons_dir: Path | None = None, parent=None):
        super().__init__(parent)
        self.setFixedHeight(48)
        self.icons = []
        if icons_dir:
            for name in ["gear1.png", "gear2.png", "gear3.png", "gear.gif", "gear.svg"]:
                p = icons_dir / name
                if p.exists():
                    pixmap = QPixmap(str(p))
                    if not pixmap.isNull():
                        self.icons.append(pixmap)
        self.label = QLabel(self)
        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.addStretch()
        layout.addWidget(self.label)
        layout.addStretch()
        self.timer = QTimer(self)
        self.timer.setInterval(120)
        self.timer.timeout.connect(self._rotate)
        self._idx = 0
        self._rotate()

    def _rotate(self):
        if not self.icons:
            return
        self.label.setPixmap(
            self.icons[self._idx].scaled(
                32,
                32,
                Qt.AspectRatioMode.KeepAspectRatio,
                Qt.TransformationMode.SmoothTransformation,
            )
        )
        self._idx = (self._idx + 1) % len(self.icons)

    def start(self):
        if self.icons:
            self.timer.start()
            self.show()

    def stop(self):
        self.timer.stop()
        self.hide()


class PreviewWidget(QWidget):
    def __init__(self, parent=None, icons_dir: Path | None = None):
        super().__init__(parent)
        self.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        self.icons_dir = icons_dir
        self._current_pixmap: QPixmap | None = None
        self._preview_path: Path | None = None
        self._last_mtime = 0.0

        self.frame = QFrame(self)
        self.frame.setObjectName("PreviewFrame")
        self.frame.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        self.frame.setStyleSheet(
            """
            QFrame#PreviewFrame {
                background-color: #0F131A;
                border: 1px solid #1B2631;
                border-radius: 12px;
                padding: 16px;
            }
            """
        )

        shadow = QGraphicsDropShadowEffect(self.frame)
        shadow.setBlurRadius(35)
        shadow.setOffset(0, 8)
        shadow.setColor(QColor(0, 0, 0, 140))
        self.frame.setGraphicsEffect(shadow)

        self.image_label = QLabel(self.frame)
        self.image_label.setScaledContents(False)
        self.image_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.image_label.setSizePolicy(
            QSizePolicy.Policy.Expanding,
            QSizePolicy.Policy.Expanding,
        )

        self.turntable_label = QLabel(self.frame)
        self.turntable_label.setScaledContents(True)
        self.turntable_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.turntable_label.setSizePolicy(
            QSizePolicy.Policy.Expanding,
            QSizePolicy.Policy.Expanding,
        )

        self.opacity_effect = QGraphicsOpacityEffect(self.image_label)
        self.image_label.setGraphicsEffect(self.opacity_effect)

        self.fade_anim = QPropertyAnimation(self.opacity_effect, b"opacity", self)
        self.fade_anim.setDuration(350)
        self.fade_anim.setStartValue(0.0)
        self.fade_anim.setEndValue(1.0)

        inner_layout = QVBoxLayout(self.frame)
        inner_layout.setContentsMargins(0, 0, 0, 0)
        inner_layout.setSpacing(0)
        self.corner_spinner = SpinnerWidget(self.icons_dir, self.frame)
        self.corner_spinner.setFixedSize(36, 36)
        self.corner_spinner.hide()
        spinner_row = QHBoxLayout()
        spinner_row.setContentsMargins(0, 0, 0, 0)
        spinner_row.addStretch()
        spinner_row.addWidget(self.corner_spinner)
        inner_layout.addLayout(spinner_row)
        self.tabs = self._build_tabs()
        self.tabs.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        inner_layout.addWidget(self.tabs, stretch=1)

        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(12)
        main_layout.addWidget(self.frame, stretch=1)
        self.setLayout(main_layout)

        self._timer = QTimer(self)
        self._timer.setInterval(500)
        self._timer.timeout.connect(self._check_refresh)

    def _build_tabs(self):
        self.tabs = QTabWidget(self.frame)
        static_tab = QWidget(self.tabs)
        turntable_tab = QWidget(self.tabs)

        static_layout = QVBoxLayout(static_tab)
        static_layout.setContentsMargins(0, 0, 0, 0)
        static_layout.setSpacing(0)
        image_container = QFrame(static_tab)
        image_container.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        image_container_layout = QVBoxLayout(image_container)
        image_container_layout.setContentsMargins(0, 0, 0, 0)
        image_container_layout.setSpacing(0)
        image_container_layout.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.image_label.setParent(image_container)
        image_container_layout.addWidget(self.image_label, alignment=Qt.AlignmentFlag.AlignCenter)
        static_layout.addWidget(image_container, stretch=1)
        static_layout.addStretch()
        static_tab.setLayout(static_layout)

        turntable_layout = QVBoxLayout(turntable_tab)
        turntable_layout.setContentsMargins(0, 0, 0, 0)
        turntable_layout.setSpacing(0)
        turntable_layout.setAlignment(Qt.AlignmentFlag.AlignCenter)
        turntable_layout.addWidget(self.turntable_label, alignment=Qt.AlignmentFlag.AlignCenter)
        turntable_layout.addStretch()
        turntable_tab.setLayout(turntable_layout)

        self.tabs.addTab(static_tab, "Static Preview")
        self.tabs.addTab(turntable_tab, "Turntable Preview")
        self.tabs.setObjectName("PreviewTabs")
        return self.tabs

    def set_pixmap(self, pix: QPixmap):
        self.update_image(pix)
        self.opacity_effect.setOpacity(0.0)
        self.fade_anim.start()

    def update_image(self, pixmap: QPixmap | None = None):
        if pixmap is not None:
            self._current_pixmap = pixmap

        if self._current_pixmap is None or self._current_pixmap.isNull():
            self.image_label.clear()
            return

        container = self.image_label.parentWidget()
        if not container:
            container_w = self.width()
            container_h = self.height()
        else:
            container_w = container.width()
            container_h = container.height()

        container_w = max(40, container_w)
        container_h = max(40, container_h)

        scaled_pixmap = self._current_pixmap.scaled(
            container_w,
            container_h,
            Qt.AspectRatioMode.KeepAspectRatio,
            Qt.TransformationMode.SmoothTransformation,
        )
        self.image_label.setPixmap(scaled_pixmap)

    def setAlignment(self, alignment):
        try:
            self.image_label.setAlignment(alignment)
        except Exception:
            pass

    def set_preview_path(self, path: Path):
        self._preview_path = path

    def enable_auto_refresh(self):
        self._timer.start()

    def disable_auto_refresh(self):
        self._timer.stop()

    def _check_refresh(self):
        if not self._preview_path:
            return
        if not self._preview_path.exists():
            return
        mtime = self._preview_path.stat().st_mtime
        if mtime <= self._last_mtime:
            return
        pix = QPixmap(str(self._preview_path))
        if not pix.isNull():
            self.set_pixmap(pix)
            self._last_mtime = mtime

    def set_turntable_movie(self, movie):
        self.turntable_label.setMovie(movie)
        movie.start()

    def set_turntable_pixmap(self, pix: QPixmap | None):
        if pix:
            self.turntable_label.setPixmap(pix)
        else:
            self.turntable_label.clear()

    def set_turntable_frames(self, frames_dir: Path):
        if not frames_dir.exists() or not frames_dir.is_dir():
            return
        if imageio is None:
            return
        frames = sorted(frames_dir.glob("*.png"))
        if not frames:
            return
        gif_path = frames_dir / "turntable.gif"
        try:
            imgs = []
            for f in frames:
                imgs.append(imageio.imread(f))
            imageio.mimsave(gif_path, imgs, duration=0.08, loop=0)
            movie = QMovie(str(gif_path))
            self.turntable_label.setMovie(movie)
            movie.start()
            movie.setScaledSize(self.turntable_label.size())
            self.tabs.setCurrentIndex(1)
        except Exception:
            pass

    def resizeEvent(self, event):
        super().resizeEvent(event)
        # Rescale the static preview pixmap whenever the widget grows/shrinks
        # so it fills the available frame instead of staying at the tiny
        # size it had at initial load.
        self.update_image()
        if self.turntable_label.movie():
            self.turntable_label.movie().setScaledSize(self.turntable_label.size())


__all__ = ["PreviewWidget", "SpinnerWidget"]
