extends CanvasModulate

## Pretiahni sem svoj DirectionalLight2D ("slnko").
@export var sun_light: DirectionalLight2D

## Dĺžka celého cyklu (deň+noc) v sekundách. Pre testovanie pokojne daj
## nízku hodnotu (napr. 30), pre "reálny" pocit neskôr zvýš (napr. 600+).
@export var day_length_seconds: float = 600.0

## Farba scény v priebehu dňa (0.0 = polnoc, 0.5 = poludnie, 1.0 = polnoc
## znova). Uprav si farebné body priamo v Inspectore kliknutím na gradient.
@export var sky_color_gradient: Gradient

## Intenzita slnka v priebehu dňa (0.0 = tma, 1.0 = plné svetlo). Uprav
## body priamo v Inspectore (Curve editor).
@export var sun_energy_curve: Curve

## Aktuálny čas dňa, 0.0-1.0. Môžeš nastaviť v Inspectore na konkrétny
## začiatočný čas (napr. 0.3 = ráno).
@export_range(0.0, 1.0) var time_of_day: float = 0.3


func _process(delta: float) -> void:
	time_of_day = fmod(time_of_day + delta / day_length_seconds, 1.0)
	_update_lighting()


func _update_lighting() -> void:
	if sky_color_gradient != null:
		color = sky_color_gradient.sample(time_of_day)

	if sun_light != null and sun_energy_curve != null:
		sun_light.energy = sun_energy_curve.sample(time_of_day)
