import os

def process_rime_dicts(input_dir, output_dir, start_index=1, end_index=None):
    """
    处理 Rime 词典文件，针对输入目录中所有文件名包含 ".pro.dict.yaml" 的文件进行处理。
    处理规则：
    - 保留拼音组的第 0 段（segments[0]）
    - 追加 [start_index, end_index) 的段，若不足自动补空
    """
    os.makedirs(output_dir, exist_ok=True)

    for filename in os.listdir(input_dir):
        # 只处理文件名中包含 .pro.dict.yaml 的文件
        if '.pro.dict.yaml' not in filename:
            continue

        # 只处理.yaml或.txt文件，防止误处理
        if not (filename.endswith('.yaml') or filename.endswith('.txt')):
            continue

        input_file = os.path.join(input_dir, filename)
        output_file = os.path.join(output_dir, filename)

        try:
            with open(input_file, 'r', encoding='utf-8') as infile:
                lines = infile.readlines()
        except Exception as e:
            print(f"读取文件 {input_file} 时出错: {e}")
            continue

        processed_data = []
        processing = False  # 是否进入正文区

        for raw_line in lines:
            line = raw_line.rstrip('\n')

            # 未进入正文区时，检测是否出现中文
            if not processing and any('\u4e00' <= ch <= '\u9fff' for ch in line):
                processing = True

            # 未进入正文区则直接保留
            if not processing:
                processed_data.append(line)
                continue

            # 进入正文区后，尝试分列处理
            parts = line.split('\t')
            if len(parts) < 2:
                # 行格式异常，保留原样
                processed_data.append(line)
                continue

            # 统一成三列格式
            if len(parts) == 2:
                parts.append("")
            elif len(parts) > 3:
                parts = [parts[0], parts[1], "\t".join(parts[2:])]

            chinese_part = parts[0]
            rime_data = parts[1]
            other_col = parts[2]

            # 多拼音组空格分隔
            rime_groups = rime_data.split(' ')

            new_rime_groups = []
            for group in rime_groups:
                segments = group.split(';')

                needed_end = end_index if end_index is not None else len(segments)
                max_needed = max(needed_end, start_index + 1)

                if len(segments) < max_needed:
                    segments += [''] * (max_needed - len(segments))

                if end_index is None:
                    to_append = segments[start_index:]
                else:
                    to_append = segments[start_index:end_index]

                if to_append:
                    new_group = segments[0] + ";" + ";".join(to_append)
                else:
                    new_group = segments[0]

                new_rime_groups.append(new_group)

            new_rime_data = ' '.join(new_rime_groups)
            result_line = '\t'.join([chinese_part, new_rime_data, other_col])
            processed_data.append(result_line)

        try:
            with open(output_file, 'w', encoding='utf-8') as outfile:
                for item in processed_data:
                    outfile.write(item + '\n')
            print(f'已处理并保存: {output_file}')
        except Exception as e:
            print(f"写入文件 {output_file} 时出错: {e}")



if __name__ == "__main__":

    # 示例 index_mapping
    index_mapping = [
        (1, 2, "pro-moqi-fuzhu-dicts"),
        (2, 3, "pro-flypy-fuzhu-dicts"),
        (3, 4, "pro-zrm-fuzhu-dicts"),
        (4, 5, "pro-jdh-fuzhu-dicts"),
        (5, 6, "pro-tiger-fuzhu-dicts"),
        (6, 7, "pro-wubi-fuzhu-dicts"),
        (7, None, "pro-hanxin-fuzhu-dicts")  # 7 到末尾
    ]

    input_dir = 'dicts'  # 源目录，包含 .pro.dict.yaml 文件
    base_output_dir = '.'    # 你可以换成你想要的根输出目录

    for start_idx, end_idx, sub_dir in index_mapping:
        out_dir = os.path.join(base_output_dir, sub_dir)
        process_rime_dicts(
            input_dir=input_dir,
            output_dir=out_dir,
            start_index=start_idx,
            end_index=end_idx
        )

    print("全部处理完成！")
