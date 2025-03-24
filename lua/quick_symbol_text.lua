-- 欢迎使用万象拼音方案
-- @amzxyz
-- https://github.com/amzxyz/rime_wanxiang
-- https://github.com/amzxyz/rime_wanxiang_pro
-- 本lua通过定义一个不直接上屏的引导符号搭配26字母实现快速符号输入，并在双击''上屏上一次的符号，双击;;重复上屏上次的汉字和字母
-- 使用方式加入到函数 - lua_processor@*quick_symbol_text 下面
-- 方案文件配置,
-- recognizer/patterns/quick_symbol: "^'.*$"
-- recognizer/patterns/quick_text: "^;.*$"
--你可以在方案文件中如下去针对性的替换符号的设定，或者a-z全部替换
--quick_symbol_text:
  --q: "wwwwwwwww"
  --w: "？"



-- 读取 RIME 配置文件中的符号映射表
local function load_mapping_from_config(config)
    local symbol_map = {}
    local keys = "qwertyuiopasdfghjklzxcvbnm1234567890"
    
    for key in keys:gmatch(".") do
        local symbol = config:get_string("quick_symbol_text/" .. key)
        if symbol then
            symbol_map[key] = symbol
        end
    end
    return symbol_map
end

-- 默认符号映射表
local default_mapping = {
    q = "“", w = "？", e = "（", r = "）", t = "~", y = "·", u = "『", i = "』", o = "〖", p = "〗",
    a = "！", s = "……", d = "、", f = "“", g = "”", h = "‘", j = "’", k = "【", l = "】",
    z = "。", x = "？", c = "！", v = "——", b = "%", n = "《", m = "》",
    ["1"] = "①", ["2"] = "②", ["3"] = "③", ["4"] = "④", ["5"] = "⑤", 
    ["6"] = "⑥", ["7"] = "⑦", ["8"] = "⑧", ["9"] = "⑨", ["0"] = "⓪"
}

-- 记录上次上屏的内容
local last_commit_symbol = ""  -- 存储符号的上屏历史
local last_commit_text = ""    -- 存储文本（汉字/字母）的上屏历史


-- 初始化符号输入的状态
local function init(env)
    local config = env.engine.schema.config
    
    -- 加载符号映射表，优先使用 RIME 配置，未找到的键使用默认值
    env.mapping = default_mapping
    local custom_mapping = load_mapping_from_config(config)
    for k, v in pairs(custom_mapping) do
        env.mapping[k] = v  -- 仅替换配置中存在的键
    end
    
    local quick_symbol_pattern = config:get_string("recognizer/patterns/quick_symbol") or "^'.*$"
    local quick_text_pattern = config:get_string("recognizer/patterns/quick_text") or "^;.*$"
    
    local quick_symbol = string.sub(quick_symbol_pattern, 2, 2) or "'"
    local quick_text = string.sub(quick_text_pattern, 2, 2) or ";"
    
    env.single_symbol_pattern = "^" .. quick_symbol .. "([a-zA-Z0-9])$"
    env.double_symbol_pattern_symbol = "^" .. quick_symbol .. quick_symbol .. "$"
    env.double_symbol_pattern_text = "^" .. quick_text .. quick_text .. "$"

    env.engine.context.commit_notifier:connect(function(ctx)
        local commit_text = ctx:get_commit_text()
        
        if commit_text:match("[%p%s]+") then
            last_commit_symbol = commit_text
        else
            last_commit_text = commit_text
        end
    end)
end

-- 处理符号和文本的重复上屏逻辑
local function processor(key_event, env)
    local engine = env.engine
    local context = engine.context
    local input = context.input

    if string.match(input, env.double_symbol_pattern_text) then
        if last_commit_text ~= "" then
            engine:commit_text(last_commit_text)
            context:clear()
            return 1
        end
    end

    if string.match(input, env.double_symbol_pattern_symbol) then
        if last_commit_symbol ~= "" then
            engine:commit_text(last_commit_symbol)
            context:clear()
            return 1
        end
    end

    local match = string.match(input, env.single_symbol_pattern)
    if match then
        local symbol = env.mapping[match]
        if symbol then
            engine:commit_text(symbol)
            last_commit_symbol = symbol
            context:clear()
            return 1
        end
    end

    return 2
end

return { init = init, func = processor }
