#!/usr/bin/env python3
import sys

# 类型到索引映射（从 0 开始）
type_index_map = {
    "zrm": 0,
    "moqi": 1,
    "flypy": 2,
    "hanxin": 3,
    "jdh": 4
}

if len(sys.argv) != 2:
    print("用法: python 提取lookup子集.py <类型>")
    sys.exit(1)

fuzhu_type = sys.argv[1]
idx = type_index_map.get(fuzhu_type)

if idx is None:
    print(f"未知类型: {fuzhu_type}")
    sys.exit(1)

input_path = "wanxiang_lookup.dict.yaml"
output_lines = []

with open(input_path, "r", encoding="utf-8") as f:
    for line in f:
        stripped = line.strip("\n")
        if "\t" in stripped:
            key, raw = stripped.split("\t", 1)
            parts = raw.split("◉")
            part = parts[idx] if idx < len(parts) else ""
            output_lines.append(f"{key}\t{part}")
        else:
            output_lines.append(stripped)

with open(input_path, "w", encoding="utf-8") as f:
    f.write("\n".join(output_lines) + "\n")
