-------------------------------------------------				Vertical Slider				----------------------------------------------------------
panelWidget["sliderV"] = {
	name = "sliderV",
	realName = "Vertical Slider",
	wireType = 2,
	paramTable = {},
	modInit =		function (widget)
						widget.value = 1
					end,
	modDraw =		function (ent, widget)
						local offs = 10
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
						local x1 = ((widget.X + (widget.W / 2) - 1) * ent.XdrawCoef) + ent.XdrawOffs
						local y1 = ((widget.Y + offs - 3) * ent.YdrawCoef) + ent.YdrawOffs
						local w = 2 * ent.XdrawCoef
						local h = (widget.H - offs - 3) * ent.YdrawCoef
						surface.DrawRect(x1, y1, w, h)
							
						local x1 = ((widget.X + (widget.W / 3)) * ent.XdrawCoef) + ent.XdrawOffs
						local y1 = ((widget.Y + ((widget.H / 2) - 1)) * ent.YdrawCoef) + ent.YdrawOffs
						local w = (widget.W / 3) * ent.XdrawCoef
						local h = 2 * ent.YdrawCoef
						surface.DrawRect(x1, y1, w, h)
						
						local drawPos = ((widget.value * (widget.H - (2 * offs))) + offs) - (widget.H / 24)
						--surface.SetDrawColor(ent.currentScheme.foregroundb.r, ent.currentScheme.foregroundb.g, ent.currentScheme.foregroundb.b, 255)
						local x1 = ((widget.X + (widget.W * 0.15)) * ent.XdrawCoef) + ent.XdrawOffs
						local y1 = ((widget.Y + drawPos) * ent.YdrawCoef) + ent.YdrawOffs
						local w = (widget.W * 0.7) * ent.XdrawCoef
						local h = (widget.H / 12) * ent.YdrawCoef
						surface.DrawRect(x1, y1, w, h)
						
					end,
	modClicked =	function (ply, widget, Xpos, Ypos)
						local offs = 10
						--Msg("widget.H = "..widget.H.."\n")
						widget.value = (math.Min(math.Max(Ypos, offs), widget.H - 6) - offs) / (widget.H - (2 * offs))
						--clientSendOutput(widget, 1, math.Max(1 - widget.value, 0))
						widget.parent:widgetOutput(ply, widget.modName, "value", math.Max(1 - widget.value, 0))
						--send value to client here for draw
						guiP_cl_drawUpdate(widget, 1, widget.value)
					end,
	modThink = nil,	--if this is a function then the widget is added to the client side think list
	triggerInput =	function (widget, inIndex, value)
						if (inIndex == "value") then
							widget.value = value
							guiP_cl_drawUpdate(widget, 1, value)
						end
					end,
	drawUpdate =	function (widget, paramNum, value)
						if (paramNum == 1) then
							widget.value = value						
						end
					end,
	inputs = {value = {index = 1, msgType = 1}},
	outputs = {"value"},
}
