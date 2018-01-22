local GridView = class("GridView", function()
	local node = ccui.ScrollView:create()
	return node
end)

--=======================================
--@desc:
--@author:marvin
--time:2017-11-03 10:16:29
--@viewSize: {width, height}	展示区域大小
--@cellSize: {width, height}	格子大小
--@columnCount: int 			列数
--@marginSize:{width, height} 	行列间距
--return 
--=======================================
function GridView:ctor(viewSize, cellSize, columnCount, marginSize)
	self:setContentSize(viewSize)

	self.m_cellSize = cellSize
	self.m_columnCount = columnCount
	self.m_marginSize = marginSize
	
	local contentPanel = self
	contentPanel:setContentSize(viewSize)
	contentPanel:setInnerContainerSize(viewSize)
	contentPanel:setDirection(ccui.ScrollViewDir.vertical)
	contentPanel:setBounceEnabled(true)
	contentPanel:jumpToTop()
	self.m_contentPanel = contentPanel
	
	self.m_gridCells = {}
	-- 触摸事件
	local function self_touchEvent(sender, eventType)
		if eventType == ccui.TouchEventType.began then
			self:updateBounds()
			self.m_bDragging = true
		elseif eventType == ccui.TouchEventType.ended then
			self.m_bDragging = false
			self:updateBounds()
		elseif eventType == ccui.TouchEventType.moved then
			self:updateBounds()
		end
	end
	self:addTouchEventListener(self_touchEvent)
	self:addEventListener(handler(self, self.onEventListener))
	
	-- 惯性效果
	self:setInertiaScrollEnabled(true)
	-- self:setBounceEnabled(false)
	self.m_bDragging = false
	self.m_nTotalCount = 0		--总数
	self.m_nStartItemIdx = 1	--
	self.m_nEndItemIdx = 1		--
	self.m_nThreshold = self.m_cellSize.height * 1.1
	
	self.m_bEnableCache = true
	self.m_tCacheQueue = {}		--
	self.m_bForceCellSize = true
	self.m_bComponentMgr = true
	
	self:setNodeEventEnabled(true)
end

function GridView:setForceCellSize(bEnable)
	self.m_bForceCellSize = bEnable
end

function GridView:setComponentMgr(bEnable)
	self.m_bComponentMgr = bEnable
end

function GridView:setCacheEnable(bEnable)
	self.m_bEnableCache = bEnable
end

