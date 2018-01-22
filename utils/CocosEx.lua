--[[--

针对 cocos2d 的扩展

]]
local c = cc
local Node = c.Node
local Sprite = c.Sprite
local ProgressTimer = c.ProgressTimer
local Widget = ccui.Widget
local ListView = ccui.ListView
local Text = ccui.Text
local ImageView = ccui.ImageView
local Button = ccui.Button
local ScrollView = ccui.ScrollView


function Node:setWidth(w)
	local oSize = self:getContentSize()
	oSize.width = w
	self:setContentSize(oSize)
end
function Node:setHeight(h)
	local oSize = self:getContentSize()
	oSize.height = h
	self:setContentSize(oSize)
end
function Node:getWidth(w)
	local oSize = self:getContentSize()
	return oSize.width
end
function Node:getHeight(h)
	local oSize = self:getContentSize()
	return oSize.height
end

function Node:alignToCenter(px, py)
	local p = self:getParent()
	assert(p)
	local oSize = p:getContentSize()
	display.align(self, display.CENTER, px or oSize.width / 2, py or oSize.height / 2)
	return self
end
function Node:alignToLeftTop()
	local p = self:getParent()
	assert(p)
	local oSize = p:getContentSize()
	display.align(self, display.TOP_LEFT, 0, oSize.height)
	return self
end
function Node:alignToRightTop()
	local p = self:getParent()
	assert(p)
	local oSize = p:getContentSize()
	display.align(self, display.TOP_RIGHT, oSize.width, oSize.height)
	return self
end
function Node:alignToCenterLeft()
	local p = self:getParent()
	assert(p)
	local oSize = p:getContentSize()
	display.align(self, display.CENTER_LEFT, 0, oSize.height / 2)
	return self
end
function Node:alignToCenterRight()
	local p = self:getParent()
	assert(p)
	local oSize = p:getContentSize()
	display.align(self, display.CENTER_RIGHT, oSize.width + self:getWidth(), oSize.height / 2)
	return self
end
function Node:alignToCenterBottom()
	local p = self:getParent()
	assert(p)
	local oSize = p:getContentSize()
	display.align(self, display.CENTER_BOTTOM, oSize.width / 2, 0)
	return self
end
function Node:alignToRightBottom(px, py)
	local p = self:getParent()
	assert(p)
	local oSize = p:getContentSize()
	display.align(self, display.RIGHT_BOTTOM, px or oSize.width, py or 0)
	return self
end

function Node:markCurrPostion()
	local p = cc.p(self:getPositionX(), self:getPositionY())
	self.m_oPos = p
end

function Node:setPostionOffset(x, y)
	if not self.m_oPos then
		self:markCurrPostion()
	end
	self:setPosition(self.m_oPos.x + x, self.m_oPos.y + y)
end

function Node:getTopLeftBoundingBox()
	local rect = self:getBoundingBox()
	rect.y = rect.y + rect.height
	return rect
end

function Widget:getWorldRect()
	local minx, miny = self:getLeftBoundary(), self:getBottomBoundary()
	local wp = self:getParent():convertToWorldSpace(c.p(minx, miny))
	local s = self:getContentSize()
	return c.rect(wp.x, wp.y, s.width, s.height)
end


function ListView:adapterContentSize(bOnlyVisible)
	local tDir = self:getDirection()
	local nMargin = self:getItemsMargin()
	local tChilrdren = self:getItems()

	local oSize = cc.size(0, 0)
	local nCount = 0
	for i, v in ipairs(tChilrdren) do
		if not bOnlyVisible or v:isVisible() then
			if ccui.ScrollViewDir.horizontal == tDir then
				oSize.width = oSize.width + v:getContentSize().width
				oSize.height = math.max(oSize.height, v:getContentSize().height)
			elseif ccui.ScrollViewDir.vertical == tDir then
				oSize.width = math.max(oSize.width, v:getContentSize().width)
				oSize.height = oSize.height + v:getContentSize().height
			end
			nCount = nCount + 1
		end
	end
	if ccui.ScrollViewDir.horizontal == tDir then
		oSize.width = oSize.width + (nCount- 1) * nMargin 
	elseif ccui.ScrollViewDir.vertical == tDir then
		oSize.height = oSize.height + (nCount- 1) * nMargin
	end
	-- 列表里如果引用了组件，加载后默认是在下一帧才会刷新布局，这里强行手动先刷新布局
	self:doLayout()
	self:setContentSize(oSize)
end 

function ListView:adapterInnerSize(bOnlyVisible)
	local tDir = self:getDirection()
	local nMargin = self:getItemsMargin()
	local tChilrdren = self:getItems()

	local oSize = cc.size(0, 0)
	local nCount = 0
	for i, v in ipairs(tChilrdren) do
		if not bOnlyVisible or v:isVisible() then
			if ccui.ScrollViewDir.horizontal == tDir then
				oSize.width = oSize.width + v:getContentSize().width
				oSize.height = math.max(oSize.height, v:getContentSize().height)
			elseif ccui.ScrollViewDir.vertical == tDir then
				oSize.width = math.max(oSize.width, v:getContentSize().width)
				oSize.height = oSize.height + v:getContentSize().height
			end
			nCount = nCount + 1
		end
	end
	if ccui.ScrollViewDir.horizontal == tDir then
		oSize.width = oSize.width + (nCount- 1) * nMargin 
	elseif ccui.ScrollViewDir.vertical == tDir then
		oSize.height = oSize.height + (nCount- 1) * nMargin
	end
	-- 列表里如果引用了组件，加载后默认是在下一帧才会刷新布局，这里强行手动先刷新布局
	self:doLayout()
	self:setInnerContainerSize(oSize)
