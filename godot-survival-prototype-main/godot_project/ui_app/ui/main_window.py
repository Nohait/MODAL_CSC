import shutil
from pathlib import Path

from PyQt6.QtCore import Qt, QSize, QFile, QTextStream
from PyQt6.QtWidgets import (
    QMainWindow,
    QWidget,
    QHBoxLayout,
    QVBoxLayout,
    QTextEdit,
    QListWidget,
    QLabel,
    QFrame,
    QToolButton,
    QProgressBar,
    QMessageBox,
    QMenuBar,
    QMenu,
    QGraphicsDropShadowEffect,
    QSizePolicy,
)
from PyQt6.QtGui import QAction, QIcon, QMovie, QCursor, QColor

from ui_app.backend import blender_runner
from ui_app.backend.config import PREVIEW_PATH, FINAL_ASSETS_PATH, verify_paths
from ui_app.ui.preview_widget import PreviewWidget
from ui_app.ui.about_dialog import AboutDialog
from ui_app.ui.worker import BlenderWorker
from ui_app.ui.progress_overlay import ProgressOverlay

ROW_SPACING = 12


class HelpOverlay(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setObjectName("HelpOverlay")
        self.setAttribute(Qt.WidgetAttribute.WA_StyledBackground, True)
        self.setWindowFlags(Qt.WindowType.FramelessWindowHint | Qt.WindowType.Tool)
        self.setStyleSheet("#HelpOverlay { background-color: rgba(0, 0, 0, 160); }")
        overlay_layout = QVBoxLayout(self)
        overlay_layout.setContentsMargins(0, 0, 0, 0)
        overlay_layout.setAlignment(Qt.AlignmentFlag.AlignCenter)

        self.container = QWidget(self)
        self.container.setObjectName("HelpOverlayContainer")
        self.container.setStyleSheet(
            """
#HelpOverlayContainer {
    background-color: #0f181f;
    border: 1px solid #1f3b4a;
    border-radius: 12px;
}
QLabel#HelpTitle {
    color: #8acaff;
    font-size: 15px;
    font-weight: 600;
}
QLabel#HelpLabel {
    color: #dfe8f2;
    font-size: 12px;
}
"""
        )
        glow = QGraphicsDropShadowEffect(self.container)
        glow.setBlurRadius(36)
        glow.setOffset(0, 0)
        glow.setColor(QColor(0, 0, 0, 120))
        self.container.setGraphicsEffect(glow)

        container_layout = QVBoxLayout(self.container)
        container_layout.setContentsMargins(22, 18, 22, 18)
        container_layout.setSpacing(10)

        title = QLabel("Quick Help", self.container)
        title.setObjectName("HelpTitle")
        content = QLabel(
            (
                "<b>Buttons</b><br>"
                "Generate: create a new asset from your prompt.<br>"
                "Tweak: apply small changes to the current asset.<br>"
                "Regenerate: start over from scratch.<br>"
                "Accept: save the current asset to your library.<br>"
                "Zoom In/Out: adjust preview zoom.<br>"
                "Rotate: manually rotate the preview.<br>"
                "Folder: open your final assets folder.<br><br>"
                "<b>Prompt</b><br>"
                "Enter a clear description in the prompt area on the left. "
                "Use suggestions or type your own for best results.<br><br>"
                "<b>Preview & Turntable</b><br>"
                "Static preview shows the latest frame. "
                "Turntable tab plays the generated 360° spin; it scales to fit."
            ),
            self.container,
        )
        content.setObjectName("HelpLabel")
        content.setWordWrap(True)

        container_layout.addWidget(title)
        container_layout.addWidget(content)

        overlay_layout.addWidget(self.container, alignment=Qt.AlignmentFlag.AlignCenter)
        self.hide()

    def show_overlay(self, rect):
        self.setGeometry(rect)
        self.show()
        self.raise_()

    def mousePressEvent(self, event):
        if not self.container.geometry().contains(event.position().toPoint()):
            self.hide()
            event.accept()
            return
        super().mousePressEvent(event)


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("AI Asset Generator")
        self._load_icon()

        icons_dir = Path(__file__).resolve().parent.parent / "assets" / "icons"
        self.icons_dir = icons_dir
        self.preview = PreviewWidget(self, icons_dir)
        self.preview_frame = self.preview

        self.generate_btn = self._make_action_button("generate", "Generate")
        self.tweak_btn = self._make_action_button("tweak", "Tweak")
        self.regen_btn = self._make_action_button("regen", "Regenerate")
        self.accept_btn = self._make_action_button("accept", "Accept")

        self.zoom_in_btn = self._make_toolbar_button("zoom_in", "Zoom In")
        self.zoom_out_btn = self._make_toolbar_button("zoom_out", "Zoom Out")
        self.rotate_btn = self._make_toolbar_button("rotate", "Rotate")
        self.folder_btn = self._make_toolbar_button("folder", "Folder")

        self.preview_progress = QProgressBar(self)
        self.preview_progress.setRange(0, 100)
        self.preview_progress.hide()
        self.progress_overlay = ProgressOverlay(self.preview, icons_dir)
        self.help_overlay = HelpOverlay(self)

        self.prompt_input = QTextEdit(self)
        self.prompt_input.setPlaceholderText("Type your prompt here...")
        self.prompt_input.setMinimumHeight(146)

        self.history_list = QListWidget(self)
        self.history_list.setObjectName("consistencyPanel")
        self.history_list.setMinimumHeight(160)
        self.history_list.itemClicked.connect(lambda item: self.prompt_input.setPlainText(item.text()))

        self.style_label = QLabel("Style: Unknown", self)
        self.style_label.setObjectName("styleLabel")
        self.style_label.setAlignment(Qt.AlignmentFlag.AlignLeft | Qt.AlignmentFlag.AlignVCenter)

        self.generate_btn.clicked.connect(lambda: self.on_generate(self._current_prompt()))
        self.tweak_btn.clicked.connect(lambda: self.on_tweak(self._current_prompt()))
        self.regen_btn.clicked.connect(self.on_regenerate)
        self.accept_btn.clicked.connect(self.on_accept)

        self._init_ui()
        self._build_menu()
        self._apply_style()
        verify_paths()
        self.update_preview()

        self.progress_overlay.sig_cancel.connect(self.on_cancel)

    def _init_ui(self):
        root = QWidget(self)
        self.setCentralWidget(root)

        main_layout = QHBoxLayout(root)
        main_layout.setContentsMargins(20, 20, 20, 20)
        main_layout.setSpacing(28)

        sidebar_widget = QWidget(self)
        sidebar_widget.setFixedWidth(120)
        sidebar_widget.setSizePolicy(QSizePolicy.Policy.Fixed, QSizePolicy.Policy.Expanding)
        sidebar_layout = QVBoxLayout(sidebar_widget)
        sidebar_layout.setContentsMargins(0, 0, 0, 0)
        sidebar_layout.setSpacing(22)
        sidebar_layout.addStretch()

        for btn in [self.generate_btn, self.tweak_btn, self.regen_btn, self.accept_btn]:
            btn.setFixedSize(64, 64)
            btn.setIconSize(QSize(64, 64))
            btn_container = QVBoxLayout()
            btn_container.setSpacing(8)
            btn_container.addWidget(btn, alignment=Qt.AlignmentFlag.AlignHCenter)
            label = QLabel(btn.toolTip())
            label.setAlignment(Qt.AlignmentFlag.AlignHCenter)
            label.setStyleSheet(
                "font-size: 11px; color: #AFC7DA; font-weight: 500; margin-top: 8px;"
            )
            btn_container.addWidget(label, alignment=Qt.AlignmentFlag.AlignHCenter)
            sidebar_layout.addLayout(btn_container)

        sidebar_layout.addStretch()

        sidebar_divider = QFrame()
        sidebar_divider.setFixedWidth(1)
        sidebar_divider.setFrameShape(QFrame.Shape.VLine)
        sidebar_divider.setFrameShadow(QFrame.Shadow.Plain)
        sidebar_divider.setStyleSheet("background-color: #1D2530; border: none;")
        sidebar_divider.setSizePolicy(QSizePolicy.Policy.Fixed, QSizePolicy.Policy.Expanding)

        central_container = QWidget(self)
        central_container.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        central_layout = QHBoxLayout(central_container)
        central_layout.setContentsMargins(0, 0, 0, 0)
        central_layout.setSpacing(16)

        left_container = QWidget(central_container)
        left_layout = QVBoxLayout(left_container)
        left_layout.setContentsMargins(0, 0, 0, 0)
        left_layout.setSpacing(12)

        header = QLabel("Describe your asset")
        header.setObjectName("sectionHeader")
        header.setAlignment(Qt.AlignmentFlag.AlignLeft)
        left_layout.addWidget(header)

        left_layout.addWidget(self.prompt_input, stretch=4)

        history_title = QLabel("Recent prompts / hints")
        history_title.setObjectName("HistoryTitle")
        history_title.setAlignment(Qt.AlignmentFlag.AlignLeft)
        left_layout.addWidget(history_title)

        self.history_list.setMinimumHeight(180)
        self.history_list.setMaximumHeight(260)
        self.history_list.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        left_layout.addWidget(self.history_list, stretch=3)

        left_layout.addStretch()

        bottom_info = QFrame()
        bottom_info.setStyleSheet("border: 1px solid #1f3b4a; border-radius: 12px;")
        bottom_info_layout = QHBoxLayout(bottom_info)
        bottom_info_layout.setContentsMargins(12, 6, 12, 6)
        bottom_info_layout.addWidget(self.style_label)
        left_layout.addWidget(bottom_info)

        right_container = QWidget(central_container)
        right_layout = QVBoxLayout(right_container)
        right_layout.setAlignment(Qt.AlignmentFlag.AlignTop)
        right_layout.setContentsMargins(0, 0, 0, 0)
        right_layout.setSpacing(12)

        toolbar_row = QHBoxLayout()
        toolbar_row.setContentsMargins(0, 0, 0, 0)
        toolbar_row.setSpacing(18)
        toolbar_row.addStretch()
        for toolbar_btn in (
            self.zoom_in_btn,
            self.zoom_out_btn,
            self.rotate_btn,
            self.folder_btn,
        ):
            toolbar_btn.setFixedSize(40, 40)
            toolbar_btn.setIconSize(QSize(32, 32))
            toolbar_row.addWidget(toolbar_btn)
        help_btn = self._build_help_button()
        toolbar_row.addWidget(help_btn)
        right_layout.addLayout(toolbar_row)
        right_layout.addSpacing(10)
        self.preview_frame.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        right_layout.addWidget(self.preview_frame, stretch=1)
        right_layout.addWidget(self.preview_progress)

        # --- FIX: remove any accidental leftover widgets (e.g., stray dividers) from the right column ---
        for i in reversed(range(right_layout.count())):
            item = right_layout.itemAt(i)
            widget = item.widget()
            if widget and widget not in (self.preview_frame, self.preview_progress):
                right_layout.removeWidget(widget)
                widget.setParent(None)

        central_layout.addWidget(left_container)
        central_layout.addWidget(right_container)
        central_layout.setStretch(0, 28)
        central_layout.setStretch(1, 72)

        main_layout.addWidget(sidebar_widget)
        main_layout.addWidget(sidebar_divider)
        main_layout.addWidget(central_container)

    def _build_menu(self):
        menubar = self.menuBar() or QMenuBar(self)
        help_menu = menubar.addMenu("Help")
        about_action = QAction("About", self)
        about_action.triggered.connect(self.show_about_dialog)
        help_menu.addAction(about_action)

    def _load_icon(self):
        icons_dir = Path(__file__).resolve().parent.parent / "assets" / "icons"
        icon_path = icons_dir / "AXC.ico"
        if icon_path.exists():
            self.setWindowIcon(QIcon(str(icon_path)))
        self._icon_path = icon_path if icon_path.exists() else None

    def _set_ui_enabled(self, enabled: bool):
        for btn in [
            self.generate_btn,
            self.tweak_btn,
            self.regen_btn,
            self.accept_btn,
        ]:
            btn.setEnabled(enabled)
        self.prompt_input.setEnabled(enabled)
        self.history_list.setEnabled(enabled)

    def _run_async(self, command, status: str):
        self.statusBar().showMessage(status)
        self._set_ui_enabled(False)
        self.progress_overlay.set_progress(0)
        self.progress_overlay.show_overlay()
        self.preview.corner_spinner.start()
        self.preview_progress.setValue(0)
        self.preview_progress.show()
        worker = BlenderWorker(command)
        worker.progress.connect(self.on_progress)
        worker.finished.connect(self.on_worker_finished)
        worker.error.connect(self.on_error)
        worker.finished.connect(lambda _: worker.deleteLater())
        worker.error.connect(lambda _: worker.deleteLater())
        self._current_worker = worker
        worker.start()

    def on_generate(self, prompt: str):
        cmd = blender_runner.build_blender_command(prompt)
        self._run_async(cmd, "Generating...")

    def on_tweak(self, text: str):
        cmd = blender_runner.build_blender_command(text)
        self._run_async(cmd, "Tweaking...")

    def on_regenerate(self):
        cmd = blender_runner.build_blender_command("regenerate")
        self._run_async(cmd, "Regenerating...")

    def on_cancel(self):
        if not (hasattr(self, "_current_worker") and self._current_worker):
            return
        reply = QMessageBox.question(
            self,
            "Cancel Generation",
            "Do you really want to cancel the generation?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
            QMessageBox.StandardButton.No,
        )
        if reply == QMessageBox.StandardButton.Yes:
            self._current_worker.cancel()
            self.preview.corner_spinner.stop()
            self.preview_progress.hide()
            self.progress_overlay.hide_overlay()
            self._set_ui_enabled(True)

    def on_accept(self):
        if not PREVIEW_PATH.exists():
            QMessageBox.information(self, "No Preview", "No preview to accept.")
            return
        dest_dir = FINAL_ASSETS_PATH
        dest_dir.mkdir(parents=True, exist_ok=True)
        dest = dest_dir / PREVIEW_PATH.name
        shutil.copy2(PREVIEW_PATH, dest)
        self.statusBar().showMessage(f"Accepted asset saved to {dest}", 3000)

    def update_preview(self):
        pix = blender_runner.get_preview_image()
        if pix:
            self.preview.set_pixmap(pix)
            self.preview.setAlignment(Qt.AlignmentFlag.AlignCenter)
        gif_path = getattr(blender_runner, "get_turntable_gif_path", lambda: None)()
        if gif_path:
            movie = QMovie(str(gif_path))
            self.preview.set_turntable_movie(movie)
        consistency = getattr(blender_runner, "get_consistency_info", lambda: None)()
        if consistency:
            style = consistency.get("style", "Unknown")
            hints = consistency.get("hints", [])
            self.style_label.setText(f"Style: {style}")
            self.history_list.clear()
            for h in hints:
                self.history_list.addItem(str(h))

    def on_worker_finished(self, success: bool):
        self.progress_overlay.hide_overlay()
        self.preview.corner_spinner.stop()
        self.preview_progress.hide()
        if success:
            self.update_preview()
        else:
            QMessageBox.warning(self, "Blender Error", blender_runner.get_log_output())
        self._set_ui_enabled(True)
        self.statusBar().clearMessage()
        self._current_worker = None

    def on_error(self, message: str):
        QMessageBox.critical(self, "Error", message or blender_runner.get_log_output())
        self._set_ui_enabled(True)
        self.progress_overlay.hide_overlay()
        self.preview.corner_spinner.stop()
        self.preview_progress.hide()
        self.statusBar().clearMessage()

    def on_progress(self, percent: int):
        self.update_progress(percent)

    def update_progress(self, percent: int):
        self.progress_overlay.set_progress(percent)
        self.preview_progress.setValue(percent)
        if percent >= 100:
            self.preview_progress.hide()
            self.preview.corner_spinner.stop()
        else:
            self.preview_progress.show()
            self.preview.corner_spinner.start()

    def show_about_dialog(self):
        dlg = AboutDialog(self, self._icon_path)
        dlg.exec()

    def _build_help_button(self):
        btn = QToolButton(self)
        btn.setText("?")
        btn.setToolTip("Show quick help")
        btn.setFixedSize(28, 28)
        btn.setStyleSheet(
            """
QToolButton {
    background-color: #1e2b36;
    color: #8acaff;
    border: 1px solid #2a3a4f;
    border-radius: 6px;
    padding: 4px;
}
QToolButton:hover {
    background-color: #273748;
}
"""
        )
        btn.clicked.connect(self._toggle_help_overlay)
        return btn

    def _toggle_help_overlay(self):
        rect = self.rect()
        if self.help_overlay.isVisible():
            self.help_overlay.hide()
        else:
            self.help_overlay.show_overlay(rect)

    def _make_action_button(self, name: str, tooltip: str) -> QToolButton:
        btn = QToolButton(self)
        btn.setToolTip(tooltip)
        btn.setCursor(QCursor(Qt.CursorShape.PointingHandCursor))
        if self.icons_dir:
            icon_path = self.icons_dir / f"{name}.svg"
            if icon_path.exists():
                btn.setIcon(QIcon(str(icon_path)))
        return btn

    def _make_toolbar_button(self, name: str, tooltip: str) -> QToolButton:
        btn = QToolButton(self)
        btn.setToolTip(tooltip)
        btn.setCursor(QCursor(Qt.CursorShape.PointingHandCursor))
        btn.setObjectName("toolbar")
        if self.icons_dir:
            icon_path = self.icons_dir / f"{name}.svg"
            if icon_path.exists():
                btn.setIcon(QIcon(str(icon_path)))
        btn.setIconSize(QSize(20, 20))
        return btn

    def _current_prompt(self) -> str:
        return self.prompt_input.toPlainText().strip()

    def _apply_style(self):
        style_path = Path(__file__).resolve().parent / "aaa_theme.qss"
        tooltip_style = """
QToolTip {
    background-color: #000000;
    color: #9fc4ff;
    border: 1px solid #4e6a8d;
    padding: 6px;
    font-size: 11px;
}
"""
        style_text = ""
        if style_path.exists():
            file = QFile(str(style_path))
            if file.open(QFile.OpenModeFlag.ReadOnly | QFile.OpenModeFlag.Text):
                stream = QTextStream(file)
                style_text = stream.readAll()
                file.close()
        style_text = f"{style_text}\n{tooltip_style}"
        self.setStyleSheet(style_text)

    def resizeEvent(self, event):
        super().resizeEvent(event)
        if getattr(self, "help_overlay", None) and self.help_overlay.isVisible():
            self.help_overlay.setGeometry(self.rect())


__all__ = ["MainWindow"]
