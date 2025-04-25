--万象拼音方案新成员，手动自由排序
--一个基于快捷键计数偏移量来手动调整排序的工具
--这个版本是db数据库支持的版本,可能会支持更多的排序记录,作为一个备用版本留存
--ctrl+j左移 ctrl+k左移  ctrl+0移除排序信息,固定词典其实没必要删除,直接降权到后面
--排序算法可能还不完美,有能力的朋友欢迎帮忙变更算法
-- 序列化并写入文件的函数
function write_word_to_file(env, record_type)
    local filename = rime_api.get_user_data_dir() .. "/lua/seq_words.lua"
    if not filename then
        return false
    end
    local serialize_str = ""  --返回数据部分
    -- 遍历表中的每个元素并格式化
    for phrase, entry in pairs(env.seq_words) do
        serialize_str = serialize_str .. string.format('    ["%s"] = {%d},\n', phrase, entry[1])  -- entry[1]为偏移量
    end
    -- 构造完整的 record 内容
    local record = "local seq_words = {\n" .. serialize_str .. "}\nreturn seq_words"
    -- 打开文件进行写入
    local fd = assert(io.open(filename, "w"))
    fd:setvbuf("line")
    -- 写入完整内容
    fd:write(record)
    fd:close()  -- 关闭文件
end
local P = {}
function P.init(env)
    env.seq_words = require("seq_words")  -- 加载文件中的 seq_words
end
-- P 阶段按键处理
function P.func(key_event, env)
    local context = env.engine.context
    local input_text = context.input
    local segment = context.composition:back()
    if not segment then
        return 2
    end
    if not key_event:ctrl() or key_event:release() then
        return 2
    end
    local selected_candidate = context:get_selected_candidate()
    local phrase = selected_candidate.text
    local preedit = selected_candidate.preedit
    local current_position = env.seq_words[phrase] and env.seq_words[phrase][1]  -- 获取对应的偏移量
    -- 判断按下的键
    if key_event.keycode == 0x6A then  -- ctrl + j (向左移动 1 个)
        if current_position == nil then
            env.seq_words[phrase] = { -1 }
        else
            local new_position = current_position - 1
            if new_position == 0 then
                env.seq_words[phrase] = nil
            else
                env.seq_words[phrase][1] = new_position  -- 更新偏移量
            end
        end
    elseif key_event.keycode == 0x6B then  -- ctrl + k (向右移动 1 个)
        if current_position == nil then
            env.seq_words[phrase] = { 1 }
        else
            local new_position = current_position + 1
            if new_position == 0 then
                env.seq_words[phrase] = nil
            else
                env.seq_words[phrase][1] = new_position  -- 更新偏移量
            end
        end
    elseif key_event.keycode == 0x30 then  -- ctrl + 0 (删除位移信息)
        env.seq_words[phrase] = nil
    else
        return 2
    end
    -- 实时更新 Lua 表序列化并保存
    write_word_to_file(env, "seq")  -- 使用统一的写入函数
    context:refresh_non_confirmed_composition()
    return 1
end


local F = {}
local MAX_CANDIDATES = 300

function F.init(env)
    env.seq_words = require("seq_words") or {}
end

function F.func(input, env)
    local seen = {}
    local displaced = {}   -- 有偏移项
    local fallback = {}    -- 无偏移项
    local result = {}      -- 最终结果
    local occupied = {}    -- 位置是否已被占用
    local original_positions = {}  -- 记录每个候选的原始 index

    local index = 1  -- 原始顺序编号
    for cand in input:iter() do
        if index > MAX_CANDIDATES then break end
        local text = cand.text
        if not seen[text] then
            seen[text] = true
            original_positions[text] = index

            local displacement = env.seq_words[text] and env.seq_words[text][1]
            if displacement then
                local pos = index + displacement
                pos = math.max(pos, 1)  -- 限制左移最小为 1
                pos = math.min(pos, MAX_CANDIDATES) -- 限制右移最大不超边界
                table.insert(displaced, {candidate = cand, target_pos = pos})
            else
                table.insert(fallback, cand)
            end

            index = index + 1
        end
    end

    local candidate_count = index - 1
    local max_pos = 0

    -- 插入有偏移量的候选
    for _, item in ipairs(displaced) do
        local pos = math.min(item.target_pos, candidate_count)
        while occupied[pos] do
            pos = pos + 1
            if pos > candidate_count then
                break
            end
        end
        if pos <= candidate_count then
            result[pos] = item.candidate
            occupied[pos] = true
            if pos > max_pos then max_pos = pos end
        else
            table.insert(fallback, item.candidate)
        end
    end

    -- 填充剩余候选
    local insert_pos = 1
    for _, cand in ipairs(fallback) do
        while occupied[insert_pos] do
            insert_pos = insert_pos + 1
        end
        result[insert_pos] = cand
        occupied[insert_pos] = true
        if insert_pos > max_pos then max_pos = insert_pos end
    end

    -- 输出排序结果
    local sorted = {}
    for i = 1, max_pos do
        if result[i] then
            table.insert(sorted, result[i])
        end
    end

    for _, cand in ipairs(sorted) do
        yield(cand)
    end
end
return { F = F, P = P }