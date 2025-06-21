--@amzxyz https://github.com/amzxyz/rime_wanxiang
--由于comment_format不管你的表达式怎么写，只能获得一类输出，导致的结果只能用于一个功能类别
--如果依赖lua_filter载入多个lua也只能实现一些单一的、不依赖原始注释的功能，有的时候不可避免的发生一些逻辑冲突
--所以此脚本专门为了协调各式需求，逻辑优化，实现参数自定义，功能可开关，相关的配置跟着方案文件走，如下所示：
--将如下相关位置完全暴露出来，注释掉其它相关参数--
--  comment_format: {comment}   #将注释以词典字符串形式完全暴露，通过super_comment.lua完全接管。
--  spelling_hints: 10          # 将注释以词典字符串形式完全暴露，通过super_comment.lua完全接管。
--在方案文件顶层置入如下设置--
--#Lua 配置: 超级注释模块
--super_comment:                     # 超级注释，子项配置 true 开启，false 关闭
--  # 以下为 pro 版专用配置
--  fuzhu_code: true                 # 启用辅助码提醒，用于辅助输入练习辅助码，成熟后可关闭
--  # 以下为通用配置
--  candidate_length: 1              # 候选词辅助码提醒的生效长度，0为关闭  但同时清空其它，应当使用上面开关来处理
--  corrector: true                  # 启用错音错词提醒，例如输入 geiyu 给予 获得 jǐ yǔ 提示
--  corrector_type: "{comment}"      # 新增一个提示类型，比如"【{comment}】"

local wanxiang = require('wanxiang')
local patterns = {
    tone = "([^;]*);",
    moqi = "[^;]*;([^;]*);",
    flypy = "[^;]*;[^;]*;([^;]*);",
    zrm = "[^;]*;[^;]*;[^;]*;([^;]*);",
    jdh = "[^;]*;[^;]*;[^;]*;[^;]*;([^;]*);",
    tiger = "[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;([^;]*);",
    wubi = "[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;([^;]*);",
    hanxin = "[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;([^;]*)"
}
-- #########################
-- # 辅助码拆分提示模块 (chaifen)
-- PRO 专用
-- #########################
local CF = {}
function CF.init(env)
    if wanxiang.is_pro_scheme(env) then -- pro 版直接初始化
        CF.get_dict(env)
    end
end

function CF.fini(env)
    env.chaifen_dict = nil
    collectgarbage()
end

function CF.get_dict(env)
    if env.chaifen_dict == nil then
        env.chaifen_dict = ReverseLookup("wanxiang_lookup")
    end
    return env.chaifen_dict
end

function CF.get_comment(cand, env)
    local dict = CF.get_dict(env)
    if not dict then return "" end

    local raw = dict:lookup(cand.text)
    if raw == "" then return "" end
    -- 若无 ◉ 分隔符，直接返回整体
    if not string.find(raw, "◉") then
        return raw
    end
    -- 拆分段落
    local segments = {}
    for seg in string.gmatch(raw .. "◉", "(.-)◉") do
        table.insert(segments, seg)
    end
    -- 辅助码类型映射到段索引
    local index_map = {
        zrm = 1,
        moqi = 2,
        flypy = 3,
        hanxin = 4,
        jdh = 5
    }
    local fuzhu_type = env.settings.fuzhu_type or ""
    local idx = index_map[fuzhu_type]
    if not idx then return "" end
    -- 若该段超出范围或为空，返回空字符串
    return segments[idx] or ""
end

