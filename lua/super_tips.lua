local M = {}

-- 初始化
function M.init(env)
    local config = env.engine.schema.config
    M.tips_key = config:get_string('key_binder/tips_key')
    env.filter_dict = ReverseLookup("wanxiang_tips")
end

-- 清理资源
function M.fini(env)
    env.filter_dict = nil  -- 清除字典
    collectgarbage()  -- 强制回收内存
end

-- 处理候选词及提示逻辑
function M.func(key, env)
    local engine = env.engine
    local context = engine.context
    local segment = context.composition:back()

    -- 如果没有候选词，退出
    if not segment then return 2 end

    local input_text = context.input or ""
    env.settings = { super_tips = context:get_option("super_tips") } or true
    local is_super_tips = env.settings.super_tips

    local dict = env.filter_dict  -- 使用 ReverseLookup 加载的字典
    if not dict then return 2 end  -- 如果字典没有加载，直接返回

    -- 使用字典的 lookup 方法进行查找
    local tips = dict:lookup(input_text)

    -- 获取当前选择的候选词的匹配
    local selected_cand = context:get_selected_candidate()
    local selected_cand_match = selected_cand and dict:lookup(selected_cand.text) or nil

    -- 如果有提示内容，则使用优先级较高的提示
    tips = tips or selected_cand_match
    env.last_tips = env.last_tips or ""

    -- 如果启用了超级提示，设置提示内容
    if is_super_tips and tips and tips ~= "" then
        env.last_tips = tips
        segment.prompt = "〔" .. tips .. "〕"
    else
        -- 如果提示内容和上次相同，清空提示
        if segment.prompt == "〔" .. env.last_tips .. "〕" then
            segment.prompt = ""
        end
    end

    -- 如果按下了指定的提示键，并且启用了超级提示功能
    if (context:is_composing() or context:has_menu()) and M.tips_key and is_super_tips then
        local trigger = key:repr() == M.tips_key
        local text = selected_cand and selected_cand.text or input_text

        if trigger then
            local formatted = tips and (tips:match(".+：(.*)") or tips:match(".+:(.*)") or tips) or ""
            engine:commit_text(formatted)  -- 提交文本
            context:clear()  -- 清空输入框
            return 1
        end
    end

    return 2
end
return M