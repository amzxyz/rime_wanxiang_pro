--万象家族lua,超级提示,表情\化学式\方程式\简码等等直接上屏,不占用候选位置
--采用leveldb数据库,支持大数据遍历,支持多种类型混合,多种拼音编码混合,维护简单
--支持候选匹配和编码匹配两种
--https://github.com/amzxyz/rime_wanxiang_pro
--     - lua_processor@*super_tips_phone*S               #超级提示模块：表情、简码、翻译、化学式
--     - lua_filter@*super_tips_phone*M                  #如果只放到lua_processor一个模块里手机就无法刷新界面,只能分开实现
--     key_binder/tips_key: "slash"     参数配置
local _db_pool = _db_pool or {}  -- 数据库池

-- 获取或创建 LevelDb 实例，避免重复打开
local function wrapLevelDb(dbname, mode)
    -- 检查数据库池是否已经包含该数据库
    _db_pool[dbname] = _db_pool[dbname] or LevelDb(dbname)
    local db = _db_pool[dbname]
    
    -- 如果数据库对象存在且未加载，打开数据库
    if db and not db:loaded() then
        if mode then
            db:open()  -- 打开数据库用于写入
        else
            db:open_read_only()  -- 只读模式打开数据库
        end
    end

    return db
end

local M = {}

-- 初始化词典并加载数据到 LevelDB
function M.init(env)
    local config = env.engine.schema.config
    M.tips_key = config:get_string('key_binder/tips_key')
    local db = wrapLevelDb('tips', true)  -- 用于存储词典的 LevelDb 数据库，打开写入模式
    local path = rime_api.get_user_data_dir() .. "/jm_dicts/tips_show.txt"
    local file = io.open(path, "r")
    if not file then
        db:close()  -- 关闭数据库连接
        return
    end
    -- 从文本文件加载词典并写入到数据库
    for line in file:lines() do
        if string.sub(line, 1, 1) == "#" then goto continue end
        local value, key = line:match("([^\t]+)\t([^\t]+)")
        if value and key then
            db:update(key, value)  -- 将词条写入数据库
        end
        ::continue::
    end
    file:close()
    db:close()  -- 关闭数据库连接
end


-- 处理候选词及提示逻辑
function M.func(input, env)
    local segment = env.engine.context.composition:back()
    local input_text = env.engine.context.input
    env.settings = {super_tips = env.engine.context:get_option("super_tips")} or true
    local is_super_tips = env.settings.super_tips
    -- 从数据库中查询与输入文本匹配的词条
    local db = wrapLevelDb('tips', false)  -- 只读模式打开数据库
    local stick_phrase = db:fetch(input_text)

    -- 检查 segment 是否有效
    if not segment then
        return 2  -- 如果 segment 无效，直接返回
    end
    -- 获取选中候选词，滤镜阶段无法使用，为了解决手机上lua_processor阶段不能刷新的问题，放弃这种匹配
   -- local selected_cand = env.engine.context:get_selected_candidate()
   -- local selected_cand_match = nil
   -- if selected_cand then
   --     selected_cand_match = db:fetch(selected_cand.text)
   -- end
    local first_cand = nil
    local candidates = {}

   -- 收集候选词
    for cand in input:iter() do
        if not first_cand then
            first_cand = cand
        end
        table.insert(candidates, cand)
    end

   -- 匹配第一候选词
    local first_cand_match = db:fetch(first_cand.text)
    -- 确定最终提示
    local tips = stick_phrase or first_cand_match

    -- 如果启用了超级提示，并且有提示内容，更新提示
    if tips and tips ~= "" and is_super_tips then
        -- 设置候选词提示内容
        segment.prompt = "〔" .. tips .. "〕"
    else
        segment.prompt = ""  -- 没有提示内容时清空提示
    end
    -- 重新输出候选词
    for _, cand in ipairs(candidates) do
        yield(cand)
    end
end
local S = {}

function S.init(env)
    local config = env.engine.schema.config
    S.tips_key = config:get_string('key_binder/tips_key')
end
function S.func(key, env)
    local engine = env.engine
    local context = env.engine.context
    local segment = env.engine.context.composition:back()
    env.settings = {super_tips = env.engine.context:get_option("super_tips")} or true
    local is_super_tips = env.settings.super_tips
    -- 检查 segment 是否有效
    if not segment then
        return 2  -- 如果 segment 无效，直接返回
    end
    local tips = segment.prompt
    if (context:is_composing() or context:has_menu()) and (S.tips_key) and is_super_tips then
        -- 按下时直接检查键值
        if (key:repr() == S.tips_key) then
            local formatted_commit_text = tips:match("〔.+：(.*)〕") or tips:match("〔.+:(.*)〕") or tips  --最终上屏字符串是去掉提示类型的有效内容,兼容中英文冒号作为分割
            engine:commit_text(formatted_commit_text)
            context:clear()
            return 1
        end
    end
    return 2
end
return {M = M, S = S}