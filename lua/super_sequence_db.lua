--万象拼音方案新成员，手动自由排序
--一个基于快捷键计数偏移量来手动调整排序的工具
--这个版本是db数据库支持的版本,可能会支持更多的排序记录,作为一个备用版本留存
--ctrl+j左移 ctrl+k左移  ctrl+0移除排序信息,固定词典其实没必要删除,直接降权到后面
--排序算法可能还不完美,有能力的朋友欢迎帮忙变更算法
-- 数据库操作
local _db_pool = _db_pool or {}
function wrapLevelDb(dbname, mode)
    _db_pool[dbname] = _db_pool[dbname] or LevelDb(dbname)
    local db = _db_pool[dbname]
    if db and not db:loaded() then
        if mode then
            db:open()  -- 读写模式
        else
            db:open_read_only()  -- 只读模式
        end
    end
    return db
end
-- P 阶段：按键事件处理
local P = {}
function P.func(key_event, env)
    local context = env.engine.context
    local db = wrapLevelDb('lua/seq', true)
    local input_text = context.input
    -- 判断输入的文本，执行备份或导入操作
    if input_text == "/update" then
        -- 执行更新操作，从文件导入数据到数据库
        import_txt_to_db(db, 'seq_backup.txt')  -- 将数据库实例传递进去
        context:clear()
        return 1  -- 返回 1，表示成功执行更新
    elseif input_text == "/backup" then
        -- 执行备份操作，将数据库内容导出到文本文件
        backup_db_to_txt(db, 'seq_backup.txt')  -- 将数据库实例传递进去
        context:clear()
        return 1  -- 返回 1，表示成功执行备份
    end
    local segment = context.composition:back()
    if not segment then
        return 2
    end
    if not key_event:ctrl() or key_event:release() then
        return 2
    end
 
    local selected_candidate = context:get_selected_candidate()
    local phrase = selected_candidate.text
    local annotation = selected_candidate.preedit
    local candidate_key = annotation .. "_" .. phrase
    local current_position = tonumber(db:fetch(candidate_key))  -- 获取当前候选词的位置

    -- 判断按下的键
    if key_event.keycode == 0x6A then  -- ctrl + j (向左移动 1 个)
        if current_position == nil then
            -- 如果当前候选词没有位置，初始化为 -1
            db:update(candidate_key, tostring(-1))  -- 初始位置为 -1
        else
            local new_position = current_position - 1
            if new_position == 0 then
                db:erase(candidate_key)  -- 如果目标位置为 0，删除当前候选词
            else
                db:update(candidate_key, tostring(new_position))   -- 如果没有冲突，直接更新
            end
        end
    elseif key_event.keycode == 0x6B then  -- ctrl + k (向右移动 1 个)
        if current_position == nil then
            -- 如果当前候选词没有位置，初始化为 1
            db:update(candidate_key, tostring(1))  -- 初始位置为 1
        else
            if new_position == 0 then
                db:erase(candidate_key)  
            else
                db:update(candidate_key, tostring(new_position))   
            end
        end
    elseif key_event.keycode == 0x30 then  -- ctrl + 0 (删除)
        db:erase(candidate_key)
    else
        return 2  -- 未处理的按键
    end
    context:refresh_non_confirmed_composition()
    return 1
end
-- 优化后的备份和导入操作
function backup_db_to_txt(db, output_file)
    local user_data_dir = rime_api.get_user_data_dir()
    local file_path = user_data_dir .. "/" .. output_file
    local file = io.open(file_path, "w")
    if not file then return end
    
    -- 一次性获取所有数据，减少查询次数
    local accessor = db:query("")
    local data = {}
    for key, value in accessor:iter() do
        table.insert(data, string.format("%s\t%s", key, value))
    end
    file:write(table.concat(data, "\n"))
    file:close()
    collectgarbage()  -- 手动触发垃圾回收
end

function import_txt_to_db(db, input_file)
    local user_data_dir = rime_api.get_user_data_dir()
    local file_path = user_data_dir .. "/" .. input_file
    local file = io.open(file_path, "r")
    if not file then return end
    
    local data = file:read("*a")  -- 一次性读取整个文件
    file:close()
    
    for line in data:gmatch("([^\n]+)") do
        local key, value = line:match("^(.-)\t(.-)$")
        if key and value then
            db:update(key, value)
        end
    end
    collectgarbage()  -- 手动触发垃圾回收
end
local F = {}

-- 执行候选词排序
function sort_candidates(input, db)
    local final_list = {}
    local adjusted_positions = {}
    local index = 1
    for cand in input:iter() do
        local key = cand.preedit .. "_" .. cand.text
        local displacement = tonumber(db:fetch(key))
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

-- 处理输入事件并优化
function F.func(input, env)
    local context = env.engine.context
    local db = wrapLevelDb('lua/seq', false)

    local sorted = sort_candidates(input, db)
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