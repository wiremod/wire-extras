-------------------------------------------------				Label				----------------------------------------------------------
panelWidget["textentry"] = {
	name = "textentry",
	realName = "Text Entry",
	wireType = 0,
	colour = {r = 255, g = 255, b = 255},
	paramTable = {	fontSize = {index = 1, default = 1, realName = "Font Size:", stool = {stype = 1, smin = 1, smax = 15, ntype = 1}},
					maxLen = {index = 2, default = 10, realName = "Max Length:", stool = {stype = 1, smin = 1, smax = 100, ntype = 1}}},
	modInit =		function (widget)
						widget.userTyping = false
						widget.userText = ""
						if widget.paramTable[1] then
							widget.fontSize = tonumber(widget.paramTable[1])
						else
							widget.fontSize = widget.modType.paramTable.fontSize.default
						end
					end,
	modDraw =		function (ent, widget)
						surface.SetDrawColor(ent.currentScheme.outline.r, ent.currentScheme.outline.g, ent.currentScheme.outline.b, 255)
						local x1 = (widget.X * ent.XdrawCoef) + ent.XdrawOffs
						local y1 = (widget.Y * ent.YdrawCoef) + ent.YdrawOffs
						local w = widget.W * ent.XdrawCoef
						local h = widget.H * ent.YdrawCoef
						surface.DrawRect(x1, y1, w, h)
						
						surface.SetDrawColor(100, 100, 100, 255)
						local x1 = ((widget.X + 1) * ent.XdrawCoef) + ent.XdrawOffs
						local y1 = ((widget.Y + 1) * ent.YdrawCoef) + ent.YdrawOffs
						local w = (widget.W - 2) * ent.XdrawCoef
						local h = (widget.H - 2) * ent.YdrawCoef
						surface.DrawRect(x1, y1, w, h)
						local x1 = ((widget.X + (widget.W / 2)) * ent.XdrawCoef) + ent.XdrawOffs
						local y1 = (widget.Y * ent.YdrawCoef) + ent.YdrawOffs	
						draw.DrawText(widget.userText, "guipfont"..tostring(16 - widget.fontSize), x1, y1, Color(255, 255, 255, 255), 1)
						--add draw cursor
					end,
	modClicked =	function (ply, widget, Xpos, Ypos)
						widget.userTyping = true
						widget.parent:StartKeyboard(widget)
						--Msg("started kb\n")
						widget.userText = ""
					end,
	drawUpdate =	function (widget, paramNum, value)
						if (paramNum == 1) then
							widget.userText = value
						end
					end,
	modKeypress =	function (widget, key)
						--Msg("key = "..key.."\n")
						if (!widget.userTyping) then return end
						local currentLen = string.len(widget.userText)
						if (key == "ENTER") then
							widget.parent:EndKeyboard(widget)
							--send text to server here
							--clientSendOutput(widget, 1, widget.userText)
							widget.parent:widgetOutput(ply, widget.modName, "text", widget.userText)
						elseif (key == "BACKSPACE") then
							widget.userText = string.sub(widget.userText, 1, -2)
						elseif (key == "SPACE" && currentLen < tonumber(widget.paramTable[2])) then	
							widget.userText = widget.userText.." "
						elseif (string.len(key) == 1 && currentLen < tonumber(widget.paramTable[2])) then
							widget.userText = widget.userText..key
						end
						guiP_cl_drawUpdate(widget, 1, widget.userText)
					end,
	modThink = nil,
	triggerInput =	function (widget, inIndex, value)
						if (inIndex == "value") then
							widget.cvalue = value
						end
					end,
	inputs = {value = {index = 1, msgType = 1}},
	outputs = {"text"},
}
