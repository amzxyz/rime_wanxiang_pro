#!/usr/bin/env python3
import sys
import os

# 类型索引定义
type_index_map = {
    "zrm": 0,
    "moqi": 1,
    "flypy": 2,
    "hanxin": 3,
    "jdh": 4,
}

# 特殊类型额外添加内容
preset_lines = [
    "大\t小",
]

# 读取参数
if len(sys.argv) != 2:
    print("用法: python lookup分包.py <类型>")
    sys.exit(1)

fuzhu_type = sys.argv[1]
if fuzhu_type not in type_index_map and fuzhu_type not in ("wubi", "tiger"):
    print(f"未知类型: {fuzhu_type}")
    sys.exit(1)

# --- 保证始终从仓库根目录读写 ---
# 假设脚本位于 custom/lookup分包.py
base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
input_path = os.path.join(base_dir, "wanxiang_lookup.dict.yaml")
output_path = os.path.join(base_dir, f"wanxiang_lookup_{fuzhu_type}.dict.yaml")

# --- 安全读取原始文件 ---
if not os.path.exists(input_path):
    print(f"❌ 文件未找到: {input_path}")
    sys.exit(1)

with open(input_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

output_lines = []

# --- 类型处理逻辑 ---
if fuzhu_type in ("wubi", "tiger"):
    for line in lines:
        line = line.strip()
        if not line:
            continue
        key = line.split("\t", 1)[0] if "\t" in line else line
        output_lines.append(f"{key}\t")
    output_lines.extend(preset_lines)
else:
    idx = type_index_map[fuzhu_type]
    for line in lines:
        line = line.strip()
        if not line or "\t" not in line:
            continue
        key, raw = line.split("\t", 1)
        parts = raw.split("◉")
        val = parts[idx].strip() if idx < len(parts) else ""
        output_lines.append(f"{key}\t{val}")

# --- 写入文件 ---
with open(output_path, "w", encoding="utf-8") as f:
    f.write("\n".join(output_lines) + "\n")

print(f"✅ 已生成: {output_path}")
