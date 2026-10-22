extends "res://scripts/run_state.gd"
## 兼容入口：旧版项目缓存仍可能引用 res://scripts/run.gd。
## 真正的单局状态实现在 run_state.gd；继承可确保 planned_slots 等新属性存在。
