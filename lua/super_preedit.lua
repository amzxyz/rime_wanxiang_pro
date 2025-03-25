local function modify_preedit_filter(input, env)
    -- 获取配置中的分隔符
    local config = env.engine.schema.config
    local delimiter = config:get_string('speller/delimiter') or " '"  -- 默认是两个空格

    -- 初始化开关状态和分隔符
    env.settings = {tone_display = env.engine.context:get_option("tone_display")} or false
    local auto_delimiter = delimiter:sub(1, 1)
    local manual_delimiter = delimiter:sub(2, 2)

    -- 获取开关状态
    local is_tone_display = env.settings.tone_display
    local context = env.engine.context

    -- **加入 `tag` 方式检测是否处于反查模式**
    local seg = context.composition:back()
    env.is_radical_mode = seg and (
        seg:has_tag("radical_lookup") 
        or seg:has_tag("reverse_stroke") 
        or seg:has_tag("add_user_dict")
    ) or false

    for cand in input:iter() do
        -- **如果处于反查模式，直接返回，不执行替换**
        if env.is_radical_mode then
            yield(cand)
            goto continue
        end

        local genuine_cand = cand:get_genuine()
        local preedit = genuine_cand.preedit or ""

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
        yield(genuine_cand)
        ::continue::
    end
end

return modify_preedit_filter