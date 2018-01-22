--
--author:marvin 
--time:2017-11-01 07:50:14
--
local HBoxLayout = class("HBoxLayout", function( ... )
    return ccui.Layout:create()
end)

function HBoxLayout:ctor( cfg )
    -- self:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    -- self:setBackGroundColor(cc.c3b(0, 255, 0))
    self.m_nMargin = 0
    local __addChild = self.addChild
    local _self = self
    function _self:addChild(... )
        __addChild(_self, ...)
        _self:refreshView()
        return _self
    end
end

function HBoxLayout:refreshView()

    local ap = cc.p(0, 0)
    local nextPos = cc.p(0, 0)
    local padding = self.m_nMargin

    local tChildren = self:getChildren()
    for i, oChild in ipairs(tChildren) do
        oChild:setAnchorPoint(ap)
        oChild:pos(nextPos.x, nextPos.y)
        
        local s = oChild:getContentSize()
        nextPos.x = nextPos.x + s.width + padding
    end

    return self
end

function HBoxLayout:setMargin(nMargin)
    self.m_nMargin = nMargin
end

return HBoxLayout