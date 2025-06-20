#!/usr/bin/env python3
import sys

# 类型到索引映射（从 0 开始）
type_index_map = {
    "zrm": 0,
    "moqi": 1,
    "flypy": 2,
    "hanxin": 3,
    "jdh": 4,
}

if len(sys.argv) != 2:
    print("用法: python 提取lookup子集.py <类型>")
    sys.exit(1)

fuzhu_type = sys.argv[1]
input_path = "wanxiang_lookup.dict.yaml"

head_lines = []
body_lines = []
collecting_head = True

# 拆分头部和正文
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

# 特殊处理：wubi / tiger → 直接清空正文，只输出一行
if fuzhu_type in ("wubi", "tiger"):
    output_lines = ["你\t哈哈"]
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

# 写入回原文件
with open(input_path, "w", encoding="utf-8") as f:
    f.write("\n".join(head_lines) + "\n\n")
    f.write("\n".join(output_lines) + "\n")
