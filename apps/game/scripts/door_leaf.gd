class_name DoorLeaf
extends Node2D
## What every door leaf drawn as a mesh in its own plane shares: its painted art ([member texture], one
## whole piece of the approved art set, sampled with mipmaps like the rooms' other door art) and how far
## open it is ([member open], 0 shut to 1 open; setting it redraws the leaf). Users: SealLeaf (the
## corridor's rolling curtain) and BlastLeaf (its inner blast leaf), which both run on the seal's one
## open value, and SlideLeaf (the Service Junction exit), which its room places instead.

## 0 shut, 1 open (each leaf says what open means for it).
var open: float = 0.0:
	set(value):
		open = clampf(value, 0.0, 1.0)
		queue_redraw()
## The leaf's art.
var texture: Texture2D


## A leaf named [param leaf_name] drawn with [param art].
func _init(leaf_name: String, art: Texture2D) -> void:
	name = leaf_name
	texture = art
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
