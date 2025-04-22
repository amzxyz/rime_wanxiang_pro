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
    for candidate_key, entry in pairs(env.seq_words) do
        serialize_str = serialize_str .. string.format('    ["%s"] = {%d},\n', candidate_key, entry[1])  -- entry[1]为偏移量
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
    local candidate_key = preedit .. "_" .. phrase
    local current_position = env.seq_words[candidate_key] and env.seq_words[candidate_key][1]  -- 获取对应的偏移量
    -- 判断按下的键
    if key_event.keycode == 0x6A then  -- ctrl + j (向左移动 1 个)
        if current_position == nil then
            env.seq_words[candidate_key] = { -1 }
        else
            local new_position = current_position - 1
            if new_position == 0 then
                env.seq_words[candidate_key] = nil
            else
                env.seq_words[candidate_key][1] = new_position  -- 更新偏移量
            end
        end
    elseif key_event.keycode == 0x6B then  -- ctrl + k (向右移动 1 个)
        if current_position == nil then
            env.seq_words[candidate_key] = { 1 }
        else
            local new_position = current_position + 1
            if new_position == 0 then
                env.seq_words[candidate_key] = nil
            else
                env.seq_words[candidate_key][1] = new_position  -- 更新偏移量
            end
        end
    elseif key_event.keycode == 0x30 then  -- ctrl + 0 (删除位移信息)
        env.seq_words[candidate_key] = nil
    else
        return 2
    end
    -- 实时更新 Lua 表序列化并保存
    write_word_to_file(env, "seq")  -- 使用统一的写入函数
    context:refresh_non_confirmed_composition()
    return 1
end
function sort_candidates(input, env)
    local final_list = {}
    local adjusted_positions = {}

    -- 遍历输入一次，分类和准备候选词
    local index = 1
    for cand in input:iter() do
        local key = cand.preedit .. "_" .. cand.text
        local displacement = env.seq_words[key] and env.seq_words[key][1]  -- env.seq_words[key][1]是偏移量

        if displacement then
            local target_pos = index + displacement
            target_pos = math.max(target_pos, 1)

            -- 确保目标位置是空的
            while adjusted_positions[target_pos] do
                target_pos = target_pos + 1
            end

            final_list[target_pos] = cand
            adjusted_positions[target_pos] = true
        else
            -- 如果没有偏移量，插入原始候选词
            while adjusted_positions[index] do
                index = index + 1  -- 跳过已经填充的目标位置
            end

            final_list[index] = cand
            adjusted_positions[index] = true
            index = index + 1
        end
    end

    -- 转换最终的候选词列表
    local sorted = {}
    for pos = 1, #final_list do
        if final_list[pos] then
            table.insert(sorted, final_list[pos])
        end
    end

    return sorted
end
local F = {}
-- 初始化时加载数据
function F.init(env)
    local config = env.engine.schema.config
    env.seq_words = require("seq_words") or {} --加载 seq_words 数据
end
function F.func(input, env)
    local sorted = sort_candidates(input, env)
    for _, cand in ipairs(sorted) do
        yield(cand)
    end
    -- 如果没有排序到任何候选词，回退到默认行为
    if #sorted == 0 then
        for cand in input:iter() do
            yield(cand)
        end
    end
end
return { F = F, P = P }