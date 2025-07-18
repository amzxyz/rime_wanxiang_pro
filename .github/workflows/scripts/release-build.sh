#!/bin/bash
# 打包对用方案到 zip 文件，放到 dist 目录
set -e

ROOT_DIR="$(cd "$(dirname "$0")/../../../" && pwd)"
DIST_DIR="$ROOT_DIR/dist"
CUSTOM_DIR="$ROOT_DIR/custom"

# 成成 PRO 分包文件
echo "▶️ PRO 分包开始"
python3 "$ROOT_DIR/.github/workflows/scripts/万象分包.py"
echo "✅ PRO 分包完毕"
echo
remove_schema() {
    SCHEMA=$1
    OUT_DIR=$2

    sed -i -E "/^\s+-\s+schema:\s+${SCHEMA}\s*$/d" "$OUT_DIR/default.yaml"
}

package_schema_base() {
    OUT_DIR=$1
    rm -rf "$OUT_DIR"
    mkdir -p "$OUT_DIR"

    # 1. 拷贝 custom/ 下除 wanxiang_pro.custom* 外的所有 yaml、md、jpg、ng 文件
    mkdir -p "$OUT_DIR"/custom
    find "$CUSTOM_DIR" -type f \( -name "*.yaml" -o -name "*.md" -o -name "*.jpg" -o -name "*.png" \) \
        ! \( -name "wanxiang_pro.custom*" -o -name "预设分包方案.yaml" \) -exec cp {} "$OUT_DIR"/custom \;

    # 2. 拷贝根目录下除指定内容外的文件/文件夹
    for item in "$ROOT_DIR"/*; do
        name="$(basename "$item")"
        if [[ "$name" =~ ^\. ]]; then continue; fi
        if [[ "$name" == "release-please-config.json" ]]; then continue; fi
        if [[ "$name" == "pro-"*-fuzhu-dicts ]]; then continue; fi
        if [[ "$name" == "lookup" ]]; then continue; fi 
        if [[ "$name" == "wanxiang_pro.dict.yaml" || "$name" == "wanxiang_pro.schema.yaml" ]]; then continue; fi
        if [[ "$name" == "wanxiang_lookup.dict.yaml" || "$name" == "wanxiang_lookup.schema.yaml" ]]; then continue; fi
        if [[ "$name" == "wanxiang_charset.dict.yaml" || "$name" == "wanxiang_charset.schema.yaml" ]]; then continue; fi
        if [[ "$name" == "custom_phrase_flypy.txt" ]]; then continue; fi
        if [[ "$name" == "zh_dicts_pro" ]]; then continue; fi
        if [[ "$name" == "custom" || "$name" == "dist" ]]; then continue; fi
        if [[ "$name" == "LICENSE" ]]; then continue; fi
        cp -r "$item" "$OUT_DIR/"
    done

    # 3. 修改 default.yaml，删除 schema_list: 中的 - schema: wanxiang_pro
    remove_schema wanxiang_pro "$OUT_DIR"
}

package_schema_pro() {
    SCHEMA_NAME="$1"
    OUT_DIR="$2"
    rm -rf "$OUT_DIR"
    mkdir -p "$OUT_DIR"

    # 1. 将 pro-方案名-fuzhu-dicts 移动为 zh_dicts_pro
    if [[ -d "$ROOT_DIR/pro-$SCHEMA_NAME-fuzhu-dicts" ]]; then
        mv "$ROOT_DIR/pro-$SCHEMA_NAME-fuzhu-dicts" "$OUT_DIR/zh_dicts_pro"
    fi

    # 2. 从 lookup 文件夹中复制对应文件并重命名
    LOOKUP_SRC="$ROOT_DIR/lookup/wanxiang_lookup_${SCHEMA_NAME}.dict.yaml"
    LOOKUP_DST="$OUT_DIR/wanxiang_lookup.dict.yaml"

    if [[ -f "$LOOKUP_SRC" ]]; then
        cp "$LOOKUP_SRC" "$LOOKUP_DST"
        sed -i "s/^name:\s*wanxiang_lookup_${SCHEMA_NAME}$/name: wanxiang_lookup/" "$LOOKUP_DST"
        sed -i 's/[ⒶⒷⒸⒹⒺⒻⒼ]//g' "$LOOKUP_DST"
    fi

    # 3. 复制 schema 主文件
    if [[ -f "$CUSTOM_DIR/预设分包方案.yaml" ]]; then
        cp "$CUSTOM_DIR/预设分包方案.yaml" "$OUT_DIR/wanxiang_pro.schema.yaml"
    fi

    # 4. 拷贝 custom/ 下除 wanxiang.custom.yaml 外的所有 yaml、md、jpg、png 文件
    mkdir -p "$OUT_DIR"/custom
    find "$ROOT_DIR/custom" -type f \( -name "*.yaml" -o -name "*.md" -o -name "*.jpg" -o -name "*.png" \) \
        ! \( -name "wanxiang.custom*" -o -name "预设分包方案.yaml" \) -exec cp {} "$OUT_DIR"/custom \;

    # 5. 拷贝根目录下除指定内容外的文件/文件夹
    for item in "$ROOT_DIR"/*; do
        name="$(basename "$item")"
        if [[ "$name" =~ ^\. ]]; then continue; fi
        if [[ "$name" == "release-please-config.json" ]]; then continue; fi
        if [[ "$name" == "pro-"*-fuzhu-dicts ]]; then continue; fi
        if [[ "$name" == "lookup" ]]; then continue; fi
        if [[ "$name" == "wanxiang.dict.yaml" || "$name" == "wanxiang.schema.yaml" ]]; then continue; fi
        if [[ "$name" == "zh_dicts" ]]; then continue; fi
        if [[ -e "$OUT_DIR/$name" ]]; then continue; fi
        if [[ "$name" == "custom" || "$name" == "dist" ]]; then continue; fi
        if [[ "$name" == "LICENSE" ]]; then continue; fi
        cp -r "$item" "$OUT_DIR/"
    done

    # 6. 修改 default.yaml，删除 schema_list 中的 - schema: wanxiang
    remove_schema wanxiang "$OUT_DIR"
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
    (cd "$OUT_DIR" && zip -r -9 -q ../"$ZIP_NAME" . && cd ..)
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
