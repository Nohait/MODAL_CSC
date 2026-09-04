import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

"""Base helpers for procedural model generation in Blender."""

import bpy
from mathutils import Vector


class BaseModelGenerator:
    """Shared utilities for procedural mesh generation."""

    def _deselect_all(self) -> None:
        for obj in bpy.context.view_layer.objects:
            obj.select_set(False)

    def _ensure_object_mode(self) -> None:
        obj = bpy.context.view_layer.objects.active
        if obj and obj.mode != "OBJECT":
            bpy.ops.object.mode_set(mode="OBJECT")

    def generate(self):
        """Entry point for building the asset. Override in subclasses."""
        raise NotImplementedError("Subclasses must implement generate()")

    def place_in_collection(self, obj: bpy.types.Object, collection_name: str) -> None:
        """Ensure the target collection exists, link the object there, and unlink elsewhere."""
        collection = bpy.data.collections.get(collection_name)
        if collection is None:
            collection = bpy.data.collections.new(collection_name)
            bpy.context.scene.collection.children.link(collection)

        if collection not in obj.users_collection:
            collection.objects.link(obj)

        for col in list(obj.users_collection):
            if col != collection:
                col.objects.unlink(obj)

    def center_on_origin(self, obj: bpy.types.Object) -> None:
        """Set origin to bottom center for proper ground placement in Godot.
        
        This ensures that when an object is placed at position (0, 0, 0) in Godot,
        its base/feet will be touching the ground plane.
        """
        self._ensure_object_mode()
        self._deselect_all()
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        
        # Apply transforms to get accurate bounds
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        
        # Find the lowest Z point in the mesh
        mesh = obj.data
        min_z = min((obj.matrix_world @ v.co).z for v in mesh.vertices)
        
        # Set cursor to bottom center
        bpy.context.scene.cursor.location = (0.0, 0.0, min_z)
        
        # Set origin to cursor
        bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
        
        # Move object to world origin
        obj.location = (0.0, 0.0, 0.0)
        
        # Reset cursor
        bpy.context.scene.cursor.location = (0.0, 0.0, 0.0)
        
        obj.select_set(False)

    def apply_flat_shading(self, obj: bpy.types.Object) -> None:
        """Apply flat shading to the object."""
        self._ensure_object_mode()
        self._deselect_all()
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.shade_flat()

    def cleanup_old_versions(self, name_prefix: str) -> None:
        """Remove lingering objects that match the given name prefix."""
        targets = [obj for obj in bpy.data.objects if obj.name.startswith(name_prefix)]
        if not targets:
            return

        self._ensure_object_mode()
        self._deselect_all()
        for obj in targets:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = targets[0]
        bpy.ops.object.delete()
