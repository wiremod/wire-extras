-------------------------------------------------				Toggle Button				----------------------------------------------------------
panelWidget["buttonToggle"] = {	
	name = "buttonToggle",
	realName = "Toggle Button",
	wireType = 2,
	paramTable = {	label = {index = 1, default = "", realName = "Label", stool = {stype = 2}},
					fontSize = {index = 2, default = 2, realName = "Font Size:", stool = {stype = 1, smin = 1, smax = 15, ntype = 1}}},
	modInit =		function (widget)
						if widget.paramTable[1] then
							widget.text = widget.paramTable[1]
						else
							widget.text = ""
						end
						if widget.paramTable[2] then
							widget.fontSize = tonumber (widget.paramTable[2])
						else
							widget.fontSize = 1	--change this too look up default
						end
					end,
	modDraw =		function (ent, widget)
						surface.SetDrawColor(ent.currentScheme.outline.r, ent.currentScheme.outline.g, ent.currentScheme.outline.b, 255)
						local x1 = (widget.X * ent.XdrawCoef) + ent.XdrawOffs
						local y1 = (widget.Y * ent.YdrawCoef) + ent.YdrawOffs
						local w = widget.W * ent.XdrawCoef
						local h = widget.H * ent.YdrawCoef
						surface.DrawRect(x1, y1, w, h)
						if (widget.aVal) then
							surface.SetDrawColor(ent.currentScheme.highlight.r, ent.currentScheme.highlight.g, ent.currentScheme.highlight.b, 255)
						else
							surface.SetDrawColor(ent.currentScheme.foreground.r, ent.currentScheme.foreground.g, ent.currentScheme.foreground.b, 255)
						end
						local x1 = ((widget.X + 1) * ent.XdrawCoef) + ent.XdrawOffs
						local y1 = ((widget.Y + 1) * ent.YdrawCoef) + ent.YdrawOffs
						local w = (widget.W - 2) * ent.XdrawCoef
						local h = (widget.H - 2) * ent.YdrawCoef
						surface.DrawRect(x1, y1, w, h)
						local x1 = ((widget.X + (widget.W / 2)) * ent.XdrawCoef) + ent.XdrawOffs
						local y1 = (widget.Y * ent.YdrawCoef) + ent.YdrawOffs
						draw.DrawText(widget.text, "guipfont"..tostring(16 - widget.fontSize), x1, y1, Color(ent.currentScheme.text.r, ent.currentScheme.text.g, ent.currentScheme.text.b, 255), 1)
					end,
	modClicked =	function (ply, widget, Xpos, Ypos)
						widget.aVal = !widget.aVal
						local rval = 0
						if (widget.aVal) then rval = 1 end
						--clientSendOutput(widget, 1, rval)
						widget.parent:widgetOutput(ply, widget.modName, "active", rval)
						guiP_cl_drawUpdate(widget, 1, rval)
					end,
	modThink = nil,
	triggerInput =	function (widget, inIndex, value)
					if (inIndex == "set") then
						if (value > 0) then
							widget.aVal = true
						else
							widget.aVal = false
						end
						--local rval = 0
						--if (widget.aVal) then rval = 1 end
						--clientSendOutput(widget, 1, rval)
					end
				end,
	drawUpdate =	function (widget, paramNum, value)
						if (paramNum == 1) then
							if (value > 0) then
								widget.aVal = true
							else
								widget.aVal = false
							end							
						end
					end,
	inputs = {set = {index = 1, msgType = 1}},	--msgType 1 = float, 2 = string
	outputs = {"active"},
						
}