function GridView:pushCache(node)
	self.m_tCacheQueue[#self.m_tCacheQueue + 1] = node
end

function GridView:popCache()
	if #self.m_tCacheQueue <= 0 then
		return nil
	end
	local node = table.remove(self.m_tCacheQueue, #self.m_tCacheQueue)
	return node
end

function GridView:clearCache()
	for _i, v in ipairs(self.m_tCacheQueue) do
		if self.m_bComponentMgr then
			g_oComponentMgr:RemoveComponent(v)
		end
		v:release()
	end
	self.m_tCacheQueue = {}
end

function GridView:onEventListener(obj, eventType)
	if ccui.ScrollviewEventType.scrolling == eventType then
		self:updateBounds()
	elseif ccui.ScrollviewEventType.scrollToTop == eventType then
		if not self:updateBounds() then
			self:postScrollToTopEvent()
		end
	elseif ccui.ScrollviewEventType.bounceTop == eventType then
		self:updateBounds()
	elseif ccui.ScrollviewEventType.scrollToBottom == eventType then
		if not self:updateBounds() then
			self:postScrollToBottomEvent()
		end
	elseif ccui.ScrollviewEventType.bounceBottom == eventType then
		self:updateBounds()
	end
end

function GridView:onExit()
	self:clearCache()
end

function GridView:getSelectingGridCell(touchPos)
	local worldPosition = touchPos
	for i, gridCell in ipairs(self.m_gridCells) do
		if gridCell:hitTest(worldPosition) then
			return gridCell
		end
	end
	return nil
end

function GridView:getStartItemIndex(  )
	return self.m_nStartItemIdx
end
function GridView:getEndItemIndex(  )
	return self.m_nEndItemIdx
end
function GridView:getTotalCount(  )
	return self.m_nTotalCount
end

function GridView:getGridCells()
	return self.m_gridCells
end

function GridView:addGridCell(gridCell, index, bIgnoreRender)
	table.insert(self.m_gridCells, index or(#self.m_gridCells + 1), gridCell)
	gridCell:setAnchorPoint(cc.p(0.5, 0.5))
	if self.m_bForceCellSize then
		gridCell:setContentSize(self.m_cellSize)
	end
	self.m_contentPanel:addChild(gridCell)
	self.m_gridCellDirty = true
	if not bIgnoreRender then
		self:renderUI()
	end
end

function GridView:removeGridCell(gridCell, bIgnoreRender)
	local result = false
	for k, v in ipairs(self.m_gridCells) do
		if v == gridCell then
			table.remove(self.m_gridCells, k)
			if self.m_bEnableCache then
				self.m_contentPanel:removeChild(gridCell)
			else
				if self.m_bComponentMgr then
					g_oComponentMgr:RemoveComponent(gridCell)
				else
					self.m_contentPanel:removeChild(gridCell)
				end
			end
			result = true
			break
		end
	end
	if result then
		self.m_gridCellDirty = true
		if not bIgnoreRender then
			self:renderUI()
		end
	end
	return result
end

function GridView:removeAllGridCells()
	self:removeAllNode()
	self.m_gridCellDirty = true
	self:renderUI()
end

--组件的创建和销毁统一组件的管理器去处理
function GridView:removeAllNode()
	for k, v in pairs(self.m_gridCells) do
		if self.m_bComponentMgr then
			g_oComponentMgr:RemoveComponent(v)
		else
			v:removeSelf()
		end
	end
	self.m_gridCells = {}
end

--界面关闭后把new出来的东西销毁
function GridView:destroy()
	self:clearCache()
	
	self:removeAllNode()
	self:removeSelf()
end

function GridView:renderUI()
	if not self.m_gridCellDirty then
		return
	end
	self.m_gridCellDirty = false
	
	local gridCellCount = #self.m_gridCells
	local rowCount = math.ceil(gridCellCount / self.m_columnCount)
	local newContentPanelSize = cc.size(0, 0)
	local nRowWidthMax = 0
	local nRowHeightMax = 0
	local tRowHeight = {}
	local rowIndex = 0
	for i, gridCell in ipairs(self.m_gridCells) do
		if(i - 1) % self.m_columnCount == 0 then
			if i > 1 then
				tRowHeight[rowIndex] = nRowHeightMax
			end
			newContentPanelSize.height = newContentPanelSize.height + nRowHeightMax
			nRowHeightMax = 0
			rowIndex = rowIndex + 1
		end
		nRowHeightMax = math.max(nRowHeightMax, self:getCellSize(gridCell))
		
		if i == #self.m_gridCells then
			newContentPanelSize.height = newContentPanelSize.height + nRowHeightMax
			tRowHeight[rowIndex] = nRowHeightMax
		end
	end
	newContentPanelSize.height = newContentPanelSize.height +((rowCount - 1) * self.m_marginSize.height)
	newContentPanelSize.width = self.m_columnCount * self.m_cellSize.width +(self.m_columnCount - 1) * self.m_marginSize.width
	
	newContentPanelSize.width = math.max(newContentPanelSize.width, self:getContentSize().width)
	newContentPanelSize.height = math.max(newContentPanelSize.height, self:getContentSize().height)
	self:getInnerContainer():setContentSize(newContentPanelSize)
	
	local nNextHeight = newContentPanelSize.height
	for i, gridCell in ipairs(self.m_gridCells) do
		local rowIndex = math.floor((i - 1) / self.m_columnCount)
		local colIndex = i % self.m_columnCount
		if colIndex == 0 then
			colIndex = self.m_columnCount
		end
		
		local nCellHeight = self:getCellSize(gridCell)
		gridCell:setPosition(cc.p((colIndex - 1) * self.m_cellSize.width +(colIndex - 1) * self.m_marginSize.width + self.m_cellSize.width / 2,
		nNextHeight - nCellHeight / 2))
		
		if colIndex == self.m_columnCount then
			nNextHeight = nNextHeight - tRowHeight[rowIndex + 1] - self.m_marginSize.height
		end
	end
end


--=======================================
--@desc:设置列表数据源
--@author:marvin
--time:2017-11-17 04:32:59
--@oDataSource:必须实现3个接口getDataCount, getData, createGridCell
--return 
--=======================================
function GridView:setDataSource(oDataSource)
	self.m_oDataSource = oDataSource
	assert(self.m_oDataSource)
	assert(type(self.m_oDataSource.getDataCount) == "function")
	assert(type(self.m_oDataSource.getData) == "function")
	assert(type(self.m_oDataSource.createGridCell) == "function")
end

function GridView:clearCells(bIgnoreRender)
	while #self.m_gridCells > 0 do
		local oCellCom = self.m_gridCells[#self.m_gridCells]
		self:returnItem(oCellCom)
	end
	self.m_nStartItemIdx = 1
	self.m_nEndItemIdx = 1
	if not bIgnoreRender then
		self:renderUI()
	end
end

function GridView:refreshCells(bJumpToTop)
	assert(self.m_oDataSource)

	if bJumpToTop == nil then
		bJumpToTop = true
	end

	-- 刷新总数
	self.m_nTotalCount = self.m_oDataSource:getDataCount()
	
	self.m_nStartItemIdx = math.min(self.m_nStartItemIdx, self.m_nTotalCount)
	if self.m_nStartItemIdx <= 0 then
		self.m_nStartItemIdx = 1
	end
	self.m_nEndItemIdx = self.m_nStartItemIdx
	
	local viewWorldRect = self:getWorldRect()
	local sizeToFill = viewWorldRect.height
	local sizeFilled = 0
	
	local i = 1
	local size = 0
	while i <= #self.m_gridCells do
		local count = self.m_columnCount
		if #self.m_gridCells - i + 1 >= count and self.m_nEndItemIdx <= self.m_nTotalCount then
			for j = 1, count do
				if self.m_nEndItemIdx <= self.m_nTotalCount then
					local oCellCom = self.m_gridCells[i]
					self:updateItemData(oCellCom, self.m_nEndItemIdx)
					self.m_nEndItemIdx = self.m_nEndItemIdx + 1
					i = i + 1
					size = math.max(self:getCellSize(oCellCom), size)
					if self.m_nEndItemIdx > self.m_nTotalCount then
						break
					end
				end
			end
			sizeFilled = sizeFilled + size
			size = 0
		else
			local oCellCom = self.m_gridCells[i]
			self:returnItem(oCellCom)
		end
	end
	
	while sizeToFill > sizeFilled do
		local size = self:newItemAtEnd()
		if size <= 0 then
			break
		end
		sizeFilled = sizeFilled + size
	end
	
	self:renderUI()
	if bJumpToTop then
		self:jumpToTop()
	end
end

function GridView:refillCells(offset)
	offset = offset or 1
	assert(offset > 0)
	
	assert(self.m_oDataSource)
	-- 刷新总数
	self.m_nTotalCount = self.m_oDataSource:getDataCount()
	
	self:clearCells(true)
	
	local viewWorldRect = self:getWorldRect()
	local sizeToFill = viewWorldRect.height
	local sizeFilled = 0
	while sizeToFill > sizeFilled do
		local size = self:newItemAtEnd()
		if size <= 0 then
			break
		end
		sizeFilled = sizeFilled + size
	end
	
	self:renderUI()
	self:jumpToTop()
end

function GridView:refillCellsFromEnd(offset)
	offset = offset or 1
	assert(offset > 0)
	
	assert(self.m_oDataSource)
	-- 刷新总数
	self.m_nTotalCount = self.m_oDataSource:getDataCount()
	
	self:clearCells(true)
	
	self.m_nEndItemIdx = self.m_nTotalCount - offset + 1 + 1
	self.m_nStartItemIdx =	self.m_nEndItemIdx
	
	local viewWorldRect = self:getWorldRect()
	local sizeToFill = viewWorldRect.height
	local sizeFilled = 0
	while sizeToFill > sizeFilled do
		local size = self:newItemAtStart()
		if size <= 0 then
			break
		end
		sizeFilled = sizeFilled + size
	end
	
	self:renderUI()
	self:jumpToBottom()
end

function GridView:moveChildren(offsetX, offsetY)
	local toX, toY = self:getInnerContainer():getPositionX() + offsetX, self:getInnerContainer():getPositionY() + offsetY
	self:getInnerContainer():pos(toX, toY)
end

function GridView:updateBounds()
	local viewWorldRect = self:getWorldRect()
	local contentWorldRect = self:getInnerContainer():getWorldRect()
	local x, y = self:getInnerContainer():getPosition()
	
	local bUpdateItems = self:updateItems(viewWorldRect, contentWorldRect)
	self:renderUI()
	return bUpdateItems
end

function GridView:updateItems(viewWorldRect, contentWorldRect)
	local bChanged = false
	
	if viewWorldRect.y < contentWorldRect.y then
		local size = self:newItemAtEnd()
		local nTotalSize = size
		while size > 0 and viewWorldRect.y < contentWorldRect.y - nTotalSize do
			size = self:newItemAtEnd()
			nTotalSize = nTotalSize + size
		end
		bChanged = nTotalSize > 0
		if bChanged then
			self:moveChildren(0, - 1 * nTotalSize)
		end
	elseif viewWorldRect.y > contentWorldRect.y + self.m_nThreshold then
		local size = self:deleteItemAtEnd()
		local nTotalSize = size
		while size > 0 and viewWorldRect.y > contentWorldRect.y + self.m_nThreshold + nTotalSize do
			size = self:deleteItemAtEnd()
			nTotalSize = nTotalSize + size
		end
		bChanged = nTotalSize > 0
		if bChanged then
			self:moveChildren(0, nTotalSize)
		end
	end
	
	if viewWorldRect.y + viewWorldRect.height > contentWorldRect.y + contentWorldRect.height then
		local size = self:newItemAtStart()
		local nTotalSize = size
		while size > 0 and viewWorldRect.y + viewWorldRect.height > contentWorldRect.y + contentWorldRect.height + nTotalSize do
			size = self:newItemAtStart()
			nTotalSize = nTotalSize + size
		end
		bChanged = nTotalSize > 0
	elseif viewWorldRect.y + viewWorldRect.height < contentWorldRect.y + contentWorldRect.height - self.m_nThreshold then
		local size = self:deleteItemAtStart()
		local nTotalSize = size
		while size > 0 and viewWorldRect.y + viewWorldRect.height < contentWorldRect.y + contentWorldRect.height - self.m_nThreshold - nTotalSize do
			size = self:deleteItemAtStart()
			nTotalSize = nTotalSize + size
		end
		bChanged = nTotalSize > 0
	end
	
	return bChanged
end

function GridView:newItemAtStart()
	if self.m_nTotalCount <= 0 then
		return 0
	end
	if self.m_nTotalCount > 0 and self.m_nStartItemIdx - self.m_columnCount <= 0 then
		return 0
	end	
	local size = 0
	for i = 1, self.m_columnCount do
		self.m_nStartItemIdx = self.m_nStartItemIdx - 1
		local oCellCom = self:createNextItem(self.m_nStartItemIdx, 1)
		
		size = math.max(size, self:getCellSize(oCellCom))
	end
	
	if size > 0 and self.m_nThreshold < size then
		self.m_nThreshold = size * 1.1
	end
	
	return size + self.m_marginSize.height
end

function GridView:deleteItemAtStart()
	if #self.m_gridCells <= 0 or self.m_nEndItemIdx >= self.m_nTotalCount then
		return 0
	end
	
	local size = 0
	for i = 1, self.m_columnCount do
		local oCellCom = self.m_gridCells[1]
		size = math.max(size, self:getCellSize(oCellCom))
		self:returnItem(oCellCom)
		
		self.m_nStartItemIdx = self.m_nStartItemIdx + 1
		if #self.m_gridCells <= 0 then
			break
		end
	end	
	return size + self.m_marginSize.height
end

function GridView:newItemAtEnd()
	if self.m_nEndItemIdx > self.m_nTotalCount then
		return 0
	end
	
	local size = 0
	local count = self.m_columnCount -(#self.m_gridCells % self.m_columnCount)
	for i = 1, count do
		local oCellCom = self:createNextItem(self.m_nEndItemIdx, #self.m_gridCells + 1)
		size = math.max(self:getCellSize(oCellCom), size)
		
		self.m_nEndItemIdx = self.m_nEndItemIdx + 1
		if self.m_nEndItemIdx > self.m_nTotalCount then
			break
		end
	end
	
	if size > 0 and size > self.m_nThreshold then
		self.m_nThreshold = size * 1.1
	end
	
	return size + self.m_marginSize.height
end

function GridView:deleteItemAtEnd()
	if self.m_nStartItemIdx <= self.m_columnCount or #self.m_gridCells <= 0 then
		return 0
	end
	
	local size = 0
	for i = 1, self.m_columnCount do
		local oCellCom = self.m_gridCells[#self.m_gridCells]	
		size = math.max(size, self:getCellSize(oCellCom))
		self:returnItem(oCellCom)
		
		self.m_nEndItemIdx = self.m_nEndItemIdx - 1
		if(self.m_nEndItemIdx - 1) % self.m_columnCount == 0 or #self.m_gridCells == 0 then
			break
		end
	end
	
	return size + self.m_marginSize.height
end

function GridView:createNextItem(nItemIdx, gridIndex)
	local oCellCom = nil
	if self.m_bEnableCache then
		oCellCom = self:popCache()
		if oCellCom then
			self:addGridCell(oCellCom, gridIndex, true)
			oCellCom:release()
			self:updateItemData(oCellCom, nItemIdx)
			return oCellCom
		end
	end
	
	oCellCom = self.m_oDataSource:createGridCell(nItemIdx)
	self:addGridCell(oCellCom, gridIndex, true)
	return oCellCom
end
function GridView:returnItem(oCellCom)
	if type(oCellCom.onCellReturn) == "function" then
		oCellCom:onCellReturn()
	end
	if self.m_bEnableCache then
		oCellCom:retain()
		self:pushCache(oCellCom)
	end
	self:removeGridCell(oCellCom, true)
end
function GridView:updateItemData(oCellCom, nItemIdx)
	if type(oCellCom.onCellData) == "function" then
		oCellCom:onCellData(self.m_oDataSource:getData(nItemIdx), nItemIdx)
	end
	if type(oCellCom.onCellIndex) == "function" then
		oCellCom:onCellIndex(nItemIdx)
	end
end

function GridView:getCellSize(oCellCom)
	-- return self.m_cellSize.height
	return oCellCom and oCellCom:getHeight() or 0
end


--=======================================
--@desc:
--@author:marvin
--time:2017-12-14 09:35:42
--return 
--=======================================
function GridView:postScrollToTopEvent()
	if type(self.m_fOnScrollToTopHandler) == "function" then
		self.m_fOnScrollToTopHandler(self)
	end
end

--=======================================
--@desc:
--@author:marvin
--time:2017-12-14 09:35:38
--return 
--=======================================
function GridView:postScrollToBottomEvent()
	if type(self.m_fOnScrollToBottomHandler) == "function" then
		self.m_fOnScrollToBottomHandler(self)
	end
end

--=======================================
--@desc:
--@author:marvin
--time:2017-12-14 09:38:50
--@fHandler:
--return 
--=======================================
function GridView:onScrollToTopEvent(fHandler)
	self.m_fOnScrollToTopHandler = fHandler
end

--=======================================
--@desc:
--@author:marvin
--time:2017-12-14 09:38:38
--@fHandler:
--return 
--=======================================
function GridView:onScrollToBottomEvent(fHandler)
	self.m_fOnScrollToBottomHandler = fHandler
end

return GridView 