end 



function Text:disableUnderLine()
	if self.line then 
		self.line:removeSelf() 
		self.line = nil
	end
end

function Text:enableUnderLine()
	if self.line then 
		self.line:removeSelf() 
		self.line = nil
	end

	local oColor = self:getColor()
	local size = self:getContentSize()
	local borderWidth = size.height / 18
	local line = display.newLine(
		{{0, borderWidth / 2}, {size.width, borderWidth / 2}},
		{
			borderColor = cc.c4f(oColor.r / 255, oColor.g / 255, oColor.b / 255, 1.0),
			borderWidth = borderWidth
		}
	):addTo(self)
	self.line = line
	self.line:setCascadeColorEnabled(true)
	self.line:setCascadeOpacityEnabled(true)
	return self
end

-- function Text:enableAutoFit()
-- 	self.m_bAutoFit = true
-- end

-- function Text:setString(str)
-- 	local cfunc = tolua.getcfunction(self, "setString")
-- 	if not self.m_bAutoFit then
-- 		cfunc(self, str)
-- 		return
-- 	end

-- 	local _contentSize = self:getContentSize()
-- 	local _labelRenderer = self:getVirtualRenderer()
-- 	local oStr = _labelRenderer:getString()
-- 	if str == oStr then
-- 		return
-- 	end

-- 	_labelRenderer:setString(str)
-- 	local bIgnoreSize = self:isIgnoreContentAdaptWithSize()
-- 	_labelRenderer:setDimensions(bIgnoreSize and 0 or _contentSize.width, 0)
-- 	local textureSize = _labelRenderer:getContentSize()
-- 	printInfo(string.format( "Text:setString, %s, (%f, %f), (%f, %f)", str, _contentSize.width, _contentSize.height, textureSize.width, textureSize.height ))
-- 	if textureSize.width <= 0.0 or textureSize.height <= 0.0 then
-- 		_labelRenderer:setScale(1.0)
-- 		return
-- 	end
-- 	_labelRenderer:setContentSize(textureSize)
-- 	local scaleX = _contentSize.width / textureSize.width
-- 	local scaleY = _contentSize.height / textureSize.height
-- 	local scale = math.min(scaleX, scaleY)
-- 	_labelRenderer:setScale(scale)
-- 	g_oTimerMgr:registerTime(0.2, 1, function( ... )
-- 		_labelRenderer:setScale(scale)
-- 	end)
-- 	self.__normalScaleValue = scale
-- end

function Sprite:loadTexture(p)
	self:setTexture(p)
end
function Sprite:AsyncLoadImage(sPath, cfg)
	self:hide()
	cfg = cfg or {}
	self.__sAsyncImagePath = sPath
	local _self = self
	g_oUIHelper:AsyncLoadImage(sPath, function()
		if not _self then
			return
		end
		
		if tolua.isnull(_self) then
			return
		end
		if _self.__sAsyncImagePath ~= sPath then
			return
		end

		-- pcall(function()
			_self:show()
			_self:loadTexture(sPath)
		-- end)
	end)
end

function Sprite:setFrame(sPath)
	local oFrame = display.newSpriteFrame(sPath)
	self:setSpriteFrame(oFrame)
end

function Sprite:playAnimationOnce(animation, removeWhenFinished, onComplete, delay)
    return transition.playAnimationOnce(self, animation, removeWhenFinished, onComplete, delay)
end

function Sprite:playAnimationForever(animation, delay)
    return transition.playAnimationForever(self, animation, delay)
end

function ImageView:AsyncLoadImage(sPath, cfg)
	self:hide()
	cfg = cfg or {}
	local _self = self
	self.__sAsyncImagePath = sPath
	g_oUIHelper:AsyncLoadImage(sPath, function()
		if not _self then
			return
		end

		if tolua.isnull(_self) then
			return
		end
		if _self.__sAsyncImagePath ~= sPath then
			return
		end

		-- pcall(function()
			_self:show()
			_self:loadTexture(sPath)
		-- end)

		if cfg.bKeepGreyEffect then
			if _self.__bGreyEnable then
				g_oUIHelper:disableGreyEffect(_self)
				g_oUIHelper:enableGreyEffect(_self)
			end
		end
	end)
end

function ImageView:setFrame(sPath)
	self:loadTexture(sPath, ccui.TextureResType.plistType)
end


function ProgressTimer:progressTo(time, percent)
    self:runAction(cc.ProgressTo:create(time, percent))
    return self
end

function Button:enableShadow(...)
	local label = self:getTitleRenderer()
	label:enableShadow(...)
end
function Button:enableOutline(...)
	local label = self:getTitleRenderer()
	label:enableOutline(...)
end
function Button:enableGlow(...)
	local label = self:getTitleRenderer()
	label:enableGlow(...)
end


function ScrollView:isAtBottom(  )
	local icBottomPos = self:getInnerContainer():getBottomBoundary() 
	return icBottomPos >= 0
end
function ScrollView:isAtTop(  )
	local icTopPos = self:getInnerContainer():getTopBoundary() 
	local _topBoundary = self:getHeight()
	return icTopPos <= _topBoundary
end