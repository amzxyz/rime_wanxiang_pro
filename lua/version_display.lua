local wanxiang = require("wanxiang")

--输入'/wx'，显示万象项目地址和当前版本号
local function translator(input, seg, env)
    if input == "/wx" then
        -- 候选1: GitHub 网址
        yield(Candidate("url", seg.start, seg._end, "https://github.com/amzxyz/rime_wanxiang", ""))
        -- 判断是否为专业版
        local version_prefix = wanxiang.is_pro_scheme(env) and "增强版" or "标准版"
        -- 候选2: 当前版本号（加上“增强版”或“标准版”前缀）
        yield(Candidate("version", seg.start, seg._end, version_prefix .. " v" .. wanxiang.version, ""))
    end
end
return translator