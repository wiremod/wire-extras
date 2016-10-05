-------------------------------------------------				List				----------------------------------------------------------
panelWidget["list"] = {	
	name = "list",
	realName = "List Box",
	wireType = 2,
	paramTable = {	fontSize = {index = 1, default = 2, realName = "Font Size:", stool = {stype = 1, smin = 1, smax = 15, ntype = 1} },
					list = {index = 2, default = "", realName = "List (seperate with |):", stool = {stype = 2}}},
	modInit =		function (widget)
						widget.selected = 0
						if widget.paramTable[1] then
							widget.oSpacing = tonumber(widget.paramTable[1]) * 5
							widget.size = tonumber(widget.paramTable[1])
						else
							widget.oSpacing = widget.modType.paramTable.fontSize.default * 5
							widget.size = 1
						end
						if widget.paramTable[2] then
							widget.options = string.Explode("|", widget.paramTable[2])
							widget.numOptions = table.getn(widget.options) - 1
						else
							widget.options = {}
							widget.numOptions = 0
						end
					end,
	modDraw =		function (ent, widget)
						surface.SetDrawColor(ent.currentScheme.outline.r, ent.currentScheme.outline.g, ent.currentScheme.outline.b, 255)
						local x1 = (widget.X * ent.XdrawCoef) + ent.XdrawOffs
						local y1 = (widget.Y * ent.YdrawCoef) + ent.YdrawOffs
						local w = widget.W * ent.XdrawCoef
						local h = widget.H * ent.YdrawCoef
						surface.DrawRect(x1, y1, w, h)
						
						surface.SetDrawColor(ent.currentScheme.foreground.r, ent.currentScheme.foreground.g, ent.currentScheme.foreground.b, 255)
						local x1 = ((widget.X + 1) * ent.XdrawCoef) + ent.XdrawOffs
						local y1 = ((widget.Y + 1) * ent.YdrawCoef) + ent.YdrawOffs
						local w = (widget.W - 2) * ent.XdrawCoef
						local h = (widget.H - 2) * ent.YdrawCoef
						surface.DrawRect(x1, y1, w, h)
						
						surface.SetDrawColor(ent.currentScheme.foregroundb.r, ent.currentScheme.foregroundb.g, ent.currentScheme.foregroundb.b, 255)
						local x1 = ((widget.X + 1) * ent.XdrawCoef) + ent.XdrawOffs
						local w = (widget.W - 2) * ent.XdrawCoef
						local h = 1 * ent.YdrawCoef
						
						for offs=0, widget.numOptions, 1 do
							local y1 = ((widget.Y + 1 + (offs * widget.oSpacing)) * ent.YdrawCoef) + ent.YdrawOffs
							surface.DrawRect(x1, y1, w, h)
						end
						
						surface.SetDrawColor(ent.currentScheme.highlight.r, ent.currentScheme.highlight.g, ent.currentScheme.highlight.b, 255)
						local x1 = ((widget.X + 1) * ent.XdrawCoef) + ent.XdrawOffs
						local y1 = ((widget.Y + (widget.selected * widget.oSpacing) + 1) * ent.YdrawCoef) + ent.YdrawOffs
						local w = (widget.W - 2) * ent.XdrawCoef
						local h = (widget.oSpacing + 2) * ent.YdrawCoef
						surface.DrawRect(x1, y1, w, h)
						
						local x1 = ((widget.X + 2) * ent.XdrawCoef) + ent.XdrawOffs
						for k, text in ipairs(widget.options) do
							local y1 = ((widget.Y + ((k - 1) * widget.oSpacing)) * ent.YdrawCoef) + ent.YdrawOffs
							draw.DrawText(text, "guipfont"..16 - widget.size, x1, y1, Color(ent.currentScheme.text.r, ent.currentScheme.text.g, ent.currentScheme.text.b, 255), 0)
						end
					end,
	modClicked =	function (ply, widget, Xpos, Ypos)		
						widget.selected = math.Min(math.Round((Ypos - (widget.oSpacing / 2)) / widget.oSpacing), widget.numOptions)
						--clientSendOutput(widget, 1, widget.selected + 1)
						widget.parent:widgetOutput(ply, widget.modName, "selected", widget.selected + 1)
						guiP_cl_drawUpdate(widget, 1, widget.selected)
						--print ("sent "..widget.selected.."\n")
					end,
	modThink = nil,
	triggerInput =	function (widget, inIndex, value)
						if (inIndex == "options") then
							--clientSendOutput(widget, 1, widget.selected + 1)
							widget.parent:widgetOutput(nil, widget.modName, "selected", widget.selected + 1)
							widget.options = string.Explode("|", value)
							widget.numOptions = table.getn(widget.options) - 1
							widget.selected = 0
							guiP_cl_drawUpdate(widget, 2, value)
							--print ("sent "..value.."\n")
						end
					end,
	drawUpdate =	function (widget, paramNum, value)
						--print ("recieved "..value.."\n")
						if (paramNum == 1) then
							widget.selected = value
						elseif (paramNum == 2) then
							widget.options = string.Explode("|", value)
							widget.numOptions = table.getn(widget.options) - 1
							widget.selected = 0
						end
					end,
	inputs = {options = {index = 1, msgType = 2}},
	outputs = {"selected"}
}
