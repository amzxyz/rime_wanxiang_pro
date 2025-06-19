local wanxiang = require("wanxiang")

-- 获取配置中的分隔符
local function get_delimiters(env)
    local config = env.engine.schema.config
    local delimiter = config:get_string('speller/delimiter') or " '" -- 默认是两个空格
    local auto_delimiter = delimiter:sub(1, 1)
    local manual_delimiter = delimiter:sub(2, 2)
    return auto_delimiter, manual_delimiter
end

local function get_genuine_cand_pro(env, cand)
    local genuine_cand = cand:get_genuine()
    local preedit = genuine_cand.preedit or ""

    -- 获取开关状态
    local is_tone_display = env.settings.tone_display
    local auto_delimiter, manual_delimiter = get_delimiters(env)

    if is_tone_display and #preedit >= 2 then
        -- 处理 preedit
        local input_parts = {}
        local current_segment = ""

        for i = 1, #preedit do
            local char = preedit:sub(i, i)
            if char == auto_delimiter or char == manual_delimiter then
                if #current_segment > 0 then
                    table.insert(input_parts, current_segment)
                    current_segment = ""
                end
                table.insert(input_parts, char)
            else
                current_segment = current_segment .. char
            end
        end

        if #current_segment > 0 then
            table.insert(input_parts, current_segment)
        end

        -- 提取拼音片段
        local comment = genuine_cand.comment
        if comment then
            local pinyin_segments = {}
            for segment in string.gmatch(comment, "[^" .. auto_delimiter .. manual_delimiter .. "]+") do
                local pinyin = string.match(segment, "^[^;]+")
                if pinyin then
                    table.insert(pinyin_segments, pinyin)
                end
            end

            local pinyin_index = 1
            for i, part in ipairs(input_parts) do
                if part ~= auto_delimiter and part ~= manual_delimiter and pinyin_index <= #pinyin_segments then
                    input_parts[i] = pinyin_segments[pinyin_index]
                    pinyin_index = pinyin_index + 1
                end
            end

            local final_preedit = table.concat(input_parts)
            genuine_cand.preedit = final_preedit
        end
    end

    return genuine_cand
end

local function get_genuine_cand(env, cand)
    local genuine_cand = cand:get_genuine()
    local preedit = genuine_cand.preedit or ""
    local comment = genuine_cand.comment

    -- 获取开关状态
    local is_tone_display = env.settings.tone_display
    if not comment or comment == "" or not is_tone_display then
        return cand
    end

    -- 从 YAML 配置读取参数
    local auto_delimiter, manual_delimiter = get_delimiters(env)
    local tone_isolate = env.engine.schema.config:get_bool("speller/tone_isolate")              -- 是否将数字声调从转换后拼音中隔离出来
    local visual_delim = env.engine.schema.config:get_string("speller/visual_delimiter") or " " -- 定义转换后的分隔符号

    -- 拆分 preedit
    local input_parts = {}
    local current_segment = ""
    for i = 1, #preedit do
        local char = preedit:sub(i, i)
        if char == auto_delimiter or char == manual_delimiter then
            if #current_segment > 0 then
                table.insert(input_parts, current_segment)
                current_segment = ""
            end
            table.insert(input_parts, char)
        else
            current_segment = current_segment .. char
        end
    end
    if #current_segment > 0 then
        table.insert(input_parts, current_segment)
    end

    -- 拆分拼音段（comment）
    local pinyin_segments = {}
    for segment in string.gmatch(comment, "[^" .. auto_delimiter .. manual_delimiter .. "]+") do
        local pinyin = segment:match("^[^;]+")
        if pinyin then
            table.insert(pinyin_segments, pinyin)
        end
    end

    -- 替换逻辑
    local pinyin_index = 1
    for i, part in ipairs(input_parts) do
        if part == auto_delimiter or part == manual_delimiter then
            input_parts[i] = visual_delim
        else
            local body, tone = part:match("(%a+)(%d?)")
            local py = pinyin_segments[pinyin_index]

            if py then
                if i == #input_parts and #part == 1 then
                    local prefix = py:sub(1, 2)
                    -- 添加对原始输入首字母的判断,如果首选是“吃”就会转换为ch，但整体来看略显突兀，因此控制csz不转换
                    local first_char = part:sub(1, 1):lower()
                    if first_char == "s" or first_char == "c" or first_char == "z" then
                        input_parts[i] = part -- 保持原始输入不转换
                    else
                        if prefix == "zh" or prefix == "ch" or prefix == "sh" then
                            input_parts[i] = prefix
                        else
                            input_parts[i] = part
                        end
                    end
                else
                    if tone_isolate then
                        input_parts[i] = py .. (tone or "")
                    else
                        input_parts[i] = py
                    end
                    pinyin_index = pinyin_index + 1
                end
            end
        end
    end
    genuine_cand.preedit = table.concat(input_parts)

    return genuine_cand
end

local function modify_preedit_filter(input, env)
    -- 初始化开关状态和分隔符
    env.settings = {
        tone_display = env.engine.context:get_option("tone_display"),
    } or false

    -- 是否处于反查模式
    local is_radical_mode = wanxiang.is_in_radical_mode(env)
    local is_pro_scheme = wanxiang.is_pro_scheme(env)

    for cand in input:iter() do
        -- **如果处于反查模式，直接返回，不执行替换**
        if is_radical_mode then
            yield(cand)
        else
            local genuine_cand = is_pro_scheme
                and get_genuine_cand_pro(env, cand)
                or get_genuine_cand(env, cand)
            yield(genuine_cand)
        end
    end
end

return modify_preedit_filter
