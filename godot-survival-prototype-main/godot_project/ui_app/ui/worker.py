import os
import subprocess
import re

from PyQt6.QtCore import QThread, pyqtSignal

from ui_app.backend import blender_runner


class BlenderWorker(QThread):
    finished = pyqtSignal(bool)
    error = pyqtSignal(str)
    progress = pyqtSignal(int)

    def __init__(self, command: list[str]):
        super().__init__()
        self.command = command
        self.proc: subprocess.Popen | None = None
        self._cancel_requested = False

    def run(self):
        log_lines = []
        err_lines = []
        try:
            self.proc = subprocess.Popen(
                self.command,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0,
            )
        except FileNotFoundError as exc:
            msg = f"Executable not found: {self.command[0]}"
            blender_runner.record_log("", msg)
            self.error.emit(msg)
            return
        except Exception as exc:
            msg = f"Failed to launch Blender: {exc}"
            blender_runner.record_log("", msg)
            self.error.emit(msg)
            return

        progress_pattern = re.compile(r"Rendering\s+(\d+)\s*/\s*(\d+)")
        simple_progress = blender_runner.parse_progress

        try:
            while True:
                line_out = self.proc.stdout.readline() if self.proc.stdout else ""
                line_err = self.proc.stderr.readline() if self.proc.stderr else ""

                if line_out:
                    log_lines.append(line_out)
                    if line_out.startswith("CONSISTENCY_ANALYSIS:"):
                        payload = line_out.split("CONSISTENCY_ANALYSIS:", 1)[1].strip()
                        blender_runner.record_consistency(payload)
                    if line_out.startswith("TURN_TABLE_FRAMES:"):
                        payload = line_out.split("TURN_TABLE_FRAMES:", 1)[1].strip()
                        try:
                            import json

                            frames = json.loads(payload)
                            if isinstance(frames, list):
                                blender_runner.record_turntable_frames(frames)
                        except Exception:
                            pass
                    match = progress_pattern.search(line_out)
                    if match:
                        current = int(match.group(1))
                        total = int(match.group(2))
                        if total > 0:
                            percent = int((current / total) * 100)
                            self.progress.emit(percent)
                    else:
                        p = simple_progress(line_out)
                        if p is not None:
                            self.progress.emit(p)
                if line_err:
                    err_lines.append(line_err)

                if self._cancel_requested:
                    if self.proc and self.proc.poll() is None:
                        self.proc.kill()
                    blender_runner.record_log("".join(log_lines + err_lines), "Canceled")
                    self.finished.emit(False)
                    return

                if line_out == "" and line_err == "" and self.proc.poll() is not None:
                    break

            self.proc.wait()
            log_text = "".join(log_lines + err_lines)
            err_text = "".join(err_lines).strip()
            blender_runner.record_log(log_text, err_text)
            success = self.proc.returncode == 0
            if success and blender_runner.get_turntable_frames():
                out_gif = blender_runner.PREVIEW_PATH.parent / "turntables" / "preview.gif"
                blender_runner.build_turntable_gif(out_gif)
            self.finished.emit(success)
        except Exception as exc:
            blender_runner.record_log("".join(log_lines + err_lines), str(exc))
            self.error.emit(str(exc))

    def cancel(self):
        self._cancel_requested = True
        if self.proc and self.proc.poll() is None:
            try:
                if os.name == "nt":
                    self.proc.kill()
                else:
                    self.proc.terminate()
            except Exception:
                pass
