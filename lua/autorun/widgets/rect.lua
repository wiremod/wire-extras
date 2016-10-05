-------------------------------------------------				Vertical Line 				----------------------------------------------------------
panelWidget["rect"] = {
	name = "rect",
	realName = "Rectangle",
	wireType = 0,
	paramTable = {	red = {index = 1, default = 120, realName = "Red:", stool = {stype = 1, smin = 1, smax = 255, ntype = 1}},
					green = {index = 2, default = 120, realName = "Green:", stool = {stype = 1, smin = 1, smax = 255, ntype = 1}},
					blue = {index = 3, default = 120, realName = "Blue:", stool = {stype = 1, smin = 1, smax = 255, ntype = 1}}},
	modInit =		function (widget)
						if widget.paramTable[1] then
							widget.red = tonumber(widget.paramTable[1])
						else
							widget.red = widget.modType.paramTable.red.default
						end
						if widget.paramTable[2] then
							widget.green = tonumber(widget.paramTable[2])
						else
							widget.green = widget.modType.paramTable.green.default
						end
						if widget.paramTable[3] then
							widget.blue = tonumber(widget.paramTable[3])
						else
							widget.blue = widget.modType.paramTable.blue.default
						end
					end,
	modDraw =		function (ent, widget)
						surface.SetDrawColor(widget.red, widget.green, widget.blue, 255)
						local x1 = (widget.X * ent.XdrawCoef) + ent.XdrawOffs
						local y1 = (widget.Y * ent.YdrawCoef) + ent.YdrawOffs
						local w = widget.W * ent.XdrawCoef
						local h = widget.H * ent.YdrawCoef
						surface.DrawRect(x1, y1, w, h)
					end,
	modClicked =	function (ply, widget, Xpos, Ypos)
					end,
	modThink = nil,
	triggerInput =	function (widget, inIndex, value)
					end,
	inputs = nil,
	outputs = nil,
}
