UDKP_data = {}

ScrollingTable = {}
local b_frame

do
	local defaultcolor = { ["r"] = 1.0, ["g"] = 1.0, ["b"] = 1.0, ["a"] = 1.0 };
	local defaulthighlight = { ["r"] = 1.0, ["g"] = 0.9, ["b"] = 0.0, ["a"] = 0.5 };
	local defaulthighlightblank = { ["r"] = 0.0, ["g"] = 0.0, ["b"] = 0.0, ["a"] = 0.0 };
	local lrpadding = 2.5;
	
	local ScrollPaneBackdrop  = {
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 3, right = 3, top = 5, bottom = 3 }
	};
	
	local framecount = 1; 
	
	local SetHeight = function(self)
		self.b_frame:SetHeight( (self.displayRows * self.rowHeight) + 10);
		self:Refresh();
	end
	
	local SetWidth = function(self)
		local width = 13;
		for num, col in pairs(self.cols) do
			width = width + col.width;
		end
		self.b_frame:SetWidth(width+20);
		self:Refresh();
	end
	
	local SetHighLightColor = function(b_frame, color)
		if not b_frame.highlight then 
			b_frame.highlight = b_frame:CreateTexture(nil, "OVERLAY");
			b_frame.highlight:SetAllPoints(b_frame);
		end
		b_frame.highlight:SetTexture(color.r, color.g, color.b, color.a);
	end
	
	local SetBackgroundColor = function(b_frame, color)
		if not b_frame.background then 
			b_frame.background = b_frame:CreateTexture(nil, "BACKGROUND");
			b_frame.background:SetAllPoints(b_frame);
		end
		b_frame.background:SetTexture(color.r, color.g, color.b, color.a);
	end
	
	local FireUserEvent = function (self, b_frame, event, handler, ...)
		if not handler( ...) then
			if self.DefaultEvents[event] then 
				self.DefaultEvents[event]( ...);
			end
		end
	end
	
	local RegisterEvents = function(self, events, fRemoveOldEvents)
			local table = self; -- save for closure later

			for i, row in ipairs(self.rows) do
				for j, col in ipairs(row.cols) do
					-- unregister old events.
					if fRemoveOldEvents and self.events then
						for event, handler in pairs(self.events) do
							col:SetScript(event, nil);
						end
					end

					-- register new ones.
					for event, handler in pairs(events) do
						col:SetScript(event, function(cellFrame, ...)
							local realindex = table.filtered[i+(table.offset or 0)];
							handler(row, cellFrame, table.data, table.cols, i, realindex, j, ...);
						end);
					end
				end
			end
			self.events = events;
		end
	
		local SetDisplayRows = function(self, num, rowHeight)
			-- should always set columns first
			self.displayRows = num;
			self.rowHeight = rowHeight;
			if not self.rows then
				self.rows = {};
			end
			for i = 1, num do
				local row = self.rows[i];
				if not row then
					row = CreateFrame("Button", self.b_frame:GetName().."Row"..i, self.b_frame);
					row.SetHighLightColor = SetHighLightColor;

					self.rows[i] = row;
					if i > 1 then
						row:SetPoint("TOPLEFT", self.rows[i-1], "BOTTOMLEFT", 0, 0);
						row:SetPoint("TOPRIGHT", self.rows[i-1], "BOTTOMRIGHT", 0, 0);
					else
						row:SetPoint("TOPLEFT", self.b_frame, "TOPLEFT", 4, -5);
						row:SetPoint("TOPRIGHT", self.b_frame, "TOPRIGHT", -4, -5);
					end
					row:SetHeight(rowHeight);
				end

				if not row.cols then
					row.cols = {};
				end
				for j = 1, #self.cols do
					local col = row.cols[j];
					if not col then
						col = CreateFrame("Button", row:GetName().."col"..j, row);
						col.text = row:CreateFontString(col:GetName().."text", "OVERLAY", "GameFontHighlightSmall");
						row.cols[j] = col;
						local align = self.cols[j].align or "LEFT";
						col.text:SetJustifyH(align);

						if self.events then
							for event, handler in pairs(self.events) do
								col:SetScript(event, function(cellFrame, ...)
									local realindex = self.filtered[i+(table.offset or 0)];
									handler(row, cellFrame, self.data, self.cols, i, realindex, j, ...);
								end);
							end
						end

						col:EnableMouse(true);
						col:RegisterForClicks("AnyUp");
