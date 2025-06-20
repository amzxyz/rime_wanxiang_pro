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

# 预设数据（用于 wubi, tiger 类型）
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
output_lines = []

with open(input_path, "r", encoding="utf-8") as f:
    for line in f:
        line = line.rstrip("\n")
        if not line.strip():
            continue

        # 特殊情况：wubi / tiger，只保留 key + tab，不处理 value
        if fuzhu_type in ("wubi", "tiger"):
            if "\t" in line:
                key, _ = line.split("\t", 1)
                output_lines.append(f"{key}\t")
            else:
                output_lines.append(line)
        else:
            idx = type_index_map.get(fuzhu_type)
            if idx is None:
                print(f"未知类型: {fuzhu_type}")
                sys.exit(1)

            if "\t" in line:
                key, raw = line.split("\t", 1)
                parts = raw.split("◉")
                part = parts[idx] if idx < len(parts) else ""
                output_lines.append(f"{key}\t{part}")
            else:
                # 无 tab 的注释或无效行保留原样（不加 tab）
                output_lines.append(line)

# wubi 和 tiger 附加预设
if fuzhu_type in ("wubi", "tiger"):
    output_lines.extend(preset_lines)

# 写入回原文件
with open(input_path, "w", encoding="utf-8") as f:
    f.write("\n".join(output_lines) + "\n")
