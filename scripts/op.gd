extends Resource
class_name Op
## A self-contained operation at a site. Data-driven metadata the hub, scene-flow
## and mission manager read; the op's bespoke gameplay lives in its scene_path
## scene (we author sites by hand — DESIGN_OUTLINE.md §9). Adding an op means
## registering one of these in OpCatalog and authoring its scene.

@export var id: StringName
@export var title: String
@export var scene_path: String
## Ordered objective ids the scene completes via MissionManager. Cleared and
## re-armed on each deploy, so ops are replayable.
@export var objectives: Array[StringName] = []
@export_multiline var briefing: Array[String] = []
@export_multiline var debrief: Array[String] = []
## Salvage scrip awarded once, the first time the op is completed.
@export var reward_credits: int = 30
