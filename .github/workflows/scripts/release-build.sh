#!/bin/bash
# 打包对用方案到 zip 文件，放到 dist 目录
set -e

ROOT_DIR="$(cd "$(dirname "$0")/../../../" && pwd)"
DIST_DIR="$ROOT_DIR/dist"
CUSTOM_DIR="$ROOT_DIR/custom"

# 成成 PRO 分包文件
python3 "$CUSTOM_DIR/万象分包.py"
echo "✅ PRO 完成: 生成完毕"
echo

package_schema_base() {
    OUT_DIR=$1
    rm -rf "$OUT_DIR"
    mkdir -p "$OUT_DIR"

    # 1. 拷贝 custom/ 下除 wanxiang_pro.custom* 外的所有 yaml、md、jpg、ng 文件
    mkdir -p "$OUT_DIR"/custom
    find "$CUSTOM_DIR" -type f \( -name "*.yaml" -o -name "*.md" -o -name "*.jpg" -o -name "*.png" \) \
        ! -name "wanxiang_pro.custom*" -exec cp {} "$OUT_DIR"/custom \;

    # 2. 拷贝根目录下除指定内容外的文件/文件夹
    for item in "$ROOT_DIR"/*; do
        name="$(basename "$item")"
        if [[ "$name" =~ ^\. ]]; then continue; fi
        if [[ "$name" == "pro-"*-fuzhu-dicts ]]; then continue; fi
        if [[ "$name" == "wanxiang_pro.dict.yaml" || "$name" == "wanxiang_pro.schema.yaml" ]]; then continue; fi
        if [[ "$name" == "custom_phrase_flypy.txt" ]]; then continue; fi
        if [[ "$name" == "zh_dicts_pro" ]]; then continue; fi
        if [[ "$name" == "custom" || "$name" == "dist" ]]; then continue; fi
        cp -r "$item" "$OUT_DIR/"
    done

    # 3. 修改 default.yaml，删除 schema_list: 中的 - schema: wanxiang_pro
    sed -i '/- schema: wanxiang_pro/d' "$OUT_DIR/default.yaml"
}

package_schema_pro() {
    SCHEMA_NAME="$1"
    OUT_DIR="$2"
    rm -rf "$OUT_DIR"
    mkdir -p "$OUT_DIR"

    # 1. 生成 pro-方案名-fuzhu-dicts 并重命名为 zh_dicts_pro
    if [[ -d "$ROOT_DIR/pro-$SCHEMA_NAME-fuzhu-dicts" ]]; then
        mv "$ROOT_DIR/pro-$SCHEMA_NAME-fuzhu-dicts" "$OUT_DIR/zh_dicts_pro"
    fi

    # 2. 生成 lookup-方案名.yaml 并重命名
    python3 "$CUSTOM_DIR/lookup分包.py" "$SCHEMA_NAME"
    if [[ -f "$ROOT_DIR/wanxiang_lookup_$SCHEMA_NAME.dict.yaml" ]]; then
        mv "$ROOT_DIR/wanxiang_lookup_$SCHEMA_NAME.dict.yaml" "$OUT_DIR/wanxiang_lookup.dict.yaml"
    fi

    # 3. 拷贝 custom/ 下除 wanxiang.custom.yaml 外的所有 yaml、md、jpg、ng 文件
    mkdir -p "$OUT_DIR"/custom
    find "$CUSTOM_DIR" -type f \( -name "*.yaml" -o -name "*.md" -o -name "*.jpg" -o -name "*.png" \) \
        ! -name "wanxiang.custom.yaml" -exec cp {} "$OUT_DIR"/custom \;

    # 4. 拷贝根目录下除指定内容外的文件/文件夹
    for item in "$ROOT_DIR"/*; do
        name="$(basename "$item")"
        if [[ "$name" =~ ^\. ]]; then continue; fi
        if [[ "$name" == "pro-"*-fuzhu-dicts ]]; then continue; fi
        if [[ "$name" == "wanxiang.dict.yaml" || "$name" == "wanxiang.schema.yaml" ]]; then continue; fi
        if [[ "$name" == "zh_dicts" ]]; then continue; fi
        if [[ -e "$OUT_DIR/$name" ]]; then continue; fi
        if [[ "$name" == "custom" || "$name" == "dist" ]]; then continue; fi
        cp -r "$item" "$OUT_DIR/"
    done

    # 5. 修改 default.yaml，删除 schema_list: 中的 - schema: wanxiang
    sed -i '/- schema: wanxiang$/d' "$OUT_DIR/default.yaml"
}

package_schema() {
    SCHEMA_NAME="$1"
    echo "▶️ 开始打包方案：$SCHEMA_NAME"

    if [[ "$SCHEMA_NAME" == "base" ]]; then
        OUT_DIR="$DIST_DIR/rime-wanxiang-base"
        package_schema_base "$OUT_DIR"

        ZIP_NAME=rime-wanxiang-"$SCHEMA_NAME".zip
    else
        OUT_DIR="$DIST_DIR/rime-wanxiang-$SCHEMA_NAME-fuzhu"
        package_schema_pro "$SCHEMA_NAME" "$OUT_DIR"

    fi

    ZIP_NAME=$(basename "$OUT_DIR").zip
    (cd "$OUT_DIR" && zip -r -q ../"$ZIP_NAME" . && cd ..)
    echo "✅ 完成打包: $ZIP_NAME"
    echo
}

SCHEMA_LIST=("base" "flypy" "hanxin" "jdh" "moqi" "tiger" "wubi" "zrm")

# 如果没有传入参数，则循环 package 所有的
if [[ -z "$SCHEMA_NAME" ]]; then
    for name in "${SCHEMA_LIST[@]}"; do
        package_schema "$name"
    done
    exit 0
fi

if [[ ! " ${SCHEMA_LIST[*]} " =~ ${SCHEMA_NAME} ]]; then
    echo "参数错误: 只支持 ${SCHEMA_LIST[*]}" >&2
    exit 1
fi

package_schema "$SCHEMA_NAME"
