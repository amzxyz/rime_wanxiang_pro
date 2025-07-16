-- 欢迎使用万象拼音方案
-- @amzxyz
-- https://github.com/amzxyz/rime_wanxiang
--给自定义用户词增加一个可以插入其他类型如换行、制表符等，从而上屏格式化的内容格式
local function text_formatting(input, env)
    -- 定义要处理的转义序列映射表
    local escape_map = {
        ["\\n"] = "\n",  -- 换行符
        ["\\t"] = "\t",  -- 制表符
        ["\\r"] = "\r",  -- 回车符
        ["\\\\"] = "\\", -- 反斜杠本身
        ["\\s"] = " ",   -- 空格（自定义）
        ["\\d"] = "-",   -- 短横线（自定义）
        -- 添加更多需要的转义序列...
    }

    -- 构建匹配所有转义序列的模式
    local pattern = "\\[ntrsd\\\\]" -- 匹配 \n, \t, \r, \s, \d, \\

    for cand in input:iter() do
        -- 检查候选文本是否包含任何转义序列
        if cand.text:find(pattern) then
            -- 替换所有转义序列
            local new_text = cand.text:gsub(pattern, function(escape)
                return escape_map[escape] or escape -- 如果未定义，保留原样
            end)

            -- 创建新候选
            local new_cand = Candidate(
                cand.type,
                cand.start,
                cand._end,
                new_text,
                cand.comment
            )
            new_cand.preedit = cand.preedit

            -- 输出处理后的候选
            yield(new_cand)
        else
            -- 直接输出其他候选
            yield(cand)
        end
    end
end
return { func = text_formatting }