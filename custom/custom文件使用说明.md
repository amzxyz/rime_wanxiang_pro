# Rime YAML Custom Patch 文件使用说明



1. 修改 `wanxiang.custom.yaml` 文件里的输入方案名称和辅助码名称，并修改中英混输词典为所选输入方案对应词典名称，wanxiang_pro.custom.yaml也同理
2. 修改 `wanxiang_en.custom.yaml` 和 `wanxiang_radical.custom.yaml` 文件里的输入方案名称，要与 `wanxiang.custom.yaml` 里的一致
3. 其他每一行都需要仔细看，因为这是个例子不是个最终产物，每一行都会干扰主方案，如果你不改就会一堆问题，所以不是方案改过来就万事大吉了！
4. 将custom文件夹下面这三个custom.yaml复制到上一级目录，也就是用户目录根目录，这个时候重新部署才能生效
