extends Resource

@export var sols: Array[Rect2] = []
@export var contour: PackedVector2Array = []
@export var navigation := true
@export_range(0.2, 1.0, 0.05) var marge_navigation := 0.65
@export var annexes: Array[PackedScene] = []
@export var positions_annexes: Array[Vector3] = []
@export var orientations_annexes: Array[float] = []
@export var lumieres: Array[Vector3] = []
