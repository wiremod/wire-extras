-------------------------------------------------				Vertical Progress Bar				----------------------------------------------------------
panelWidget["progressV"] = {
	name = "progressV",
	realName = "Vertical Progress Bar",
	wireType = 1,
	paramTable = {	direction = {index = 1, default = 0, realName = "Direction:", stool = {stype = 3}}},
	modInit =		function (widget)
						widget.cvalue = 0
						if widget.paramTable[1] then
							widget.direction = tonumber(widget.paramTable[1])
						else
							widget.direction = 0
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
						
						surface.SetDrawColor(ent.currentScheme.highlight.r, ent.currentScheme.highlight.g, ent.currentScheme.highlight.b, 255)
						if (widget.direction > 0) then
							y1 = ((widget.Y +  3) * ent.YdrawCoef) + ent.YdrawOffs
							h = ((widget.H - 6) * widget.cvalue) * ent.YdrawCoef
						else
							y1 = ((widget.Y + ((widget.H - 6) * (1 - widget.cvalue)) + 3) * ent.YdrawCoef) + ent.YdrawOffs
							h = ((widget.H - 12) * widget.cvalue) * ent.YdrawCoef
						end
						local x1 = ((widget.X + 3) * ent.XdrawCoef) + ent.XdrawOffs
						local w = (widget.W - 6) * ent.XdrawCoef
						surface.DrawRect(x1, y1, w, h)
					end,
	modClicked =	function (ply, widget, Xpos, Ypos)
					end,
	modThink = nil,
	triggerInput =	function (widget, inIndex, value)
						if (inIndex == "value") then
							widget.cvalue = value
							guiP_cl_drawUpdate(widget, 1, value)
						end
					end,
	drawUpdate =	function (widget, paramNum, value)
						if (paramNum == 1) then
							widget.cvalue = value						
						end
					end,
	inputs = {value = {index = 1, msgType = 1}},
	outputs = nil,
}
