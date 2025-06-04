-- 提供跨平台设备检测功能
-- @author amzxyz
local M = {}
-- 判断是否为手机设备（返回布尔值）
function M.is_mobile_device()
    local dist = rime_api.get_distribution_code_name() or ""
    local user_data_dir = rime_api.get_user_data_dir() or ""

    -- 转换为小写以便比较
    local lower_dist = dist:lower()
    local lower_path = user_data_dir:lower()

    -- 主判断：常见移动端输入法
    if lower_dist == "trime" or
        lower_dist == "hamster" or
        lower_dist == "squirrel" then
        return true
    end

    -- 补充判断：路径中包含移动设备特征
    if lower_path:find("/android/") or
        lower_path:find("/mobile/") or
        lower_path:find("/sdcard/") or
        lower_path:find("/data/storage/") or
        lower_path:find("/storage/emulated/") then
        return true
    end

    -- 特定平台判断（Android/Linux）
    if jit and jit.os then
        local os_name = jit.os:lower()
        if os_name:find("android") then
            return true
        end
    end

    -- 所有检查未通过则默认为桌面设备
    return false
end

return M
