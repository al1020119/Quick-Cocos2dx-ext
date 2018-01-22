--椭圆布局面板
--author:marvin 
--time:2018-01-12 04:27:40
--
local EllipseLayoutPanel = class("EllipseLayoutPanel", function()
	local node = display.newNode()
	-- local node = display.newColorLayer(cc.c4b(255, 0, 0, 0.4 * 255))
	return node
end)


--=======================================
--@desc:
--@author:marvin
--time:2018-01-12 04:35:30
--@oSize:
--@nA: 椭圆的A
--@nB: 椭圆的B
--return 
--=======================================
function EllipseLayoutPanel:ctor(oSize, nA, nB)
    self:setContentSize(oSize)
    self.m_nA = nA
    self.m_nB = nB

    self.m_tCellList = {}
    self.m_nCurrCellIdx = 1
    self.m_nZeroAngle = 270
    self.m_nAngle = 0
    self.m_bMoving = false
    self.m_nToAngle = 0
    self.m_nSpeed = -150
    self.m_nToCellIdx = 1

    self.m_bRenderDirty = true
    
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, handler(self, self.onEnterFrame))
    self:scheduleUpdate()
    
    
    self:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, self.onTouchEvent))
    self:setTouchEnabled(true)
end
function EllipseLayoutPanel:onTouchEvent(event)
    -- name = name,
    -- x = tp.x,
    -- y = tp.y,
    -- prevX = pp.x,
    -- prevY = pp.y,
    if event.name == "began" then
        self.m_nBeganPos = cc.p(event.x, event.y)
        return true
    elseif event.name == "ended" then
        if math.abs(event.x - self.m_nBeganPos.x) > 10 then
            if event.x < self.m_nBeganPos.x then
                self:trunLeft()
            else
                self:trunRight()
            end
        end
    end
end

--=======================================
--@desc:
--@author:marvin
--time:2018-01-12 06:32:14
--@dt:
--return 
--=======================================
function EllipseLayoutPanel:onEnterFrame(dt)
    if self.m_bMoving then
        local nCurrAngle = self.m_nAngle + dt * self.m_nSpeed
        if self.m_nSpeed >= 0 then
            if nCurrAngle >= self.m_nToAngle then
                nCurrAngle = self.m_nToAngle
                self.m_bMoving = false
            end
        else
            if nCurrAngle <= self.m_nToAngle then
                nCurrAngle = self.m_nToAngle
                self.m_bMoving = false
            end
        end
        self:alignChildrenByAngle(nCurrAngle)
        if not self.m_bMoving then
            self:onMoveDone()
        end
    end
end

--=======================================
--@desc:
--@author:marvin
--time:2018-01-12 06:38:10
--return 
--=======================================
function EllipseLayoutPanel:onMoveDone()
    if type(self.m_fnMoveDoneEvent) == "function" then
        self.m_fnMoveDoneEvent(self)
    end
end

function EllipseLayoutPanel:onMoveDoneEvent( fn )
	self.m_fnMoveDoneEvent = fn
end

function EllipseLayoutPanel:addCell(node)
    self:addChild(node)
    table.insert(self.m_tCellList, node)
    self.m_bRenderDirty = true
    self:renderUI()
end

function EllipseLayoutPanel:getCell(nIdx)
    return self.m_tCellList[nIdx]
end

function EllipseLayoutPanel:renderUI( )
    if not self.m_bRenderDirty then
        return 
    end
    self.m_bRenderDirty = true

    self:alignChildrenByAngle(0)
end

--=======================================
--@desc:
--@author:marvin
--time:2018-01-12 06:26:57
--@nToAngle:
--return 
--=======================================
function EllipseLayoutPanel:alignChildrenByAngle(nToAngle)
	-- 中心点
    local cx, cy = self:getWidth() / 2, self:getHeight() / 2
    -- 第一个元素的角度
    self.m_nAngle = nToAngle
    local nAngle = self.m_nZeroAngle + self.m_nAngle
    local nCellCount = #self.m_tCellList
    local nDetalAngle = 360 / nCellCount * -1
    local nIdx = self.m_nCurrCellIdx
    while (nIdx+1) % (nCellCount + 1) ~= self.m_nCurrCellIdx do
        local oCell = self:getCell(nIdx)
        local x = cx + self.m_nA * math.cos( math.rad(nAngle) )
        local y = cy + self.m_nB * math.sin( math.rad(nAngle) )
        oCell:setPosition(cc.p(x, y))
        oCell:setLocalZOrder(100000 - y)
        oCell.nAngle = nAngle
        nAngle = nAngle + nDetalAngle
        nIdx = nIdx + 1
    end
end

function EllipseLayoutPanel:moveToAngle(nToAngle)
    self.m_nAngle = self.m_nAngle % 360
    if self.m_nSpeed >= 0 then
        self.m_nToAngle = nToAngle % 360
        if self.m_nToAngle < self.m_nAngle then
            self.m_nToAngle = 360 + self.m_nToAngle
        end
    else
        self.m_nToAngle = nToAngle % 360
        if self.m_nAngle < self.m_nToAngle then
            self.m_nAngle = 360 + self.m_nAngle
        end
    end
    self.m_bMoving = true
end

--=======================================
--@desc:
--@author:marvin
--time:2018-01-12 07:14:09
--return 
--=======================================
function EllipseLayoutPanel:trunLeft()
    if self.m_bMoving then
        return
    end
    local nCellCount = #self.m_tCellList
    local nNextIdx = (self.m_nCurrCellIdx + 1) % (nCellCount + 1)
    if nNextIdx == self.m_nCurrCellIdx then
        return
    end
    local oNextCell = self:getCell(nNextIdx)
    self.m_nToCellIdx = nNextIdx
    self.m_nSpeed = math.abs( self.m_nSpeed ) * -1
    self:moveToAngle((oNextCell.nAngle + 360) - self.m_nZeroAngle)
end

--=======================================
--@desc:
--@author:marvin
--time:2018-01-12 07:14:09
--return 
--=======================================
function EllipseLayoutPanel:trunRight()
    if self.m_bMoving then
        return
    end
    local nCellCount = #self.m_tCellList
    local nNextIdx = (self.m_nCurrCellIdx + nCellCount - 1 ) % (nCellCount + 1)
    if nNextIdx == self.m_nCurrCellIdx then
        return
    end
    local oNextCell = self:getCell(nNextIdx)
    self.m_nToCellIdx = nNextIdx
    self.m_nSpeed = math.abs( self.m_nSpeed )
    self:moveToAngle((oNextCell.nAngle + 360) - self.m_nZeroAngle)
end

return EllipseLayoutPanel