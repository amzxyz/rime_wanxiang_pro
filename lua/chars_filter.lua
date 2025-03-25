local charsfilter = {}

function charsfilter.init(env)
   -- 使用 ReverseLookup 方法加载字符集
   env.charset = ReverseLookup("charset")
   env.memo = {}
end

function charsfilter.fini(env)
   env.charset = nil
   env.memo = nil
   collectgarbage()
end

function charsfilter.func(t_input, env)
   local extended = env.engine.context:get_option("charset_filter")

   if extended or env.charset == nil or charsfilter.IsReverseLookup(env) then
      for cand in t_input:iter() do
         yield(cand)
      end
   else
      for cand in t_input:iter() do
         if charsfilter.IsSingleChineseCharacter(cand.text) and charsfilter.InCharset(env, cand.text) then
            yield(cand)
         elseif not charsfilter.IsSingleChineseCharacter(cand.text) then
            -- 对于非汉字字符，直接放行
            yield(cand)
         end
      end
   end
end

-- 检查字符是否为单个汉字
function charsfilter.IsSingleChineseCharacter(text)
   return utf8.len(text) == 1 and charsfilter.IsChineseCharacter(text)
end

-- 判断字符是否为汉字
function charsfilter.IsChineseCharacter(text)
	local codepoint = utf8.codepoint(text)
	return (codepoint >= 0x4E00 and codepoint <= 0x9FFF)   -- basic
	   or (codepoint >= 0x3400 and codepoint <= 0x4DBF)    -- ext a
	   or (codepoint >= 0x20000 and codepoint <= 0x2A6DF)  -- ext b
	   or (codepoint >= 0x2A700 and codepoint <= 0x2B73F)  -- ext c
	   or (codepoint >= 0x2B740 and codepoint <= 0x2B81F)  -- ext d
	   or (codepoint >= 0x2B820 and codepoint <= 0x2CEAF)  -- ext e
	   or (codepoint >= 0x2CEB0 and codepoint <= 0x2EBE0)  -- ext f
	   or (codepoint >= 0x30000 and codepoint <= 0x3134A)  -- ext g
	   or (codepoint >= 0x31350 and codepoint <= 0x323AF)  -- ext h
	   or (codepoint >= 0x2EBF0 and codepoint <= 0x2EE5F)  -- ext i
	   or (codepoint >= 0xF900 and codepoint <= 0xFAFF)    -- CJK Compatibility
	   or (codepoint >= 0x2F800 and codepoint <= 0x2FA1F)  -- Compatibility Supplement
	   or (codepoint >= 0x2E80 and codepoint <= 0x2EFF)    -- CJK Radicals Supplement
	   or (codepoint >= 0x2F00 and codepoint <= 0x2FDF)    -- Kangxi Radicals
 end

-- 检查字符是否在字符集内
function charsfilter.InCharset(env, text)
   for i, codepoint in utf8.codes(text) do
      if not charsfilter.CodepointInCharset(env, codepoint) then
         return false
      end
   end
   return true
end

function charsfilter.CodepointInCharset(env, codepoint)
   -- 如果已经缓存过该字符的处理结果，直接返回
   if env.memo[codepoint] ~= nil then
      return env.memo[codepoint]
   end

   local char = utf8.char(codepoint)
   local res = env.charset:lookup(char) ~= ""
   env.memo[codepoint] = res
   return res
end

function charsfilter.IsReverseLookup(env)
   local seg = env.engine.context.composition:back()
   if not seg then
      return false
   end
   return seg:has_tag("radical_lookup")
      or seg:has_tag("reverse_stroke")
      or seg:has_tag("add_user_dict")
end

return charsfilter
