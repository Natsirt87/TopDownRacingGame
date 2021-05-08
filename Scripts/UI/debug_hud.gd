extends Node2D


onready var lap_num_label = get_node("Canvas/LapNum") # label for displaying lap number
onready var lap_time_label = get_node("Canvas/LapTime") # label for displaying lap time
onready var best_lap_label = get_node("Canvas/BestLap") # label for displaying lap time
onready var speed_label = get_node("Canvas/Speed") # label for displaying speed
onready var gear_label = get_node("Canvas/Gear") # label for displaying current gear
onready var rpm_label = get_node("Canvas/RPM") # label for displaying RPM
onready var warning_label = get_node("Canvas/Warning") # label for displaying various warnings
