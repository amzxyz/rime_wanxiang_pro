local M = {}
local S = {}

-- 初始化
function M.init(env)
    local config = env.engine.schema.config
    M.tips_key = config:get_string("key_binder/tips_key")
    env.filter_dict = ReverseLookup("wanxiang_tips")     -- 使用 ReverseLookup
end
-- 清理资源
function M.fini(env)
    env.filter_dict = nil  -- 清除字典
    collectgarbage()  -- 强制回收内存
end

-- 滤镜：设置提示内容
function M.func(input, env)
    local segment = env.engine.context.composition:back()
    -- 如果没有 segment，立即执行清理和退出
    if not segment then return 2 end

    local input_text = env.engine.context.input
    env.settings = { super_tips = env.engine.context:get_option("super_tips") } or true
    local is_super_tips = env.settings.super_tips

    local dict = env.filter_dict  -- 使用 ReverseLookup 加载的字典
    if not dict then return 2 end  -- 如果字典没有加载，则返回

    -- 使用字典的 lookup 方法进行查找
    local stick_phrase = dict:lookup(input_text)

    local first_cand, candidates = nil, {}
    for cand in input:iter() do
        if not first_cand then first_cand = cand end
        table.insert(candidates, cand)
    end

    local first_cand_match = first_cand and dict:lookup(first_cand.text)
    local tips = stick_phrase or first_cand_match
    env.last_tips = env.last_tips or ""

    if is_super_tips and tips and tips ~= "" then
        env.last_tips = tips
        segment.prompt = "〔" .. tips .. "〕"
    else
        if segment.prompt == "〔" .. env.last_tips .. "〕" then
            segment.prompt = ""
        end
    end
    for _, cand in ipairs(candidates) do
        yield(cand)  -- 输出候选词
    end
end

-- Processor：按键触发上屏
function S.init(env)
    local config = env.engine.schema.config
    S.tips_key = config:get_string("key_binder/tips_key")
end
function S.func(key, env)
    local context = env.engine.context
    local segment = context.composition:back()
    if not segment then return 2 end

    env.settings = { super_tips = context:get_option("super_tips") } or true
    local is_super_tips = env.settings.super_tips
    local tips = segment.prompt

    if (context:is_composing() or context:has_menu()) and S.tips_key and is_super_tips then
        if key:repr() == S.tips_key then
            local formatted = tips and (
                tips:match("〔.+：(.*)〕") or
                tips:match("〔.+:(.*)〕") or
                tips
            ) or ""
            env.engine:commit_text(formatted)
            context:clear()
            return 1
        end
    end
    return 2
end
return { M = M, S = S }