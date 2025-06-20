#!/usr/bin/env python3
import sys
import os

type_index_map = {
    "zrm": 0,
    "moqi": 1,
    "flypy": 2,
    "hanxin": 3,
    "jdh": 4,
}

preset_lines = [
    "大\t小",
]

if len(sys.argv) != 2:
    print("用法: python lookup分包.py <类型>")
    sys.exit(1)

fuzhu_type = sys.argv[1]
input_path = "wanxiang_lookup.dict.yaml"
output_path = f"wanxiang_lookup_{fuzhu_type}.dict.yaml"
output_lines = []

if not os.path.exists(input_path):
    print(f"未找到文件: {input_path}")
    sys.exit(1)

with open(input_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

if fuzhu_type in ("wubi", "tiger"):
    for line in lines:
        line = line.strip()
        if not line:
            continue
        if "\t" in line:
            key = line.split("\t", 1)[0]
            output_lines.append(f"{key}\t")
        else:
            output_lines.append(f"{line}\t")
    output_lines.extend(preset_lines)
else:
    idx = type_index_map.get(fuzhu_type)
    if idx is None:
        print(f"未知类型: {fuzhu_type}")
        sys.exit(1)

    for line in lines:
        line = line.strip()
        if not line:
            continue

        if "\t" in line:
            key, value = line.split("\t", 1)
            parts = value.split("◉")
            selected = parts[idx].strip() if idx < len(parts) else ""
            output_lines.append(f"{key}\t{selected}")
        else:
            # 若整行无 tab，视为 key-only（极少数情况）
            output_lines.append(f"{line}\t")

with open(output_path, "w", encoding="utf-8") as f:
    f.write("\n".join(output_lines) + "\n")

print(f"✓ 类型 {fuzhu_type} 已写入: {output_path}")
