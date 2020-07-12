extends Node2D

export var center : Vector2
export var radius : int
export var angle_from : int
export var angle_to : int
export var color : Color

var _progress := 0

func UpdateFuse(progress):
	_progress = progress
	update()

func _draw():
	draw_circle_arc_poly(center, radius, angle_from, angle_to, color)
	draw_circle_arc_poly(center, radius, angle_from, _progress, color)

func draw_circle_arc_poly(center, radius, angle_from, angle_to, color):
	var nb_points = 32
	var points_arc = PoolVector2Array()
	points_arc.push_back(center)
	var colors = PoolColorArray([color])

	for i in range(nb_points + 1):
		var angle_point = deg2rad(angle_from + i * (angle_to - angle_from) / nb_points - 90)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	draw_polygon(points_arc, colors)
