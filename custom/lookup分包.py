#!/usr/bin/env python3
import sys

type_index_map = {
    "zrm": 0,
    "moqi": 1,
    "flypy": 2,
    "hanxin": 3,
    "jdh": 4,
}

preset_lines = [
    "太原\t晋A",
    "大同\t晋B",
    "阳泉\t晋C",
]

if len(sys.argv) != 2:
    print("用法: python 提取lookup子集.py <类型>")
    sys.exit(1)

fuzhu_type = sys.argv[1]
input_path = "wanxiang_lookup.dict.yaml"

head_lines = []
body_lines = []
collecting_head = True

# 读取并拆分文件内容
with open(input_path, "r", encoding="utf-8") as f:
    for line in f:
        line = line.rstrip()
        if collecting_head:
            head_lines.append(line)
            if line.strip() == "...":
                collecting_head = False
        else:
            body_lines.append(line)

output_lines = []

if fuzhu_type in ("wubi", "tiger"):
    # 仅保留单列数据
    for line in body_lines:
        if not line or "\t" in line:
            continue
        output_lines.append(line)
    output_lines.extend(preset_lines)
else:
    idx = type_index_map.get(fuzhu_type)
    if idx is None:
        print(f"未知类型: {fuzhu_type}")
        sys.exit(1)

    for line in body_lines:
        if not line:
            continue
        if "\t" in line:
            key, raw = line.split("\t", 1)
            parts = raw.split("◉")
            part = parts[idx] if idx < len(parts) else ""
            output_lines.append(f"{key}\t{part}")
        else:
            output_lines.append(line)

# 写入回原文件（保留头部 + 新正文）
with open(input_path, "w", encoding="utf-8") as f:
    f.write("\n".join(head_lines) + "\n\n")
    f.write("\n".join(output_lines) + "\n")