-- #########################
-- # 错音错字提示模块 (Corrector)
-- #########################
local CR = {}
local corrections_cache = nil -- 用于缓存已加载的词典
function CR.init(env)
    CR.style = env.settings.corrector_type or '{comment}'
    --if corrections_cache then return end
    local auto_delimiter = env.settings.auto_delimiter
    local is_pro = wanxiang.is_pro_scheme(env)
    -- 根据方案选择加载路径
    local path = (is_pro and "zh_dicts_pro/corrections.dict.yaml") or "zh_dicts/corrections.dict.yaml"
    local file, close_file, err = wanxiang.load_file_with_fallback(path)
    if not file then
        log.error(string.format("[super_comment]: 加载失败 %s，错误: %s", path, err))
        return
    end
    corrections_cache = {}
    for line in file:lines() do
        if not line:match("^#") then
            local text, code, weight, comment = line:match("^(.-)\t(.-)\t(.-)\t(.-)$")
            if text and code then
                text = text:match("^%s*(.-)%s*$")
                code = code:match("^%s*(.-)%s*$")
                comment = comment and comment:match("^%s*(.-)%s*$") or ""
                comment = comment:gsub("%s+", auto_delimiter)
                code = code:gsub("%s+", auto_delimiter)
                corrections_cache[code] = { text = text, comment = comment }
            end
        end
    end
    close_file()
end

function CR.get_comment(cand)
    -- 使用候选词的 comment 作为 code，在缓存中查找对应的修正
    local correction = nil
    if corrections_cache then
        correction = corrections_cache[cand.comment]
    end
    if correction and cand.text == correction.text then
        -- 用新的注释替换默认注释
        local final_comment = CR.style:gsub("{comment}", correction.comment)
        return final_comment
    end
    return nil
end

-- ################################
-- 部件组字返回的注释（radical_pinyin）
-- ################################
---@return string
local function get_az_comment(_, env, initial_comment)
    if not initial_comment or initial_comment == "" then return "" end
    local final_comment = nil
    local auto_delimiter = env.settings.auto_delimiter or " "
    -- 拆分各字注释段
    local segments = {}
    for segment in initial_comment:gmatch("[^%s]+") do
        table.insert(segments, segment)
    end
    local semicolon_count = select(2, segments[1]:gsub(";", "")) -- 使用第一个段判断
    local pinyins = {}
    local fuzhu = nil
    for _, segment in ipairs(segments) do
        local pinyin = segment:match("^[^;]+")
        local fz = nil

        if semicolon_count == 0 then
            -- 无分号，只收集拼音
            fz = nil
        elseif semicolon_count == 1 then
            -- 一个分号，取后段
            fz = segment:match(";(.+)$")
        else
            -- 多个分号，使用模式提取
            local pattern = patterns[env.settings.fuzhu_type]
            if pattern then
                fz = segment:match(pattern)
            end
        end

        if pinyin then table.insert(pinyins, pinyin) end
        if not fuzhu and fz and fz ~= "" then fuzhu = fz end
    end
    -- 拼接结果
    if #pinyins > 0 then
        local pinyin_str = table.concat(pinyins, ",")
        if fuzhu then
            final_comment = string.format("〔音%s 辅%s〕", pinyin_str, fuzhu)
        else
            final_comment = string.format("〔音%s〕", pinyin_str)
        end
    end
    return final_comment or ""
end
-- #########################
-- # 辅助码提示或带调全拼注释模块 (Fuzhu)
-- #########################
local function get_fz_comment(cand, env, initial_comment)
    local length = utf8.len(cand.text)
    if length > env.settings.candidate_length then
        return ""
    end
    local auto_delimiter = env.settings.auto_delimiter or " "
    local segments = {}
    for segment in string.gmatch(initial_comment, "[^" .. auto_delimiter .. "]+") do
        table.insert(segments, segment)
    end
    local fuzhu_type = env.settings.fuzhu_type
    -- 只用第一个片段来计算分号数量
    local first_segment = segments[1] or ""
    local semicolon_count = select(2, first_segment:gsub(";", ""))
    local fuzhu_comments = {}

    if semicolon_count == 0 then
        -- 第三种情况：无分号，直接输出原始注释（空格连接）匹配标准版的release版本
        return initial_comment:gsub(auto_delimiter, " ")
    elseif semicolon_count == 1 then
        -- 第二种情况：一个分号，提取其后内容,匹配pro的release版本
        for _, segment in ipairs(segments) do
            local match = segment:match(";(.+)$")
            if match then
                table.insert(fuzhu_comments, match)
            end
        end
    else
        -- 第一种情况：多个分号，依 fuzhu_type 使用对应 pattern 匹配,匹配pro的仓库版本
        local pattern = patterns[fuzhu_type]
        if pattern then
            for _, segment in ipairs(segments) do
                local match = segment:match(pattern)
                if match then
                    table.insert(fuzhu_comments, match)
                end
            end
        else
            return ""
        end
    end
    -- 最终拼接输出，fuzhu用 `,`，tone用 空格连接
    if #fuzhu_comments > 0 then
        if fuzhu_type == "tone" then
            return table.concat(fuzhu_comments, " ")
        else
            return table.concat(fuzhu_comments, ",")
        end
    else
        return ""
    end