--						col:RegisterForDrag("LeftButton");
					end

					if j > 1 then
						col:SetPoint("LEFT", row.cols[j-1], "RIGHT", 0, 0);
					else
						col:SetPoint("LEFT", row, "LEFT", 2, 0);
					end
					col:SetHeight(rowHeight);
					col:SetWidth(self.cols[j].width);
					col.text:SetPoint("TOP", col, "TOP", 0, 0);
					col.text:SetPoint("BOTTOM", col, "BOTTOM", 0, 0);
					col.text:SetWidth(self.cols[j].width - 2*lrpadding);
				end
				j = #self.cols + 1;
				col = row.cols[j];
				while col do
					col:Hide();
					j = j + 1;
					col = row.cols[j];
				end
			end

			for i=num+1,#self.rows do
				self.rows[i]:Hide()
			end

			self:SetHeight();
		end

		local SetDisplayCols = function(self, cols)
			local table = self; -- reference saved for closure
			self.cols = cols;

			local rowFrameName = self.b_frame:GetName().."Head";
			local row = getglobal(rowFrameName);
			if not row then
				row = CreateFrame("Frame", rowFrameName, self.b_frame);
				row:SetPoint("BOTTOMLEFT", self.b_frame, "TOPLEFT", 4, 0);
				row:SetPoint("BOTTOMRIGHT", self.b_frame, "TOPRIGHT", -4, 0);
				row:SetHeight(self.rowHeight);
				row.cols = {};
			end
			for i = 1, #cols do
				local colFrameName =  row:GetName().."Col"..i;
				local col = row.cols[i]

				if not col then
					col = CreateFrame("Button", colFrameName, row);
					col:SetScript("OnClick", function (self, button)
						if button == "LeftButton" then
							for j = 1, #table.cols do
								if j ~= i then -- clear out all other sort marks
									table.cols[j].sort = nil;
								end
							end
							local sortorder = "asc";
							if not table.cols[i].sort and table.cols[i].defaultsort then
								sortorder = table.cols[i].defaultsort; -- sort by columns default sort first;
							elseif table.cols[i].sort and table.cols[i].sort:lower() == "asc" then
								sortorder = "dsc";
							end
							table.cols[i].sort = sortorder;
							table:SortData();
						else
							if table.cols[i].rightclick then
								table.cols[i].rightclick();
							end
						end
					end);


					col:SetScript("OnEnter", function (thisFrame)
						--UDKP_frame.keyCapture:EnableKeyboard(true)
						if table.cols[i].tooltipText then
							GameTooltip:SetOwner(thisFrame, "ANCHOR_TOPLEFT")

							GameTooltip:ClearLines()

							GameTooltip:AddLine(table.cols[i].name,1,1,1)
							GameTooltip:AddLine(table.cols[i].tooltipText,.7,.7,.7)

							GameTooltip:Show()
						end
					end);

					col:SetScript("OnLeave", function (thisFrame)
						--UDKP_frame.keyCapture:EnableKeyboard(false)
						GameTooltip:Hide()
					end);

					col:RegisterForClicks("AnyUp");
					row.cols[i] = col;
				end


				local fs = col:GetFontString() or col:CreateFontString(col:GetName().."fs", "OVERLAY", "GameFontHighlightSmall");
				fs:SetAllPoints(col);
				fs:SetPoint("LEFT", col, "LEFT", lrpadding, 0);
				fs:SetPoint("RIGHT", col, "RIGHT", -lrpadding, 0);
				local align = cols[i].align or "LEFT";
				fs:SetJustifyH(align);

				col:SetFontString(fs);
				fs:SetText(cols[i].name);
				fs:SetTextColor(1.0, 1.0, 1.0, 1.0);
				col:SetPushedTextOffset(0,0);

				if i > 1 then
					col:SetPoint("LEFT", row.cols[i-1], "RIGHT", 0, 0);
				else
					col:SetPoint("LEFT", row, "LEFT", 2, 0);
				end
				col:SetHeight(self.rowHeight);
				col:SetWidth(cols[i].width);

				local color = cols[i].bgcolor;
				if (color) then
					local colibg = "col"..i.."bg";
					local bg = self.b_frame[colibg];
					if not bg then
						bg = self.b_frame:CreateTexture(nil, "OVERLAY");
						self.b_frame[colibg] = bg;
					end
					bg:SetPoint("BOTTOM", self.b_frame, "BOTTOM", 0, 4);
					bg:SetPoint("TOPLEFT", col, "BOTTOMLEFT", 0, -4);
					bg:SetPoint("TOPRIGHT", col, "BOTTOMRIGHT", 0, -4);
					bg:SetTexture(color.r, color.g, color.b, color.a);
				end
			end

			self:SetWidth();
		end
	
	local Show = function(self)
		self.b_frame:Show();
		self.scrollframe:Show();
		self.showing = true;
	end
	local Hide = function(self)
		self.b_frame:Hide();
		self.showing = false;
	end
	
	local SetData = function(self, data)
		self.data = data;
		self:SortData();
	end
		
	local SortData = function(self)
		-- sanity check
		if not(self.sorttable) or (#self.sorttable > #self.data)then 
			self.sorttable = {};
		end
		if #self.sorttable ~= #self.data then
			for i = 1, #self.data do 
				self.sorttable[i] = i;
			end
		end 
		
		-- go on sorting
		local i, sortby = 1, nil;
		while i <= #self.cols and not sortby do
			if self.cols[i].sort then 
				sortby = i;
			end
			i = i + 1;
		end
		if sortby then 
			table.sort(self.sorttable, function(rowa, rowb)
				local column = self.cols[sortby];
				if column.comparesort then 
					return column.comparesort(self, rowa, rowb, sortby);
				else
					return self:CompareSort(rowa, rowb, sortby);
				end
			end);
		end
		self.filtered = self:DoFilter();
		self:Refresh();
	end
	
	local StringToNumber = function(str)
		if str == "" then 
			return 0;
		else
			return tonumber(str)
		end
	end
	
	local CompareSort = function (self, rowa, rowb, sortbycol)
		local cella, cellb = self.data[rowa].cols[sortbycol], self.data[rowb].cols[sortbycol];
		local a1, b1 = cella.value, cellb.value;
		local column = self.cols[sortbycol];
		if type(a1) == "function" then 
			a1 = a1(unpack(cella.args or {}));
		end
		if type(b1) == "function" then 
			b1 = b1(unpack(cellb.args or {}));
		end
		
		if type(a1) ~= type(b1) then
			local typea, typeb = type(a1), type(b1);
			if typea == "number" and typeb == "string" then 
				if tonumber(typeb) then -- is it a number in a string?
					b1 = StringToNumber(b1); -- "" = 0
				else
					a1 = tostring(a1);
				end
			elseif typea == "string" and typeb == "number" then 
				if tonumber(typea) then -- is it a number in a string?
					a1 = StringToNumber(a1); -- "" = 0
				else
					b1 = tostring(b1);
				end
			end
		end
		
		if a1 == b1 and column.sortnext and (not(self.cols[column.sortnext].sort)) then 
			local nextcol = self.cols[column.sortnext];
			if nextcol.comparesort then 
				return nextcol.comparesort(self, rowa, rowb, column.sortnext);
			else
				return self:CompareSort(rowa, rowb, column.sortnext);
			end
		else
			local direction = column.sort or column.defaultsort or "asc";
			if direction:lower() == "asc" then 		
				return a1 > b1;
			else
				return a1 < b1;
			end
		end
	end
	
	local Filter = function(self, ...)
		return true;
	end
	
	local SetFilter = function(self, Filter)
		self.Filter = Filter;
		self:SortData();
	end
	
	local DoFilter = function(self)
		local result = {};
		for row = 1, #self.data do 
			if self:Filter(self.data[self.sorttable[row]]) then
				table.insert(result, self.sorttable[row]);
			end
		end
		return result;
	end
	
	local DoCellUpdate = function(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, ...)
		if fShow then
			local cellData = data[realrow].cols[column];
			
			if type(cellData.value) == "function" then 
				cellFrame.text:SetText(cellData.value(unpack(cellData.args or {})) );
			else
				cellFrame.text:SetText(cellData.value);
			end
			
			local color = cellData.color;
			local colorargs = nil;
			if not color then 
			 	color = cols[column].color;
			 	if not color then 
			 		color = data[realrow].color;
			 		if not color then 
			 			color = defaultcolor;
			 		else
			 			colorargs = data[realrow].colorargs;
			 		end
			 	else
			 		colorargs = cols[column].colorargs;
			 	end
			else
				colorargs = cellData.colorargs;
			end	
			if type(color) == "function" then 
				color = color(unpack(colorargs or {cellFrame}));
			end
			cellFrame.text:SetTextColor(color.r, color.g, color.b, color.a);
		else	
			cellFrame.text:SetText("");
		end
	end
	
	function ScrollingTable:CreateST(cols, numRows, rowHeight, highlight, parent)
		local ast = {};
		local f = CreateFrame("Frame", "ScrollTab"..framecount, parent or UIParent);
		framecount = framecount + 1;
		ast.showing = true;
		ast.b_frame = f;
		
		ast.Show = Show;
		ast.Hide = Hide;
		ast.SetDisplayRows = SetDisplayRows;
		ast.SetRowHeight = SetRowHeight;
		ast.SetHeight = SetHeight;
		ast.SetWidth = SetWidth;
		ast.SetDisplayCols = SetDisplayCols;
		ast.SetData = SetData;
		ast.SortData = SortData;
		ast.CompareSort = CompareSort;
		ast.RegisterEvents = RegisterEvents;
		ast.FireUserEvent = FireUserEvent;
		
		ast.SetFilter = SetFilter;
		ast.DoFilter = DoFilter;
		
		ast.highlight = highlight or defaulthighlight;
		ast.displayRows = numRows or 12;
		ast.rowHeight = rowHeight or 15;
		ast.cols = cols or {
			{
				["name"] = "Test 1",
			 	["width"] = 50,
			 	["color"] = { ["r"] = 0.5, ["g"] = 0.5, ["b"] = 1.0, ["a"] = 1.0 },
			}, -- [1]
			{ 
				["name"] = "Test 2", 
				["width"] = 50, 
				["align"] = "CENTER",
				["bgcolor"] = { ["r"] = 1.0, ["g"] = 0.0, ["b"] = 0.0, ["a"] = 0.2 },
			}, -- [2]
			{ 
				["name"] = "Test 3", 
				["width"] = 50, 
				["align"] = "RIGHT",
				["bgcolor"] = { ["r"] = 0.0, ["g"] = 0.0, ["b"] = 0.0, ["a"] = 0.5 },
			}, -- [3]
		};
		ast.DefaultEvents = {
			["OnEnter"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, ...)
				if row and realrow then 
					SetHighLightColor(rowFrame, ast.highlight);
				end
				return true;
			end, 
			["OnLeave"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, ...)
				if row and realrow then 
					SetHighLightColor(rowFrame, defaulthighlightblank);
				end
				return true;
			end,
			["OnClick"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, ...)
				if not (row or realrow) then
					for i, col in ipairs(ast.cols) do 
						if i ~= column then -- clear out all other sort marks
							cols[i].sort = nil;
						end
					end
					local sortorder = "asc";
					if not cols[column].sort and cols[column].defaultsort then
						sortorder = cols[column].defaultsort; -- sort by columns default sort first;
					elseif cols[column].sort and cols[column].sort:lower() == "asc" then 
						sortorder = "dsc";
					end
					cols[column].sort = sortorder;
					ast:SortData();
				end
				return true;
			end,
		};
		ast.data = {};
	
		f:SetBackdrop(ScrollPaneBackdrop);
		f:SetBackdropColor(0.1,0.1,0.1);
		f:SetPoint("CENTER",UIParent,"CENTER",0,0);
		
		-- build scroll frame		
		local scrollframe = CreateFrame("ScrollFrame", f:GetName().."ScrollFrame", f, "FauxScrollFrameTemplate");
		ast.scrollframe = scrollframe;
		scrollframe:Show();
		scrollframe:SetScript("OnHide", function(self, ...)
			self:Show();
		end);
		
		scrollframe:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -4);
		scrollframe:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -26, 3);
		
		local scrolltrough = CreateFrame("Frame", f:GetName().."ScrollTrough", scrollframe);
		scrolltrough:SetWidth(17);
		scrolltrough:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -3);
		scrolltrough:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 4);
		scrolltrough.background = scrolltrough:CreateTexture(nil, "BACKGROUND");
		scrolltrough.background:SetAllPoints(scrolltrough);
		scrolltrough.background:SetTexture(0.05, 0.05, 0.05, 1.0);
		local scrolltroughborder = CreateFrame("Frame", f:GetName().."ScrollTroughBorder", scrollframe);
		scrolltroughborder:SetWidth(1);
		scrolltroughborder:SetPoint("TOPRIGHT", scrolltrough, "TOPLEFT");
		scrolltroughborder:SetPoint("BOTTOMRIGHT", scrolltrough, "BOTTOMLEFT");
		scrolltroughborder.background = scrolltrough:CreateTexture(nil, "BACKGROUND");
		scrolltroughborder.background:SetAllPoints(scrolltroughborder);
		scrolltroughborder.background:SetTexture(0.5, 0.5, 0.5, 1.0);
		
		ast.Refresh = function(self)	
			FauxScrollFrame_Update(scrollframe, #ast.filtered, ast.displayRows, ast.rowHeight);
			local o = FauxScrollFrame_GetOffset(scrollframe);
			ast.offset = o;
			
			for i = 1, ast.displayRows do
				local row = i + o;	
				if ast.rows then
					for col = 1, #ast.cols do
						local rowFrame = ast.rows[i];
						local cellFrame = rowFrame.cols[col];
						local fShow = true;
						local fnDoCellUpdate = DoCellUpdate;
						if ast.data[ast.filtered[row]] then
							ast.rows[i]:Show();
							local rowData = ast.data[ast.filtered[row]];
							local cellData = rowData.cols[col];
							if cellData.DoCellUpdate then 
								fnDoCellUpdate = cellData.DoCellUpdate;
							elseif ast.cols[col].DoCellUpdate then 
								fnDoCellUpdate = ast.cols[col].DoCellUpdate;
							elseif rowData.DoCellUpdate then
								fnDoCellUpdate = rowData.DoCellUpdate;
							end
						else
							ast.rows[i]:Hide();
							fShow = false;
						end
						fnDoCellUpdate(rowFrame, cellFrame, ast.data, ast.cols, row, ast.filtered[row], col, fShow);
					end
				end
			end
		end
		
		scrollframe:SetScript("OnVerticalScroll", function(self, offset)
			FauxScrollFrame_OnVerticalScroll(self, offset, ast.rowHeight, ast.Refresh);
		end);
	
		ast:SetFilter(Filter);
		ast:SetDisplayCols(ast.cols);
		ast:SetDisplayRows(ast.displayRows, ast.rowHeight);
		ast:RegisterEvents(ast.DefaultEvents);
		
		return ast;
	end
end

function GetSizingPoint(b_frame)
	local x,y = GetCursorPosition()
	local s = b_frame:GetEffectiveScale()

	local left,bottom,width,height = b_frame:GetRect()

	x = x/s - left
	y = y/s - bottom

	if x < 10 then
		if y < 10 then return "BOTTOMLEFT" end

		if y > height-10 then return "TOPLEFT" end

		return "LEFT"
	end

	if x > width-10 then
		if y < 10 then return "BOTTOMRIGHT" end

		if y > height-10 then return "TOPRIGHT" end

		return "RIGHT"
	end

	if y < 10 then return "BOTTOM" end

	if y > height-10 then return "TOP" end

	return "UNKNOWN"
end

function OnResize()
	if UDKP_st then
		columnHeads[5].width =  UDKP_frame:GetWidth() - 460

		local rows = floor((UDKP_frame:GetHeight()-60-15) / 15)
		if rows > 80 then
			return
		end


		if rows >= #UDKP_st.filtered then
			UDKP_st.scrollframe:Show()
		else
			UDKP_st.scrollframe:Hide()
		end

		UDKP_st:SetDisplayCols(UDKP_st.cols)
		UDKP_st:SetDisplayRows(rows, UDKP_st.rowHeight)

		UDKP_st:Refresh()
	end
end

function WndOnResize()
	return
end

function CreateResizableWindow(frameName,windowTitle, width, height, resizeFunction)
	local s_frame = CreateFrame("Frame",frameName,UIParent)
	s_frame:Hide()

	s_frame:SetFrameStrata("DIALOG")
	s_frame:SetWidth(width)
	s_frame:SetHeight(height)

	s_frame:SetBackdrop({bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
				edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
				tile = true, tileSize = 32, edgeSize = 32,
				insets = { left = 8, right = 8, top = 8, bottom = 8 }})
	if resizeFunction then
		s_frame:SetResizable(true)
		s_frame:SetScript("OnSizeChanged", function() resizeFunction() end)
		s_frame:SetScript("OnMouseDown", function() s_frame:StartSizing(GetSizingPoint(s_frame)) end)
	end
	
	s_frame:SetMovable(true)
	s_frame:SetPoint("CENTER",0,0)

	s_frame:EnableMouse(true)

	
	s_frame:SetScript("OnMouseUp", s_frame.StopMovingOrSizing)
	s_frame:SetScript("OnHide", s_frame.StopMovingOrSizing)

	local movr = CreateFrame("Frame",nil,s_frame)
	movr:SetPoint("BOTTOMRIGHT",s_frame,"BOTTOMRIGHT",0,0)
	movr:SetPoint("TOPLEFT",s_frame,"TOPLEFT",0,0)

	movr:EnableMouse(true)

	movr:SetScript("OnMouseDown", function() s_frame:StartMoving("TestFrame") end)
	movr:SetScript("OnMouseUp", function() s_frame:StopMovingOrSizing("TestFrame") end)
	movr:SetScript("OnHide", function() s_frame:StopMovingOrSizing() end)

	movr:SetHitRectInsets(10,10,10,10)

	s_frame.mover = movr

	local title = CreateFrame("Frame",nil,s_frame)

	title:SetBackdrop({bgFile =	"Interface/Tooltips/UI-Tooltip-Background",
					edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
					tile = true, tileSize = 16, edgeSize = 16,
					insets = { left = 4, right = 4, top = 4, bottom = 4 }})

	title:SetHeight(30)
	title.texture = title:CreateTexture()
	title.texture:SetPoint("BOTTOMLEFT",title,"BOTTOMLEFT",4,4)
	title.texture:SetPoint("TOPRIGHT",title,"TOPRIGHT",-4,-4)
	title.texture:SetGradient("vertical",.66,.54,0,.6,.48,0)
	title:SetPoint("CENTER",s_frame,"TOP",0,-6)
	title:EnableMouse(true)
	title:SetScript("OnMouseDown", function() s_frame:StartMoving() end)
	title:SetScript("OnMouseUp", function() s_frame:StopMovingOrSizing() end)
	title:SetScript("OnHide", function() s_frame:StopMovingOrSizing() end)

	local text = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetJustifyH("CENTER")
	text:SetPoint("CENTER",0,0)
	text:SetTextColor(1,1,1)
	text:SetText(windowTitle)

	title:SetWidth(text:GetStringWidth()+50)

	s_frame.title = title

	local closeButton = CreateFrame("Button",nil,s_frame,"UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT",0,0)
	closeButton:SetScript("OnClick", function() s_frame:Hide() end)
	closeButton:SetFrameLevel(closeButton:GetFrameLevel()+5)

	return s_frame
end

