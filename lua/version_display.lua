-- version_display.lua
local wanxiang = require("wanxiang")

--输入'wxpy'，显示万象项目地址和当前版本号
local function translator(input, seg, env)
    if input == "wxpy" then
        -- 候选1: GitHub 网址
        yield(Candidate("url", seg.start, seg._end, 
            "https://github.com/amzxyz/rime_wanxiang",
            "万象项目地址"))

        -- 候选2: 当前版本号
        yield(Candidate("version", seg.start, seg._end,
            "v" .. wanxiang.version,
            "当前版本号"))
    end
end

return translator