end
local function get_pro_fz_cl_comment(env, cand, index, initial_comment)
    local final_comment = initial_comment
    local is_fuzhu_enabled = env.engine.context:get_option("comment_hint")     -- 辅助码/带调全拼等类型的注释是否开启
    local is_chaifen_enabled = env.engine.context:get_option("chaifen_switch") -- 拆分提示是否开启
    if not (is_fuzhu_enabled or is_chaifen_enabled) then
        return ""
    end
    -- 如果启用辅助码提示
    if is_fuzhu_enabled then
        local fz_comment = get_fz_comment(cand, env, initial_comment)
        if fz_comment then
            final_comment = fz_comment
        end
    end
    -- 拆分辅助码
    if is_chaifen_enabled then
        local cf_comment = CF.get_comment(cand, env)
        if cf_comment then
            final_comment = cf_comment
        end
    end
    return final_comment
end
-- #########################
-- 主函数：根据优先级处理候选词的注释
-- #########################
local ZH = {}
function ZH.init(env)
    local config = env.engine.schema.config
    local delimiter = config:get_string('speller/delimiter') or " '"
    local auto_delimiter = delimiter:sub(1, 1)
    env.settings = {
        delimiter = delimiter,
        auto_delimiter = auto_delimiter,
        corrector_enabled = config:get_bool("super_comment/corrector") or true,                -- 错音错词提醒功能
        corrector_type = config:get_string("super_comment/corrector_type") or "{comment}",     -- 提示类型
        candidate_length = tonumber(config:get_string("super_comment/candidate_length")) or 1, -- 候选词长度
        fuzhu_type = config:get_string("super_comment/fuzhu_type") or ""                       -- 辅助码类型
    }
    CR.init(env)
end

function ZH.fini(env)
    -- 清理
    CF.fini(env)
end

function ZH.func(input, env)
    -- 声明反查模式的 tag 状态
    local is_radical_mode = wanxiang.is_in_radical_mode(env)
    local is_pro_scheme = wanxiang.is_pro_scheme(env)
    local index = 0

    local input_str = env.engine.context.input
    -- 标注是否需要处理候选 comment
    -- 有些候选是动态生成的，非词库候选，不需要处理注释
    local should_skip_candidate_comment = input_str and input_str:match("^[VRNU/]")
    for cand in input:iter() do
        index = index + 1
        if should_skip_candidate_comment then
            yield(cand)
            goto continue
        end
        local initial_comment = cand.comment
        -- 辅助码提示注释
        local final_comment = get_pro_fz_cl_comment(env, cand, index, initial_comment)

        -- 错音错词提示注释
        if env.settings.corrector_enabled then
            local cr_comment = CR.get_comment(cand)
            if cr_comment then
                final_comment = cr_comment
            end
        end
        -- 部件组字注释
        if is_radical_mode then
            local az_comment = get_az_comment(cand, env, initial_comment)
            if az_comment then
                final_comment = az_comment
            end
        end
        -- 更新最终注释
        if final_comment ~= initial_comment then
            cand:get_genuine().comment = final_comment
        end
        yield(cand)
        ::continue::
    end
end

return ZH
