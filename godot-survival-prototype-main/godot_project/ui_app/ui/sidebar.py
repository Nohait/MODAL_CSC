from pathlib import Path

from PyQt6.QtCore import pyqtSignal, Qt
from PyQt6.QtWidgets import QWidget, QVBoxLayout, QPushButton
from PyQt6.QtGui import QIcon


class SidebarWidget(QWidget):
    sig_generate = pyqtSignal()
    sig_cancel = pyqtSignal()
    sig_tweak = pyqtSignal()
    sig_regenerate = pyqtSignal()
    sig_accept = pyqtSignal()

    def __init__(self, icons_dir: Path, parent=None):
        super().__init__(parent)
        self.setObjectName("Sidebar")
        layout = QVBoxLayout(self)
        layout.setAlignment(Qt.AlignmentFlag.AlignTop | Qt.AlignmentFlag.AlignHCenter)
        layout.setSpacing(12)

        self.btn_generate = self._make_button("Generate", icons_dir / "generate.svg")
        self.btn_cancel = self._make_button("Cancel", icons_dir / "cancel.svg")
        self.btn_tweak = self._make_button("Tweak", icons_dir / "tweak.svg")
        self.btn_regen = self._make_button("Regenerate", icons_dir / "regen.svg")
        self.btn_accept = self._make_button("Accept", icons_dir / "accept.svg")

        layout.addWidget(self.btn_generate)
        layout.addWidget(self.btn_cancel)
        layout.addWidget(self.btn_tweak)
        layout.addWidget(self.btn_regen)
        layout.addWidget(self.btn_accept)
        layout.addStretch()

        self.btn_generate.clicked.connect(self.sig_generate)
        self.btn_cancel.clicked.connect(self.sig_cancel)
        self.btn_tweak.clicked.connect(self.sig_tweak)
        self.btn_regen.clicked.connect(self.sig_regenerate)
        self.btn_accept.clicked.connect(self.sig_accept)

        self.btn_cancel.setEnabled(False)

    def _make_button(self, tooltip: str, icon_path: Path) -> QPushButton:
        btn = QPushButton(self)
        btn.setToolTip(tooltip)
        btn.setText("")
        btn.setFixedSize(48, 48)
        if icon_path and icon_path.exists():
            btn.setIcon(QIcon(str(icon_path)))
            btn.setIconSize(btn.size() * 0.6)
        btn.setStyleSheet("border-radius: 12px;")
        return btn

    def set_running(self, running: bool):
        self.btn_generate.setEnabled(not running)
        self.btn_tweak.setEnabled(not running)
        self.btn_regen.setEnabled(not running)
        self.btn_accept.setEnabled(not running)
        self.btn_cancel.setEnabled(running)


__all__ = ["SidebarWidget"]
