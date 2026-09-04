from pathlib import Path

from PyQt6.QtGui import QIcon
from PyQt6.QtWidgets import QDialog, QVBoxLayout, QLabel, QDialogButtonBox


class AboutDialog(QDialog):
    def __init__(self, parent=None, icon_path: Path | None = None):
        super().__init__(parent)
        self.setWindowTitle("About AXC Asset Generator")
        if icon_path and icon_path.exists():
            self.setWindowIcon(QIcon(str(icon_path)))
        layout = QVBoxLayout(self)

        title = QLabel("<b>AXC Asset Generator</b>")
        version = QLabel("Version: 1.0.0")
        author = QLabel("Author: AXC")
        links = QLabel("GitHub: https://github.com/yourname<br>Website: https://yourwebsite.com")
        links.setOpenExternalLinks(True)

        layout.addWidget(title)
        layout.addWidget(version)
        layout.addWidget(author)
        layout.addWidget(links)

        buttons = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok)
        buttons.accepted.connect(self.accept)
        layout.addWidget(buttons)


__all__ = ["AboutDialog"]
