from PyQt6.QtCore import pyqtSignal, QPropertyAnimation, QEasingCurve
from PyQt6.QtWidgets import (
    QWidget,
    QVBoxLayout,
    QLabel,
    QTextEdit,
    QListWidget,
    QListWidgetItem,
)


class PromptWorkspace(QWidget):
    sig_generate = pyqtSignal(str)
    sig_tweak = pyqtSignal(str)
    sig_regenerate = pyqtSignal()
    sig_accept = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setObjectName("PromptWorkspace")
        self._init_ui()

    def _init_ui(self):
        layout = QVBoxLayout(self)
        self.title = QLabel("Describe your asset", self)
        self.title.setObjectName("TitleLabel")

        self.prompt_edit = QTextEdit(self)
        self.prompt_edit.setPlaceholderText("Type your prompt here...")
        self.prompt_edit.setStyleSheet("padding: 12px; font-size: 14px;")
        self.prompt_edit.setMinimumHeight(260)

        self.suggestions = QListWidget(self)
        for text in [
            "Small green pine tree",
            "Rusty metal crate",
            "Cracked concrete ruin",
            "Dense jungle bush",
        ]:
            QListWidgetItem(text, self.suggestions)
        self.suggestions.itemClicked.connect(self._apply_suggestion)

        layout.addWidget(self.title)
        layout.addWidget(self.prompt_edit)
        layout.addWidget(self.suggestions)

        self._placeholder_anim = QPropertyAnimation(self.prompt_edit, b"windowOpacity")
        self._placeholder_anim.setDuration(1200)
        self._placeholder_anim.setStartValue(0.7)
        self._placeholder_anim.setEndValue(1.0)
        self._placeholder_anim.setEasingCurve(QEasingCurve.Type.InOutQuad)
        self._placeholder_anim.setLoopCount(-1)
        self._placeholder_anim.start()

    def _apply_suggestion(self, item: QListWidgetItem):
        self.prompt_edit.setPlainText(item.text())

    def get_prompt(self) -> str:
        return self.prompt_edit.toPlainText().strip()

    def set_prompt(self, text: str):
        self.prompt_edit.setPlainText(text)

    # Legacy signal hooks (not used directly but kept for compatibility)
    def emit_generate(self):
        self.sig_generate.emit(self.get_prompt())

    def emit_tweak(self):
        self.sig_tweak.emit(self.get_prompt())


__all__ = ["PromptWorkspace"]
