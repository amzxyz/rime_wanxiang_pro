#!/usr/bin/env python3
import sys
import os

# 类型索引定义：对应 raw.split("◉") 的下标
type_index_map = {
    "zrm": 0,
    "moqi": 1,
    "flypy": 2,
    "hanxin": 3,
    "jdh": 4,
    "tiger": 5,
    "wubi": 6,
}

# 读取参数
if len(sys.argv) != 2:
    print("用法: python lookup分包.py <类型>")
    sys.exit(1)

fuzhu_type = sys.argv[1]
if fuzhu_type not in type_index_map:
    print(f"❌ 未知类型: {fuzhu_type}")
    sys.exit(1)

# --- 保证始终从仓库根目录读写 ---
# 假设脚本位于 custom/lookup分包.py
base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../"))
input_path = os.path.join(base_dir, "wanxiang_lookup.dict.yaml")
output_path = os.path.join(base_dir, f"wanxiang_lookup_{fuzhu_type}.dict.yaml")

# --- 安全读取原始文件 ---
if not os.path.exists(input_path):
    print(f"❌ 文件未找到: {input_path}")
    sys.exit(1)

with open(input_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

# --- 拆分注释头与正文内容 ---
header_lines = []
data_lines = []
in_data = False
for line in lines:
    if line.strip() == '...':
        header_lines.append(line.rstrip())
        in_data = True
        continue
    if not in_data:
        header_lines.append(line.rstrip())
    else:
        data_lines.append(line.strip())

output_lines = header_lines + []  # 保留 header
idx = type_index_map[fuzhu_type]

# --- 主分列逻辑 ---
for line in data_lines:
    if not line or "\t" not in line:
        continue
    key, raw = line.split("\t", 1)
    parts = raw.split("◉")
    val = parts[idx].strip() if idx < len(parts) else ""
    output_lines.append(f"{key}\t{val}")

# --- 写入输出文件 ---
with open(output_path, "w", encoding="utf-8") as f:
    f.write("\n".join(output_lines) + "\n")

print(f"✅ 已生成: {output_path}")
