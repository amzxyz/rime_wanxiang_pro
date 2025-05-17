import os

def process_rime_dicts(input_dir, output_dir, start_index=1, end_index=None):
    """
    示例：处理 Rime 词典文件时，保留每个拼音组的第 0 段（segments[0]），
    并将 [start_index, end_index) 的段追加到后面。若分号不够，自动补空。
    """

    os.makedirs(output_dir, exist_ok=True)  # 确保输出目录存在

    for filename in os.listdir(input_dir):
        if not (filename.endswith('.yaml') or filename.endswith('.txt')):
            continue

        input_file = os.path.join(input_dir, filename)
        output_file = os.path.join(output_dir, filename)

        with open(input_file, 'r', encoding='utf-8') as infile:
            lines = infile.readlines()

        processed_data = []
        processing = False  # 标志是否进入正文区

        for raw_line in lines:
            line = raw_line.rstrip('\n')

            # 如果还没进入正文区，则检查是否出现中文
            if not processing and any('\u4e00' <= ch <= '\u9fff' for ch in line):
                processing = True

            # 如果不在正文区，则保持原样
            if not processing:
                processed_data.append(line)
                continue

            # 进入正文区，先分列
            parts = line.split('\t')
            if len(parts) < 2:
                # 连字+拼音都不够，原样保留
                processed_data.append(line)
                continue

            # 保证三列：  [字/词, 拼音/编码, 频率/注释]
            if len(parts) == 2:
                parts.append("")
            elif len(parts) > 3:
                # 多余合并到第三列
                parts = [parts[0], parts[1], "\t".join(parts[2:])]

            # 现在肯定是三列
            chinese_part = parts[0]
            rime_data = parts[1]
            other_col = parts[2]

            # 按空格分多个拼音组
            rime_groups = rime_data.split(' ')

            new_rime_groups = []
            for group in rime_groups:
                # 按分号拆分
                segments = group.split(';')

                # 如果 end_index 大于实际段数，会导致越界，可先补空
                needed_end = end_index if end_index is not None else len(segments)
                max_needed = max(needed_end, start_index + 1)

                if len(segments) < max_needed:
                    segments += [''] * (max_needed - len(segments))

                # 保留 segments[0]，并把 [start_index, end_index) 拼到后面
                if end_index is None:
                    # 取到结尾
                    to_append = segments[start_index:]
                else:
                    to_append = segments[start_index:end_index]

                # 拼回
                if to_append:
                    # 原来的第 0 段 + 分号 + 截取部分
                    new_group = segments[0] + ";" + ";".join(to_append)
                else:
                    # 如果截取的部分全空，则只有第 0 段
                    new_group = segments[0]

                new_rime_groups.append(new_group)

            # 多组用空格拼回
            new_rime_data = ' '.join(new_rime_groups)
            # 合并三列成一行
            result_line = '\t'.join([chinese_part, new_rime_data, other_col])
            processed_data.append(result_line)

        # 写入文件
        with open(output_file, 'w', encoding='utf-8') as outfile:
            for item in processed_data:
                outfile.write(item + '\n')


if __name__ == "__main__":

    # 你可能有一批 start_index、end_index 对照表，这里仅示意
    index_mapping = [
        (1, 2, "moqi_dicts"),
        (2, 3, "flypy_dicts"),
        (3, 4, "zrm_dicts"),
        (4, 5, "jdh_dicts"),
        (5, 6, "cj_dicts"),
        (6, 7, "tiger_dicts"),
        (7, 8, "wubi_dicts"),
        (8, None, "hanxin_dicts")  # 8 到末尾
    ]

    input_dir = 'cn_dicts'

    for start_idx, end_idx, out_dir in index_mapping:
        process_rime_dicts(
            input_dir=input_dir,
            output_dir=out_dir,
            start_index=start_idx,
            end_index=end_idx
        )

    print("全部处理完成！")
