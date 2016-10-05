-------------------------------------------------				Text box			----------------------------------------------------------
panelWidget["textbox"] = {
	name = "textbox",
	realName = "A bit ritch text box",
	wireType = 0,
	colour = {r = 255, g = 255, b = 255},
	paramTable = {	fontSize = {index = 1, default = 1, realName = "Font Size:", stool = {stype = 1, smin = 1, smax = 15, ntype = 1}},
					alignment = {index = 2, default = 1, realName = "Alignment:", stool = {stype = 1, smin = 1, smax = 2, ntype = 1}}},
	modInit =		function (widget)
						widget.text = ""
						if widget.paramTable[1] then
							widget.fontSize = tonumber (widget.paramTable[1])
						else
							widget.fontSize = 1	--change this too look up default
						end
						if widget.paramTable[2] then
							widget.alignment = tonumber (widget.paramTable[2])
						else
							widget.alignment = 1	--change this too look up default
						end
					end,
	modDraw =		function (ent, widget)												--client
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
						
						local x1 = (ent.x + ((widget.X + (widget.W / 2)) * ent.w * 0.00621)) / ent.RatioX
						local y1 = ent.y + (widget.Y * ent.h * 0.00621)
						draw.DrawText(widget.text, "guipfont"..tostring(16 - widget.fontSize), x1, y1, Color(255, 255, 255, 255), widget.alignment)
						
					end,
	modClicked =	function (ply, widget, Xpos, Ypos)										--client
					end,
	modThink = nil,
	triggerInput =	function (widget, inIndex, value)									--client	(called by server using servSendInput()
						if (inIndex == "text") then
							local maxLineLen = 16 - widget.paramTable[1]
							local maxLines = (16 - widget.paramTable[1]) / 2
							local intoText = false
							local compstring = value
							if (!compstring) then return false end
							compstring = string.gsub(compstring, "<br>", "\n")
							
							local outString = ""
							if (string.len(compstring) > maxLineLen) then
								local lastSpace = 0
								local lastBreak = 1
								local numLines = 1
								for chrNum = 1, string.len(compstring) do
									if (string.byte(string.sub(compstring, chrNum, chrNum)) == 10) && (numLines <= maxLines) then
										outString = outString..string.Left(string.sub(compstring, lastBreak, chrNum), chrPerLine)
										lastBreak = chrNum + 1
										lastSpace = 0
										numLines = numLines + 1
									end
									if (string.sub(compstring, chrNum, chrNum) == " ") then
										lastSpace = chrNum
									end
									if (chrNum >= lastBreak + maxLineLen) && (numLines <= maxLines) then	--if we've gone past a line length since the last break and line is still on screen
										if (lastSpace > 0) then
											outString = outString..string.Left(string.sub(compstring, lastBreak, lastSpace), chrPerLine).."\n"
											lastBreak = lastSpace + 1
											lastSpace = 0
											numLines = numLines + 1
										end
									end
								end
								if (numLines <= maxLines) then
									local foff = 0
									outString = outString..string.Left(string.sub(compstring, lastBreak + foff, string.len(compstring)), chrPerLine).."\n"
								end
							else
								outString = compstring
							end
							--Msg("setting line now ("..outString..")\n")
							widget.text = outString
						end
					end,
	inputs = {text = {index = 1, msgType = 2}},
	outputs = nil,
}
