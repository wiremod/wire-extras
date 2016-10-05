-------------------------------------------------				Indicator				----------------------------------------------------------
panelWidget["indicator"] = {
	name = "indicator",
	realName = "Indicator",
	wireType = 1,
	paramTable = {	label = {index = 1, default = "", realName = "Label:", stool = {stype = 2}},
					fontSize = {index = 2, default = 1, realName = "Font Size:", stool = {stype = 1, smin = 1, smax = 15, ntype = 1}}},
	modInit =		function (widget)
						widget.cvalue = 0
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
						
						surface.SetDrawColor(ent.currentScheme.highlight.r * widget.cvalue, ent.currentScheme.highlight.g * widget.cvalue, ent.currentScheme.highlight.b * widget.cvalue, 255)
						local x1 = ((widget.X + 1) * ent.XdrawCoef) + ent.XdrawOffs
						local y1 = ((widget.Y + 1) * ent.YdrawCoef) + ent.YdrawOffs
						local w = (widget.W - 2) * ent.XdrawCoef
						local h = (widget.H - 2) * ent.YdrawCoef
						surface.DrawRect(x1, y1, w, h)
						
						local x1 = ((widget.X + (widget.W / 2)) * ent.XdrawCoef) + ent.XdrawOffs
						local y1 = ((widget.Y) * ent.YdrawCoef) + ent.YdrawOffs
						draw.DrawText(widget.text, "guipfont"..tostring(16 - widget.fontSize), x1, y1, Color(ent.currentScheme.text.r, ent.currentScheme.text.g, ent.currentScheme.text.b, 255), 1)
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
