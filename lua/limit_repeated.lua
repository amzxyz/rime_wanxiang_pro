-- 用于限制最大候选数量以及重复最大输入编码,防止卡顿性能异常
--@amzxyz
--https://github.com/amzxyz
local M = {}
local ACCEPT, PASS = 1, 2

local MAX_REPEAT    = 8           -- 连续重复输入声母上限
local MAX_SEGMENTS  = 30          -- 允许的最大“分段”数
local INITIALS      = "[bpmfdtnlgkhjqxrzcsyw]"

-- 计算末尾重复
local function tail_rep(s)
  local last, n = s:sub(-1), 1
  for i = #s-1,1,-1 do
    if s:sub(i,i)==last then n=n+1 else break end
  end
  return last, n
end

-- 在候选栏最后一个 segment 加提示
local function prompt(ctx, msg)
  local comp = ctx.composition
  if comp and not comp:empty() then comp:back().prompt = msg end
end

function M.func(key, env)
  local ctx, kc = env.engine.context, key.keycode
  -- 先拿到“上一轮”高亮候选的 preedit 及段数
  local cand     = ctx:get_selected_candidate()
  local preedit  = cand and (cand.preedit or cand:get_genuine().preedit) or ""
  local segs     = 1
  for _ in preedit:gmatch("[%'%s]") do segs = segs + 1 end
  -- 本次按键字符（只关心字母 / 分隔符）
  local ch
  if     kc >= 0x61 and kc <= 0x7A then ch = string.char(kc)  -- a~z
  elseif kc == 0x27 then                ch = "'"             -- '
  elseif kc == 0x20 then                ch = " "             -- space
  end
  -- ① 连续声母限制：第 MAX_REPEAT 个同声母直接拦截
  if ch and kc >= 0x61 and kc <= 0x7A then
    local nxt         = ctx.input .. ch
    local last, rep_n = tail_rep(nxt)
    if last:match(INITIALS) and rep_n > MAX_REPEAT then
      prompt(ctx, "  〔已超最大重复声母〕")
      return ACCEPT
    end
  end
  -- ② 分段限制：第 MAX_SEGMENTS 段拦截
  local segs_after = segs
  if ch == "'" or ch == " " then segs_after = segs + 1 end
  if segs_after >= MAX_SEGMENTS and kc >= 0x61 and kc <= 0x7A then
    prompt(ctx, "  〔已超最大输入长度〕")
    return ACCEPT
  end
  return PASS
end
return M