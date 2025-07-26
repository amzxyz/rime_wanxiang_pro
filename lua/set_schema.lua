--https://github.com/amzxyz/rime_wanxiang
--@amzxyz
--一个快速初始化方案类型的工具,使用方法,方案文件放进用户目录后先部署,再执行相关指令后重新部署完成切换
local wanxiang = require("wanxiang")

-- 文件复制函数
local function copy_file(src, dest)
    local fi = io.open(src, "r")
    if not fi then 
        return false 
    end
    local content = fi:read("*a")
    fi:close()

    local fo = io.open(dest, "w")
    if not fo then 
        return false 
    end
    fo:write(content)
    fo:close()
    return true
end

-- 替换方案函数（根据文件名应用特定替换模式）
local function replace_schema(file_path, target_schema)
    local f = io.open(file_path, "r")
    if not f then 
        return false 
    end
    local content = f:read("*a")
    f:close()

    -- 根据文件名决定替换模式
    if file_path:find("wanxiang_reverse") then
        content = content:gsub("([%s]*__include:%s*wanxiang_reverse%.schema:/)[^%sa-zA-Z\r\n]+", "%1" .. target_schema)

    elseif file_path:find("wanxiang_mixedcode") then
        content = content:gsub("([%s]*__include:%s*wanxiang_mixedcode%.schema:/)[^%sa-zA-Z\r\n]+", "%1" .. target_schema)

    elseif file_path:find("wanxiang%.custom") or file_path:find("wanxiang_pro%.custom") then
        content = content:gsub("([%s%-]*wanxiang[_]pro%.schema:/)[^%sa-zA-Z\r\n]+", "%1" .. target_schema, 1)
        content = content:gsub("([%s%-]*wanxiang%.schema:/)[^%sa-zA-Z\r\n]+", "%1" .. target_schema, 1)
    end
    

    f = io.open(file_path, "w")
    if not f then 
        return false 
    end
    f:write(content)
    f:close()
    return true
end

-- translator 主函数
local function translator(input, seg, env)
    local schema_map = {
        ["/flypy"] = "小鹤双拼",
        ["/mspy"] = "微软双拼",
        ["/zrm"] = "自然码",
        ["/sogou"] = "搜狗双拼",
        ["/abc"] = "智能ABC",
        ["/ziguang"] = "紫光双拼",
        ["/pyjj"] = "拼音加加",
        ["/gbpy"] = "国标双拼",
        ["/lxsq"] = "乱序17",
        ["/pinyin"] = "全拼"
    }

    local target_schema = schema_map[input]
    if target_schema then
        local user_dir = rime_api.get_user_data_dir()

        -- 检查根目录是否存在自定义文件
        local pro_file = user_dir .. "/wanxiang_pro.custom.yaml"
        local normal_file = user_dir .. "/wanxiang.custom.yaml"
        local pro_exists = io.open(pro_file, "r")
        local normal_exists = io.open(normal_file, "r")
        local custom_file_exists = false

        if pro_exists or normal_exists then
            custom_file_exists = true
            if pro_exists then pro_exists:close() end
            if normal_exists then normal_exists:close() end
        end

        local files = {
            "wanxiang_mixedcode.custom.yaml",
            "wanxiang_reverse.custom.yaml"
        }

        -- 判断是否为专业版
        local is_pro = wanxiang.is_pro_scheme(env)
        local fourth_file = is_pro and "wanxiang_pro.custom.yaml" or "wanxiang.custom.yaml"
        table.insert(files, fourth_file)

        for _, name in ipairs(files) do
            local src = user_dir .. "/custom/" .. name
            local dest = user_dir .. "/" .. name

            if name == fourth_file and custom_file_exists then
                -- 根目录自定义文件已存在，不复制，但依然修改
                replace_schema(dest, target_schema)
            else
                -- 其他文件: 若 custom 目录存在文件，则复制到根目录并修改
                local src_file = io.open(src, "r")
                if src_file then
                    src_file:close()
                    if copy_file(src, dest) then
                        replace_schema(dest, target_schema)
                    end
                end
            end
        end

        -- 返回提示候选
        if custom_file_exists then
            yield(Candidate("switch", seg.start, seg._end, "", "检测到已有自定义文件，已为您切换到〔" .. target_schema .. "〕，请手动重新部署"))
        else
            yield(Candidate("switch", seg.start, seg._end, "", "已帮您复制并切换到〔" .. target_schema .. "〕，请手动重新部署"))
        end
    end
end
return translator
