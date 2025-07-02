-- 欢迎使用万象拼音方案
-- @amzxyz
-- https://github.com/amzxyz/rime_wanxiang
--用来在声调辅助的时候当你输入2个数字的时候自动将声调替换为第二个数字，
--也就是说你发现输入错误声调你可以手动轮巡输入而不用回退删除直接输入下一个即可

local wanxiang = require("wanxiang")

---@return ProcessResult
local function tone_fallback(_, env)
    local ctx = env.engine.context
    local input_text = ctx.input
    -- 排除特殊模式（V/R/N/U//开头）
    if input_text:match("^[VRNU/]") then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end
    -- 查找所有连续数字段（≥2位）
    local modified = false
    local new_str = input_text:gsub("(%d)(%d+)", function(first, rest)
        modified = true
        -- 保留最后一位数字
        return rest:sub(-1)
    end)
    -- 若发生替换则更新输入
    if modified then
        ctx.input = new_str
        return wanxiang.RIME_PROCESS_RESULTS.kAccepted
    end
    return wanxiang.RIME_PROCESS_RESULTS.kNoop
end
return tone_fallback
