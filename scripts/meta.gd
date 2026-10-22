extends Node
## v5：局外成长（跨局存档）
## 回声碎片：通关/死亡结算获得；用于永久解锁角色
## 存档位置：user://save.json（真实游戏中自动读写）

const SAVE_PATH := "user://save.json"
const UNLOCK_COSTS := {
	"ranger": 0, "cleric": 0, "channeler": 0,
	"mage": 30,
	"guardian": 60, "assassin": 70, "alchemist": 90,
}

var shards := 0
var unlocked: Array = GameData.INITIAL_CHARACTERS.duplicate()


func _ready() -> void:
	load_data()


func add_shards(n: int, persist := true) -> void:
	shards += n
	if persist:
		save_data()


func is_unlocked(key: String) -> bool:
	return key in unlocked


func unlock_cost(key: String) -> int:
	return UNLOCK_COSTS.get(key, -1)


## 尝试解锁角色：碎片足够则扣费并解锁；已解锁直接返回 true
func try_unlock(key: String, persist := true) -> bool:
	if is_unlocked(key):
		return true
	var cost := unlock_cost(key)
	if cost < 0 or shards < cost:
		return false
	shards -= cost
	unlocked.append(key)
	if persist:
		save_data()
	return true


func save_data() -> void:
	var data := {"shards": shards, "unlocked": unlocked}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var data: Variant = JSON.parse_string(text)
	if data is Dictionary:
		shards = data.get("shards", 0)
		unlocked = data.get("unlocked", GameData.INITIAL_CHARACTERS.duplicate())
	for key in GameData.INITIAL_CHARACTERS:
		if not unlocked.has(key):
			unlocked.append(key)
