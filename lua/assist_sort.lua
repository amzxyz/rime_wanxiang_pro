
local M = {}
-- **获取辅助码**
function M.run_fuzhu(cand, env, initial_comment)
    local patterns = {
        moqi = "[^;]*;([^;]*);",
        flypy = "[^;]*;[^;]*;([^;]*);",
        zrm = "[^;]*;[^;]*;[^;]*;([^;]*);",
        jdh = "[^;]*;[^;]*;[^;]*;[^;]*;([^;]*);",
        cj = "[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;([^;]*);",
        tiger = "[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;([^;]*);",
        wubi = "[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;([^;]*);",
        hanxin = "[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;([^;]*)"
    }
    local pattern = patterns[env.settings.fuzhu_type]
    if not pattern then return {}, {} end  

    local full_fuzhu_list, first_fuzhu_list = {}, {}

    for segment in initial_comment:gmatch("[^%s]+") do
        local match = segment:match(pattern)
        if match then
            for sub_match in match:gmatch("[^,]+") do
                table.insert(full_fuzhu_list, sub_match)
                local first_char = sub_match:sub(1, 1)
                if first_char and first_char ~= "" then
                    table.insert(first_fuzhu_list, first_char)
                end
            end
        end
    end
    return full_fuzhu_list, first_fuzhu_list
end
-- 判断是否为字母、数字或特定符号
local function is_alnum(text)
    return text:match("^[%w%s.·-_']+$") ~= nil
end
-- 主逻辑
function M.func(input, env)
    local input_code = env.engine.context.input
    local input_len = utf8.len(input_code)
    -- 如果输入长度小于3或大于4，直接返回所有候选
    if input_len < 3 or input_len > 4 then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end
    local last_two = input_code:sub(-2)                -- 最后两位：用于 full 匹配
    local second_last_char = input_code:sub(-2, -2)    -- 倒数第二位：用于 first 匹配
    local moved, reordered, otherss, alnum_cands, other_cands = {}, {}, {}, {}, {}
    -- 遍历候选并进行匹配
    for cand in input:iter() do
        local text_len = utf8.len(cand.text)
        -- 如果是单字符且符合辅助码匹配
        if text_len == 1 then
            local full, first = M.run_fuzhu(cand, cand.comment or "")
            local matched = false
            -- 完全匹配（双位辅助码）
            for _, code in ipairs(full) do
                if code == last_two then
                    matched = true
                    table.insert(moved, cand)  -- 完全匹配，优先排序
                    break
                end
            end
            -- 部分匹配（单位辅助码）
            if not matched then
                for _, code in ipairs(first) do
                    if code == second_last_char then
                        matched = true
                        table.insert(reordered, cand)  -- 部分匹配，次优排序
                        break
                    end
                end
            end
            -- 如果都没有匹配，放到其他组
            if not matched then
                table.insert(otherss, cand)
            end
        -- 如果是字母、数字或特殊符号的候选
        elseif is_alnum(cand.text) then
            table.insert(alnum_cands, cand)
        -- 其他情况
        else
            table.insert(other_cands, cand)
        end
    end
    -- 确保输出顺序：先完全匹配，再部分匹配，再字母数字，最后未匹配的
    for _, v in ipairs(other_cands) do yield(v) end
    for _, v in ipairs(moved) do yield(v) end
    for _, v in ipairs(reordered) do yield(v) end
    for _, v in ipairs(otherss) do yield(v) end
    for _, v in ipairs(alnum_cands) do yield(v) end
end
return M