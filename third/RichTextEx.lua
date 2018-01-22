local htmlparser = import(".htmlparser")
local LabelTTFEx = import(".LabelTTFEx")

local RichTextEx = class("RichTextEx", function()
	return ccui.RichText:create()
end)

local string = string
local ipairs = ipairs
local tonumber = tonumber

-- wapper this with project
local defaultFont = display.DEFAULT_TTF_FONT
local defaultFontSize = 24
local defaultFontColor = cc.c3b(255, 255, 255)

-- #RRGGBB/#RGB to c3b
local function c3b_parse(s)
	local r, g, b = 0, 0, 0
	if #s == 4 then
		r = tonumber(string.rep(string.sub(s, 2, 2), 2), 16)
		g = tonumber(string.rep(string.sub(s, 3, 3), 2), 16)
		b = tonumber(string.rep(string.sub(s, 4, 4), 2), 16)
	elseif #s == 7 then
		r = tonumber(string.sub(s, 2, 3), 16)
		g = tonumber(string.sub(s, 4, 5), 16)
		b = tonumber(string.sub(s, 6, 7), 16)
	end
	return cc.c3b(r, g, b)
end

--[[用法：
local RichTextEx = require("app.utils.RichTextEx")
local clickDeal = function(id, content)
	print(id, content)
end

RichTextEx.new([==[
<t c="#f00" s="50" id="click">Hello World!</t><br><i s="0_DEMO/icon/baogao_2.png" id="iamgeaa"></i>
]==], clickDeal)
	:addTo(self)
	:center()
]]
--
-- do not support nesting
function RichTextEx:ctor(str, cfg)
	self.m_nFontSize = defaultFontSize
	if cfg and cfg.nFontSize then
		self.m_nFontSize = cfg.nFontSize
	end
	self.m_tElelementList = {}
	
	local that = self
	local __pushBackElement = self.pushBackElement
	function that:pushBackElement(e)
		table.insert(self.m_tElelementList, e)
		__pushBackElement(self, e)
	end
	
	self.m_cfg = cfg
	self:setString(str, cfg)
end

function RichTextEx:removeAllElements()
	for i, v in ipairs(self.m_tElelementList) do
		self:removeElement(v)
	end
	self.m_tElelementList = {}
end

function RichTextEx:setString(str, cfg)
	assert(str)
	
	self:removeAllElements()

	cfg = cfg or self.m_cfg or {}
	
	-- fix没有设置标签的文本
	if str:byte(1) ~= 60 or str:byte(str:len()) ~= 62 or cfg.forceTag then
		str = string.format("<l>%s</l>", str)
	end
	
	-- 行间距
	self:setVerticalSpace(cfg.verticalSpace or 0)
	
	local root = htmlparser.parse(str)
	self._callback = cfg.callback
	self:render(root.nodes)
	
	-- fix当前帧无法获取大小
	self:formatText()
end

function RichTextEx:render(nodes)
	local addTouch = function(target, id, content)
		target:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
			if event.name == "began" then
				return true
			end
			if event.name == "ended" then
				if self._callback then
					self._callback(id, content)
				end
			end
		end)
		target:setTouchEnabled(true)
	end
	
	local tag = {
		t = function(e, preChildNodeIdx) -- text
			local font = e.attributes.f or defaultFont
			local size = self.m_nFontSize
			if e.attributes.s then
				size = tonumber(e.attributes.s)
			end
			local color = defaultFontColor
			if e.attributes.c then
				color = c3b_parse(e.attributes.c)
			end
			local label = LabelTTFEx.new(e:getnodecontent(preChildNodeIdx), font, size, color)
			if e.attributes.id then
				addTouch(label, e.attributes.id, e:getnodecontent(preChildNodeIdx))
				label:enableUnderLine()
			end
			return ccui.RichElementCustomNode:create(0, display.COLOR_WHITE, 255, label)
		end,
		i = function(e) -- image
			local isSpriteFrame = 0
			local src = e.attributes.s
			if string.byte(src, 1) == 35 then -- # spriteframe
				src = string.sub(src, 2)
				isSpriteFrame = 1
			end
			local image = ccui.ImageView:create(src, isSpriteFrame)
			local size = image:getContentSize()
			if e.attributes.w then
				size.width = tonumber(e.attributes.w)
			end
			if e.attributes.h then
				size.height = tonumber(e.attributes.h)
			end
			
			local nScale = 1
			if e.attributes.p then
				nScale = tonumber(e.attributes.p) / 100
			end
			size.width = size.width * nScale
			size.height = size.height * nScale

			image:ignoreContentAdaptWithSize(false)
			image:setContentSize(size)
			if e.attributes.id then -- set underline for clicked text
				addTouch(image, e.attributes.id, src)
			end
			return ccui.RichElementCustomNode:create(0, display.COLOR_WHITE, 255, image)
		end,
		br = function(e) -- break
			return ccui.RichElementNewLine:create(0, display.COLOR_WHITE, 255)
		end,
		l = function(e, preChildNodeIdx) -- 无事件label
			local font = e.attributes.f or defaultFont
			local size = self.m_nFontSize
			if e.attributes.s then
				size = tonumber(e.attributes.s)
			end
			local color = defaultFontColor
			if e.attributes.c then
				color = c3b_parse(e.attributes.c)
			end
			local sText = e:getnodecontent(preChildNodeIdx)
			return ccui.RichElementText:create(0, color, 255, sText, font, size)
		end,
	}
	
	-- 递归所有节点
	local function renderNode(pNode)
		if tag[pNode.name] then
			local element = tag[pNode.name](pNode)
			self:pushBackElement(element)
		end
		
		for nChildNodeIdx, cNode in ipairs(pNode.nodes) do
			renderNode(cNode)
			
			if tag[pNode.name] then
				local element = tag[pNode.name](pNode, nChildNodeIdx)
				self:pushBackElement(element)
			end
		end
	end
	
	for _, e in ipairs(nodes) do
		renderNode(e)
	end
end

return RichTextEx
