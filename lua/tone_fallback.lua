--@amzxyz https://github.com/amzxyz
--用来在声调辅助的时候当你输入2个数字的时候自动将声调替换为第二个数字，
--也就是说你发现输入错误声调你可以手动轮巡输入而不用回退删除直接输入下一个即可
local function tone_fallback(input, env)
    local ctx = env.engine.context
    -- 获取当前输入的内容
    local input_text = ctx.input
    local is_last_digit = input_text:match("%d%d") -- 检查最后一个字符是否为数字
    -- 动态提取输入的最后一个字符并判断是否为数字
    local last_char = is_last_digit:sub(-1) -- 获取最后一个字符
    -- 如果最后一个字符是数字且连续数字的长度等于 2
    if is_last_digit then
        local digit_count = 0
        -- 从倒数第二个字符开始检查连续的数字
        for i = #input_text, 1, -1 do
            if input_text:sub(i, i):match("%d") then
                digit_count = digit_count + 1
            else
                break
            end
        end
        -- 如果有两个连续数字，进行回退并插入新的数字
        if digit_count == 2 then
            -- 删除最后一个数字
            ctx:pop_input(2)

            -- 获取当前按下的数字并插入
            ctx:push_input(last_char)
        end
    else
        -- 不是连续数字，正常处理
        ctx:push_input(last_char)
    end
end
return tone_fallback