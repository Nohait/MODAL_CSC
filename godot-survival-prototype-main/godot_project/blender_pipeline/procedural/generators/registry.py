import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

"""Dynamic registry for procedural asset generators."""

import importlib
import inspect
import pkgutil
from pathlib import Path
from typing import Dict, List, Type

from blender_pipeline.procedural.templates.model_base import BaseModelGenerator

TEMPLATE_PACKAGE = "blender_pipeline.procedural.templates"
TEMPLATE_DIR = Path(__file__).resolve().parent.parent / "templates"

Registry = Dict[str, Type[BaseModelGenerator]]
_registry: Registry = {}


def _discover_template_modules() -> List[str]:
    """List all template module names (without package prefix)."""
    names: List[str] = []
    for _, module_name, is_pkg in pkgutil.iter_modules([str(TEMPLATE_DIR)]):
        if is_pkg:
            continue
        if module_name.startswith("_"):
            continue
        if module_name in {"model_base", "material_base", "__init__"}:
            continue
        names.append(module_name)
    return names


def _register_module(module_name: str) -> None:
    """Import a module and register generator classes found inside."""
    full_name = f"{TEMPLATE_PACKAGE}.{module_name}"
    module = importlib.import_module(full_name)

    for _, cls in inspect.getmembers(module, inspect.isclass):
        if cls.__module__ != module.__name__:
            continue
        if not issubclass(cls, BaseModelGenerator):
            continue
        if cls is BaseModelGenerator:
            continue

        asset_type = getattr(cls, "asset_type", module_name)
        _registry[asset_type] = cls


def _build_registry() -> None:
    for module_name in _discover_template_modules():
        _register_module(module_name)


def get_generator(asset_type: str) -> BaseModelGenerator:
    """Return an instance of the registered generator for the given asset type."""
    if not _registry:
        _build_registry()
    cls = _registry.get(asset_type)
    if cls is None:
        raise KeyError(f"No generator registered for asset type '{asset_type}'")
    return cls()


def list_generators() -> List[str]:
    """List available asset types known to the registry."""
    if not _registry:
        _build_registry()
    return sorted(_registry.keys())
