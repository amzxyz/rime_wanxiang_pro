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

-- #########################
-- # 辅助码拆分提示模块 (chaifen)
-- PRO 专用
-- #########################
local CF = {}
function CF.init(env)
    local is_pro_scheme = wanxiang.is_pro_scheme(env)
    if is_pro_scheme then
        -- 初始化拆分词典（reverse.bin 形式）
        if env.chaifen_dict == nil then
            env.chaifen_dict = ReverseLookup("wanxiang_lookup")
        end
    end
end

function CF.fini(env)
    if env.chaifen_dict ~= nil then
        env.chaifen_dict = nil
        collectgarbage()
    end
end

-- 拆分功能：返回拆分注释
function CF.get_comment(cand, env, initial_comment)
    local dict = env.chaifen_dict
    if not dict then return nil end

    local append = dict:lookup(cand.text)
    if append ~= "" then
        if initial_comment and initial_comment ~= "" then
            return append
        end
    end
    return nil
end

-- #########################
-- # 错音错字提示模块 (Corrector)
-- #########################
local CR = {}
local corrections_cache = nil -- 用于缓存已加载的词典

function CR.init(env)
    -- 使用设置好的 corrector_type 和样式
    CR.style = env.settings.corrector_type or '{comment}'

    if corrections_cache then return end

    local auto_delimiter = env.settings.auto_delimiter
    local file, close_file, err = wanxiang.load_file_with_fallback("cn_dicts/corrections.dict.yaml")

    if not file then
        log.error(string.format("[wanxiang/super_comment]: 加载 corrections file 失败：%s", err))
    end

    corrections_cache = {}
    for line in file:lines() do
        if not line:match("^#") then
            local text, code, weight, comment = line:match("^(.-)\t(.-)\t(.-)\t(.-)$")
            if text and code then
                text = text:match("^%s*(.-)%s*$")
                code = code:match("^%s*(.-)%s*$")
                comment = comment and comment:match("^%s*(.-)%s*$") or ""
                -- 用自动分隔符替换空格
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
local function get_az_comment_pro(env, initial_comment)
    local final_comment = nil -- 初始化最终注释为空

    -- 使用空格将注释分割成多个片段
    local segments = {}
    for segment in initial_comment:gmatch("[^%s]+") do
        table.insert(segments, segment)
    end

    local pinyins = {} -- 存储多个拼音
    local fuzhu = nil  -- 辅助码
    -- 遍历分割后的片段，提取拼音和辅助码
    for _, segment in ipairs(segments) do
        local pinyin = segment:match("^[^;]+")   -- 提取注释中的拼音部分
        local fz = segment:match("^[^;]*;?(.*)") -- 提取分号后面的所有字符作为辅助码（允许缺失）

        if pinyin then
            table.insert(pinyins, pinyin) -- 收集拼音
        end

        if fuzhu == nil and fz and string.len(fz) > 0 then
            fuzhu = fz -- 同一个字的符码都是一样的，仅获取第一个辅助码
        end

        -- 如果存在拼音和辅助码，则生成最终注释
        if #pinyins > 0 then
            local pinyin_str = table.concat(pinyins, ",") -- 用逗号分隔多个拼音
            if fuzhu then
                -- 存在辅助码时，生成带 "辅" 的注释
                final_comment = string.format("〔音%s 辅%s〕", pinyin_str, fuzhu)
            else
                -- 不存在辅助码时，只生成带拼音的注释
                final_comment = string.format("〔音%s〕", pinyin_str)
            end
        end
    end

    return final_comment or "" -- 确保返回最终值
end

-- 处理函数，只负责处理候选词的注释
---@return string
local function get_az_comment(_, env, initial_comment)
    local is_pro_scheme = wanxiang.is_pro_scheme(env)

    if is_pro_scheme then
        return get_az_comment_pro(env, initial_comment)
    end

    local final_comment = nil -- 初始化最终注释为空
    -- 如果注释不为空，添加括号
    if initial_comment and initial_comment ~= "" then
        final_comment = string.format("〔 %s 〕", initial_comment)
    end
    return final_comment or "" -- 返回最终注释
end

-- #########################
-- 主函数：根据优先级处理候选词的注释
-- #########################
-- 主函数：根据优先级处理候选词的注释
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
    }

    local is_pro_scheme = wanxiang.is_pro_scheme(env)
    if is_pro_scheme then
        env.settings.fuzhu_type = config:get_string("super_comment/fuzhu_type") or "" -- 辅助码类型
    end

    CR.init(env)
    CF.init(env)
end

function ZH.fini(env)
    -- 清理
    CF.fini(env)
end

-- #########################
-- # 辅助码提示模块 (Fuzhu)
-- PRO 专用
-- #########################
local function get_fz_comment(cand, env, initial_comment)
    -- 确保候选词长度检查使用从配置中读取的值
    local length = utf8.len(cand.text)
    if length > env.settings.candidate_length then
        return ""
    end

    local segments = {}
    -- 先用空格将分隔符分成多个片段
    local auto_delimiter = env.settings.auto_delimiter
    for segment in string.gmatch(initial_comment, "[^" .. auto_delimiter .. "]+") do
        table.insert(segments, segment)
    end

    -- 提取匹配内容
    local fuzhu_comments = {}
    for _, segment in ipairs(segments) do
        local match = segment:match(";(.+)$") -- 提取分号后面的内容作为辅助码
        if match then
            table.insert(fuzhu_comments, match)
        end
    end

    local final_comment = nil
    -- 将提取的拼音片段用空格连接起来
    if #fuzhu_comments > 0 then
        final_comment = table.concat(fuzhu_comments, "/")
    end

    return final_comment or "" -- 确保返回最终值
end

local function get_pro_fz_cl_comment(env, cand, index, initial_comment)
    local final_comment = initial_comment

    local is_fuzhu_enabled = env.engine.context:get_option("fuzhu_switch")     -- 辅助码是否开启
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
        local cf_comment = CF.get_comment(cand, env, initial_comment)
        if cf_comment then
            final_comment = cf_comment
        end
    end

    return final_comment
end

-- #########################
-- # 拼音提示模块 (PinyinHint)
-- #########################
local function get_py_comment(cand, env, initial_comment)
    local auto_delimiter = env.settings.auto_delimiter
    initial_comment = initial_comment:gsub(auto_delimiter, " ")

    local is_pinyinhint_enabled = env.engine.context:get_option("pinyinhint")
    if is_pinyinhint_enabled and utf8.len(cand.text) <= env.settings.candidate_length then
        return initial_comment
    else
        return ""
    end
end

local function get_basic_fz_comment(env, cand, initial_comment)
    local is_pinyinhint_enabled = env.engine.context:get_option("pinyinhint")

    -- 如果辅助码显示未开启
    if not is_pinyinhint_enabled then return "" end

    local final_comment = initial_comment

    local py_comment = get_py_comment(cand, env, initial_comment)
    if py_comment then
        final_comment = py_comment
    end
    return final_comment
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
        local final_comment = is_pro_scheme
            and get_pro_fz_cl_comment(env, cand, index, initial_comment)
            or get_basic_fz_comment(env, cand, initial_comment)

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
