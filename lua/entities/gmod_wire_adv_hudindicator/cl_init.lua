
include('shared.lua')

ENT.RenderGroup 		= RENDERGROUP_BOTH

local advhudindicators = {}
// Default HUD x/y
//local hudx = 0
//local hudy = 0
local nextupdate = 0

// Text Height Constant
local dtextheight = draw.GetFontHeight("Default")

// So we don't need to calculate this every frame w/ Percent Bar style
local pbarheight = dtextheight + 16

// Y Offset constants
//local offsety = {32, 32, 32, 92 + dtextheight, 60 + dtextheight}

// Texture IDs for Full/Semi-Circle styles
//local fullcircletexid = surface.GetTextureID("hudindicator/hi_fullcircle")
//local semicircletexid = surface.GetTextureID("hudindicator/hi_semicircle")

local tex_sci_fi_1 = surface.GetTextureID("adv_hud/sci_fi_style_1")


// Copied from wirelib.lua (table.MakeSortedKeys() should be made shared :P)
local function MakeSortedKeys(tbl)
	local result = {}

	for k,_ in pairs(tbl) do table.insert(result, k) end
	table.sort(result)

	return result
end

// Function to check if a registered HUD Indicator:
// A) belongs to someone other than the calling LocalPlayer()
// B) is not registered as pod-only
function ENT:ClientCheckRegister()
	local ply = LocalPlayer()
	local plyuid = ply:UniqueID()
	return ply != self:GetPlayer() && !self:GetNWBool(plyuid)
end

// Used by STool for unregister control panel
// Only allowed to unregister HUD Indicators that aren't yours
// and for those that aren't pod-only registers
function AdvHUDIndicator_GetCurrentRegistered()
	local registered = {}
	for eindex,_ in pairs(advhudindicators) do
		local ent = ents.GetByIndex(eindex)
		if (ent && ent:IsValid()) and (ent:CheckClientRegister()) then
			local entry = {}
			entry.EIndex = eindex
			entry.Description = advhudindicators[eindex].Description
			table.insert(registered, entry)
		end
	end

	return registered
end

local function isInsideZone( x, y, minX, minY, maxX, maxY )
	return ( x > minX && x < maxX ) and ( y > minY && y < maxY )
end

local function DrawAdvHUDIndicators()

	if (!LocalPlayer():Alive()) then return end

	local screenWidth = ScrW()
	local screenHeight = ScrH()

	//local halfScreenWidth = screenWidth/2
	//local halfScreenHeight = screenHeight/2

	local errors = 0

	// Now draw HUD Indicators
	for _, index in ipairs(MakeSortedKeys(advhudindicators)) do
		if (advhudindicators[index]) then // Is this necessary?
			local ent = ents.GetByIndex(index)

			if (ent && ent:IsValid() ) then
				local indinfo = advhudindicators[index]

				//-- If we're hidden just skip this lot --//
				if( !indinfo.HideHUD ) then

					local xPos = indinfo.xPos
					local yPos = indinfo.yPos
					local zPos = indinfo.zPos

					local xEnd = indinfo.xEnd
					local yEnd = indinfo.yEnd
					local zEnd = indinfo.zEnd

					local positionMethod = indinfo.positionMethod

					//--Convert the world position to a screenspace position, this skips the input conversion step, as it makes no sense here...
					if( indinfo.useWorldCoords == 1 ) then

						//-- Start Coordinate --//
						local screenPos = Vector( xPos, yPos, zPos ):ToScreen()
						xPos = screenPos.x
						yPos = screenPos.y

						//-- End Coordinate --//
						local endScreenPos = Vector( xEnd, yEnd, zEnd ):ToScreen()
						xEnd = endScreenPos.x
						yEnd = endScreenPos.y

					else
						//--Convert the positions based on the position method.
						if( positionMethod == 1 ) then
							xPos = (screenWidth/100)*xPos
							yPos = (screenHeight/100)*yPos
							if( xEnd && yEnd ) then
								xEnd = (screenWidth/100)*xEnd
								yEnd = (screenHeight/100)*yEnd
							end
						elseif( positionMethod == 2 ) then
							xPos = screenWidth*((xPos/2)+0.5)
							yPos = screenHeight*((yPos/2)+0.5)
							if( xEnd && yEnd ) then
								xEnd = screenWidth*((xEnd/2)+0.5)
								yEnd = screenHeight*((yEnd/2)+0.5)
							end
						end

					end

					local txt = indinfo.FullText or ""

					//local alphaVal = 160
					if( indinfo.alpha != nil ) then
						alphaVal = indinfo.alpha
					end

					//-- Access the colors for this indicator, and update the local variables --//
					local AColor = indinfo.AColor
					local BColor = indinfo.BColor

					if( indinfo.Style == nil ) then
						errors = errors + 1

					//-- Basic --//
					elseif (indinfo.Style == 0) then
						//--draw.WordBox(8, xPos, yPos, txt, "Default", Color(50, 50, 75, 192), Color(255, 255, 255, 255))

						draw.DrawText( txt, "ScoreboardText", xPos, yPos, indinfo.DisplayColor, indinfo.TextColor )


					//-- Boxed Text (rounded corners...) --//
					elseif (indinfo.Style == 1) then

						//draw.WordBox(8, xPos, yPos, txt, "Default", indinfo.DisplayColor, indinfo.TextColor)
						draw.WordBox(8, xPos, yPos, txt, "Default", Color(BColor.r, BColor.g, BColor.b, BColor.a), Color(AColor.r, AColor.g, AColor.b, AColor.a))


					//--Text Box - Pretty much only useful with string gates--//
					elseif (indinfo.Style == 2) then
						local lines = string.Explode("|", indinfo.Description)
						//local totalLines = table.Count(lines)
						local boxWidth = 0
						local boxHeight = 0

						surface.SetFont("ChatFont")

						//--Gather the total height and max width of this text--//
						for k,v in pairs(lines) do

							local lineWidth, lineHeight = surface.GetTextSize( v )
							if ( lineWidth > boxWidth ) then boxWidth = lineWidth end
							boxHeight = boxHeight + lineHeight + 2
						end

						//--Add a bit of a border (5px all round)--//
						boxWidth = boxWidth + 10
						boxHeight = boxHeight + 10

						//--Draw the background rectangle--//
						surface.SetDrawColor(50, 50, 75, 192)
						surface.DrawRect( xPos, yPos, boxWidth, boxHeight )

						surface.SetTextColor(255, 255, 255, 255)
						local index = 0
						for k,v in pairs(lines) do
							//local lineWidth, lineHeight = surface.GetTextSize( v )

							surface.SetTextPos( xPos+5, yPos+5+(index*(lineHeight+2)) )
							surface.DrawText( v );
							index = index + 1
						end


					//-- Percent Bar (Style 1) --//
					elseif (indinfo.Style == 10) then

						local pbarwidth = 200

						//--Reposition at the center of the point specified.--//
						xPos = xPos - pbarwidth/2
						xPos = xPos - pbarheight/2

						local w1 = pbarwidth*indinfo.Factor
						local w2 = pbarwidth*(1-indinfo.Factor)

						if (indinfo.Factor > 0) then // Draw only if we have a factor
							local BColor = indinfo.BColor
							surface.SetDrawColor(BColor.r, BColor.g, BColor.b, 160)
							surface.DrawRect(xPos, yPos, w1, pbarheight)
						end

						if (indinfo.Factor < 1) then
							//--local AColor = indinfo.AColor
							surface.SetDrawColor(AColor.r, AColor.g, AColor.b, 160)
							surface.DrawRect(xPos+w1, yPos, w2, pbarheight)
						end

						//--Draw the border--//
						surface.SetDrawColor( 255, 255, 255,160)
						surface.DrawOutlinedRect(xPos, yPos, pbarwidth, pbarheight)

						if( txt != "" ) then
							draw.SimpleText(txt, "Default", xPos+10, yPos+8, Color(255, 255, 255, 255), 0)
						end

					//-- Percent Bar (Style 2) --//
					elseif( indinfo.Style == 11 ) then
						local pbarwidth = 200

						//--Reposition at the center of the point specified.--//
						xPos = xPos - pbarwidth/2
						xPos = xPos - pbarheight/2

						local pos = pbarwidth*indinfo.Factor

						//--Draw the bar--//
						surface.SetDrawColor(BColor.r, BColor.g, BColor.b, 160)
						surface.DrawRect(xPos, yPos, pbarwidth, pbarheight)

						//--Draw the marker--//
						surface.SetDrawColor(AColor.r, AColor.g, AColor.b, 160)
						surface.DrawRect(xPos+pos-3, yPos, 6, pbarheight)

						//--Draw the border--//
						surface.SetDrawColor( 255, 255, 255,160)
						surface.DrawOutlinedRect(xPos, yPos, pbarwidth, pbarheight)

						if( txt != "" ) then
							draw.SimpleText(txt, "Default", xPos+10, yPos+7, Color(255, 255, 255, 255), 0)
						end

					//-- Vertical Bar (Style 1) --//
					elseif (indinfo.Style == 20) then

						local pbarwidth = 200

						//--Reposition at the center of the point specified.--//
						xPos = xPos - pbarwidth/2
						xPos = xPos - pbarheight/2

						local w1 = pbarwidth*indinfo.Factor
						local w2 = pbarwidth*(1-indinfo.Factor)

						if (indinfo.Factor > 0) then // Draw only if we have a factor
							local BColor = indinfo.BColor
							surface.SetDrawColor(BColor.r, BColor.g, BColor.b, 160)
							surface.DrawRect(xPos, yPos, pbarheight, w1)
						end

						if (indinfo.Factor < 1) then
							//--local AColor = indinfo.AColor
							surface.SetDrawColor(AColor.r, AColor.g, AColor.b, 160)
							surface.DrawRect(xPos, yPos+w1, pbarheight, w2)
						end

						//--Draw the border--//
						surface.SetDrawColor( 255, 255, 255,160)
						surface.DrawOutlinedRect(xPos, yPos, pbarheight, pbarwidth)

						if( txt != "" ) then
							draw.SimpleText(txt, "Default", xPos+pbarheight+5, yPos, Color(255, 255, 255, 255), 0)
						end

					//-- Vertical Bar (Style 2) --//
					elseif(indinfo.Style == 21) then
						local pbarwidth = 200

						//--Reposition at the center of the point specified.--//
						xPos = xPos - pbarwidth/2
						xPos = xPos - pbarheight/2

						local pos = pbarwidth*indinfo.Factor

						//--Draw the bar--//
						surface.SetDrawColor(BColor.r, BColor.g, BColor.b, 160)
						surface.DrawRect(xPos, yPos, pbarheight, pbarwidth)

						//--Draw the marker--//
						surface.SetDrawColor(AColor.r, AColor.g, AColor.b, 160)
						surface.DrawRect(xPos, yPos+pos-3, pbarheight, 6)

						//--Draw the border--//
						surface.SetDrawColor( 255, 255, 255,160)
						surface.DrawOutlinedRect(xPos, yPos, pbarheight, pbarwidth)

						if( txt != "" ) then
							draw.SimpleText(txt, "Default", xPos+pbarheight+5, yPos, Color(255, 255, 255, 255), 0)
						end

					//-- Targetting Rectangle --//
					elseif (indinfo.Style == 30) then

						local size = 45

						surface.SetDrawColor(AColor.r, AColor.g, AColor.b, 90)
						surface.DrawRect(xPos-size, yPos-size, size*2, size*2)

						surface.SetDrawColor(BColor.r, BColor.g, BColor.b, 160)

						surface.DrawLine(xPos-size, yPos-size, xPos-size, yPos-size+15)
						surface.DrawLine(xPos-size, yPos-size, xPos-size+15, yPos-size)

						surface.DrawLine(xPos+size, yPos-size, xPos+size, yPos-size+15)
						surface.DrawLine(xPos+size, yPos-size, xPos+size-15, yPos-size)

						surface.DrawLine(xPos-size, yPos+size, xPos-size, yPos+size-15)
						surface.DrawLine(xPos-size, yPos+size, xPos-size+15, yPos+size)

						surface.DrawLine(xPos+size, yPos+size, xPos+size, yPos+size-15)
						surface.DrawLine(xPos+size, yPos+size, xPos+size-15, yPos+size)

						if( txt != "" ) then
							surface.DrawLine( xPos+size, yPos+size, xPos+size+20, yPos+size+20 )
							draw.WordBox(8, xPos+size+20, yPos+size+12, txt, "Default", Color(50,255,50, 160), Color(0,0,0, 255) )
						end

					//-- Target rectangle with lines to the corners of the screen --//
					elseif (indinfo.Style == 31) then

						local size = 45
						local bracket_length = 15

						if( isInsideZone(xPos, yPos, 0, 0, screenWidth, screenHeight) ) then
							//--Corner brackets--//
							surface.SetDrawColor(AColor.r, AColor.g, AColor.b, 160)

							surface.DrawLine(xPos-size, yPos-size, xPos-size, yPos-size+bracket_length)
							surface.DrawLine(xPos-size, yPos-size, xPos-size+bracket_length, yPos-size)

							surface.DrawLine(xPos+size, yPos-size, xPos+size, yPos-size+bracket_length)
							surface.DrawLine(xPos+size, yPos-size, xPos+size-bracket_length, yPos-size)

							surface.DrawLine(xPos-size, yPos+size, xPos-size, yPos+size-bracket_length)
							surface.DrawLine(xPos-size, yPos+size, xPos-size+bracket_length, yPos+size)

							surface.DrawLine(xPos+size, yPos+size, xPos+size, yPos+size-bracket_length)
							surface.DrawLine(xPos+size, yPos+size, xPos+size-bracket_length, yPos+size)

							//--Lines from the corner of the screen--//
							surface.DrawLine( 0, 0, xPos-size, yPos-size )
							surface.DrawLine( screenWidth, 0, xPos+size, yPos-size )
							surface.DrawLine( screenWidth, screenHeight, xPos+size, yPos+size )
							surface.DrawLine( 0, screenHeight, xPos-size, yPos+size )


							if( txt != "" ) then
								draw.WordBox(8, xPos+size+20, yPos+size+20, txt, "Default", Color(50,255,50, 160), Color(0,0,0, 255) )
							end

						end

					//-- Targetting Triangle --//
					elseif (indinfo.Style == 40) then

						surface.SetDrawColor(AColor.r, AColor.g, AColor.b, 160)

						surface.DrawLine(xPos-20, yPos-10, xPos+20, yPos-10)
						surface.DrawLine(xPos-20, yPos-10, xPos, yPos+10)
						surface.DrawLine(xPos+20, yPos-10, xPos, yPos+10)

					//-- Crosshair Style 1 --//
					elseif (indinfo.Style == 50) then

						surface.SetDrawColor(AColor.r, AColor.g, AColor.b, 160)

						surface.DrawLine( xPos-20, yPos, xPos+20, yPos )
						surface.DrawLine( xPos, yPos-20, xPos, yPos+20 )

					//-- Crosshair Style 2 --//
					elseif (indinfo.Style == 51) then

						surface.SetDrawColor(AColor.r, AColor.g, AColor.b, 160)

						surface.DrawLine(xPos, yPos-25, xPos, yPos-5)
						surface.DrawLine(xPos, yPos+25, xPos, yPos+5)

						surface.DrawLine(xPos-25, yPos, xPos-5, yPos)
						surface.DrawLine(xPos+25, yPos, xPos+5, yPos)

					//-- Crosshair Style 3 --//
					elseif (indinfo.Style == 52) then

						surface.SetDrawColor(AColor.r, AColor.g, AColor.b, 160)

						surface.DrawLine( xPos-20, yPos, xPos+20, yPos )
						surface.DrawLine( xPos, yPos-10, xPos, yPos+10 )

						//-- The braces are now controlled by wire inputs in the Extended I/O indicators. --//
						//-- Left Brace, This should be controlled by wire inputs!

						surface.SetDrawColor(BColor.r, BColor.g, BColor.b, 160)

						surface.DrawLine( xPos-30, yPos-10, xPos-30, yPos+10 )
						surface.DrawLine( xPos-30, yPos-10, xPos-25, yPos-10 )
						surface.DrawLine( xPos-30, yPos+10, xPos-25, yPos+10 )

						//-- Right Brace, This should be controlled by wire inputs!

						surface.DrawLine( xPos+30, yPos-10, xPos+30, yPos+10 )
						surface.DrawLine( xPos+30, yPos-10, xPos+25, yPos-10 )
						surface.DrawLine( xPos+30, yPos+10, xPos+25, yPos+10 )


					//-- Crosshair with lines to edges of screen --//
					elseif (indinfo.Style == 53) then

						surface.SetDrawColor(AColor.r, AColor.g, AColor.b, 160)

						//-- Lines to the edge of the screen
						surface.DrawLine( 0, yPos, xPos-20, yPos )
						surface.DrawLine( xPos+20, yPos, screenWidth, yPos )
						surface.DrawLine( xPos, 0, xPos, yPos-20 )
						surface.DrawLine( xPos, yPos+20, xPos, screenHeight )


						//--Inner Braces
						surface.DrawLine( xPos-10, yPos-20, xPos+10, yPos-20 )
						surface.DrawLine( xPos-10, yPos+20, xPos+10, yPos+20 )
						surface.DrawLine( xPos-20, yPos-10, xPos-20, yPos+10 )
						surface.DrawLine( xPos+20, yPos-10, xPos+20, yPos+10 )

						if( txt != "" ) then
							draw.WordBox(8, xPos+20, yPos+20, txt, "Default", Color(50,255,50, 160), Color(0,0,0, 255) )
						end

					//-- Textured crosshair in the 'Ghost In The Shell' style --//
					//-- Lines to edge of screen also. --//
					elseif (indinfo.Style == 54) then

						surface.SetTexture(tex_sci_fi_1)

						local xSize = 256
						local ySize = 256
						local xOffset = 128
						local yOffset = 128

						//-- Texture is 256x256, ergo position needs to be offset by 128.
						surface.DrawTexturedRect( xPos-xOffset, yPos-yOffset, xSize, ySize )

						//-- Lines to the edge of the screen to match the texture...
						surface.SetDrawColor(187, 215, 239, 160)
						surface.DrawLine( 0, yPos, xPos-xOffset, yPos )
						surface.DrawLine( 0, yPos-1, xPos-xOffset, yPos-1 )

						surface.DrawLine( xPos+xOffset, yPos, screenWidth, yPos )
						surface.DrawLine( xPos+xOffset, yPos-1, screenWidth, yPos-1 )

						surface.DrawLine( xPos, 0, xPos, yPos-yOffset )
						surface.DrawLine( xPos-1, 0, xPos-1, yPos-yOffset )

						surface.DrawLine( xPos, yPos+yOffset, xPos, screenHeight )
						surface.DrawLine( xPos-1, yPos+yOffset, xPos-1, screenHeight )


					//--Animating target marker (triangular)--//
					//--Offsets 100 from the normal indicators, so I have room to group types--//
					elseif( indinfo.Style == 100 ) then

						local frame = RealTime()*120

						local point1x = xPos+(math.sin(math.rad(frame))*20)
						local point1y = yPos+(math.cos(math.rad(frame))*20)

						local point2x = xPos+(math.sin(math.rad(frame+120))*20)
						local point2y = yPos+(math.cos(math.rad(frame+120))*20)

						local point3x = xPos+(math.sin(math.rad(frame+240))*20)
						local point3y = yPos+(math.cos(math.rad(frame+240))*20)

						surface.SetDrawColor(AColor.r, AColor.g, AColor.b, 160)
						surface.DrawLine( point1x, point1y, point2x, point2y )
						surface.DrawLine( point2x, point2y, point3x, point3y )
						surface.DrawLine( point3x, point3y, point1x, point1y )

						if( txt != "" ) then
							draw.WordBox(8, xPos+20, yPos+20, txt, "Default", Color(50,255,50, 160), Color(0,0,0, 255) )
						end


					//-----------------------------------------------------------------------------------------------//
					//-- [Extended I/O] [Extended I/O] [Extended I/O] [Extended I/O] [Extended I/O] [Extended I/O] --//
					//-----------------------------------------------------------------------------------------------//
					//-- These inputs have other IO functions on the SENT, so can access the exio values           --//
					//-----------------------------------------------------------------------------------------------//
					//-- Targetting Rectangle --//
					elseif (indinfo.Style == 1000) then

						local size = 45
						if( indinfo.exio_size != nil ) then size = indinfo.exio_size end
						if( size < 0 ) then size = 0 end

						surface.SetDrawColor(AColor.r, AColor.g, AColor.b, 90)
						surface.DrawRect(xPos-size, yPos-size, size*2, size*2)

						surface.SetDrawColor(BColor.r, BColor.g, BColor.b, 160)

						surface.DrawLine(xPos-size, yPos-size, xPos-size, yPos-size+15)
						surface.DrawLine(xPos-size, yPos-size, xPos-size+15, yPos-size)

						surface.DrawLine(xPos+size, yPos-size, xPos+size, yPos-size+15)
						surface.DrawLine(xPos+size, yPos-size, xPos+size-15, yPos-size)

						surface.DrawLine(xPos-size, yPos+size, xPos-size, yPos+size-15)
						surface.DrawLine(xPos-size, yPos+size, xPos-size+15, yPos+size)

						surface.DrawLine(xPos+size, yPos+size, xPos+size, yPos+size-15)
						surface.DrawLine(xPos+size, yPos+size, xPos+size-15, yPos+size)

						if( txt != "" ) then
							surface.DrawLine( xPos+size, yPos+size, xPos+size+20, yPos+size+20 )
							draw.WordBox(8, xPos+size+20, yPos+size+12, txt, "Default", Color(50,255,50, 160), Color(0,0,0, 255) )
						end

					//-- Crosshair Style 3 --//
					elseif (indinfo.Style == 1001) then

						surface.SetDrawColor(AColor.r, AColor.g, AColor.b, 160)

						surface.DrawLine( xPos-20, yPos, xPos+20, yPos )
						surface.DrawLine( xPos, yPos-10, xPos, yPos+10 )

						surface.SetDrawColor(BColor.r, BColor.g, BColor.b, 160)

						//-- Left Brace --//
						if( indinfo.exio_lbrace != nil ) and ( indinfo.exio_lbrace > 0 ) then
							surface.DrawLine( xPos-30, yPos-10, xPos-30, yPos+10 )
							surface.DrawLine( xPos-30, yPos-10, xPos-25, yPos-10 )
							surface.DrawLine( xPos-30, yPos+10, xPos-25, yPos+10 )
						end

						//-- Right Brace --//
						if( indinfo.exio_rbrace != nil ) and ( indinfo.exio_rbrace > 0 ) then
							surface.DrawLine( xPos+30, yPos-10, xPos+30, yPos+10 )
							surface.DrawLine( xPos+30, yPos-10, xPos+25, yPos-10 )
							surface.DrawLine( xPos+30, yPos+10, xPos+25, yPos+10 )
						end

					//-- Divided Box --//
					elseif (indinfo.Style == 1002) then

						if( indinfo.exio_width == nil ) then
							indinfo.exio_width = 200
							//--Msg("[WW] exio_width has not been set yet... using default value of 200\n")
							errors = errors + 1
						end
						if( indinfo.exio_height == nil ) then
							indinfo.exio_height = 200
							//--Msg("[WW] exio_height has not been set yet... using default value of 200\n")
							errors = errors + 1
						end
						if( indinfo.exio_x == nil ) then
							indinfo.exio_x = 50
							//--Msg("[WW] exio_x has not been set yet... using default value of 50\n")
							errors = errors + 1
						end
						if( indinfo.exio_y == nil ) then
							indinfo.exio_y = 50
							//--Msg("[WW] exio_y has not been set yet... using default value of 50\n")
							errors = errors + 1
						end

						local x = xPos - (indinfo.exio_width/2)
						local y = yPos - (indinfo.exio_height/2)

						xRef = math.Clamp( (indinfo.exio_x/100)*indinfo.exio_width, 0, indinfo.exio_width )
						yRef = math.Clamp( (indinfo.exio_y/100)*indinfo.exio_height, 0, indinfo.exio_height )

						surface.SetDrawColor(BColor.r, BColor.g, BColor.b, 160)
						surface.DrawRect( x, y, indinfo.exio_width, indinfo.exio_height )

						surface.SetDrawColor(AColor.r, AColor.g, AColor.b, 255)
						surface.DrawOutlinedRect( x, y, indinfo.exio_width, indinfo.exio_height )
						surface.DrawLine( x+xRef, y, x+xRef, y+indinfo.exio_height )
						surface.DrawLine( x, y+yRef, x+indinfo.exio_width, y+yRef )

					end

					//-- manual draw mode, possibly -intensely- laggy...--//
					if( xEnd && yEnd ) then
						//--XY->XY Line mode --//
						if( indinfo.Style == 200 ) then
							surface.SetDrawColor(AColor.r, AColor.g, AColor.b, 160)
							surface.DrawLine( xPos, yPos, xEnd, yEnd )

						//--XY->XY Box mode --//
						elseif( indinfo.Style == 201 ) then

							local boxSizeX = xEnd-xPos
							local boxSizeY = yEnd-yPos
							local drawX = xPos
							local drawY = yPos
							if( boxSizeX < 0 ) then
								boxSizeX = xPos-xEnd
								drawX = xEnd
							end
							if( boxSizeY < 0 ) then
								boxSizeY = yPos-yEnd
								drawY = yEnd
							end


							surface.SetDrawColor(AColor.r, AColor.g, AColor.b, 160)
							surface.DrawRect( drawX, drawY, boxSizeX, boxSizeY )

						//--XY->XY Rounded Box mode --//
						elseif( indinfo.Style == 202 ) then

							local boxSizeX = xEnd-xPos
							local boxSizeY = yEnd-yPos
							local drawX = xPos
							local drawY = yPos
							if( boxSizeX < 0 ) then
								boxSizeX = xPos-xEnd
								drawX = xEnd
							end
							if( boxSizeY < 0 ) then
								boxSizeY = yPos-yEnd
								drawY = yEnd
							end

							surface.SetDrawColor(AColor.r, AColor.g, AColor.b, 160)
							draw.RoundedBox( 3, drawX, drawY, boxSizeX, boxSizeY, Color(255,255,255, 160) )

						end

					end

				end

			else
				// Clear this from the table so we don't check again
				advhudindicators[index] = nil
			end
		end
	end

	//--if( errors > 0 ) then
	//--	draw.WordBox(8, 20, 20, "[Warning] "..errors.." indicators were missing information at render time! If this message does not go away - contact a developer! ", "Default", Color(50, 50, 75, 192), Color(255, 255, 255, 255))
	//--end

end
hook.Add("HUDPaint", "DrawAdvHUDIndicators", DrawAdvHUDIndicators)

local function AdvHUDFormatDescription( eindex )
	// This is placed here so we don't have to update
	// the description more often than is necessary
	local indinfo = advhudindicators[eindex]
	advhudindicators[eindex].FullText = indinfo.Description

	if( indinfo.xPos == nil ) then indinfo.xPos = 0 end
	if( indinfo.yPos == nil ) then indinfo.yPos = 0 end
	if( indinfo.zPos == nil ) then indinfo.zPos = 0 end

	if (indinfo.ShowValue == 1) then // Percent
		advhudindicators[eindex].FullText = indinfo.Description.." "..string.format("%.1f", (indinfo.Factor or 0) * 100).."%"
	elseif (indinfo.ShowValue == 2) then // Value
		// Round to up to 2 places
		advhudindicators[eindex].FullText = indinfo.Description.." "..string.format("%g", math.Round((indinfo.Value or 0) * 100) / 100)..""
	end

	// Do any extra processing for certain HUD styles
	// so we aren't calculating this every frame
	surface.SetFont("Default")
	if( advhudindicators[eindex].FullText ) then
		indinfo.BoxWidth = surface.GetTextSize(advhudindicators[eindex].FullText)
	else
		indinfo.BoxWidth = 0
	end

end

// Function to ensure that the respective table index is created before any elements are added or modified
// The HUDIndicatorRegister umsg is *supposed* to arrive (and be processed) before all the others,
// but for some reason (probably net lag or whatever) it isn't (TheApathetic)
local function AdvCheckHITableElement(eindex)
	if (!advhudindicators[eindex]) then
		advhudindicators[eindex] = {}
	end
end

// UserMessage stuff
local function AdvHUDIndicatorRegister()
	local eindex = net.ReadInt(16)
	AdvCheckHITableElement(eindex)

	advhudindicators[eindex].Description = net.ReadString()
	advhudindicators[eindex].ShowValue = net.ReadInt(16)
	local tempstyle = net.ReadInt(16)
	if (!advhudindicators[eindex].Style || advhudindicators[eindex].Style != tempstyle) then
		advhudindicators[eindex].Ready = false // Make sure that everything's ready first before drawing
	end
	advhudindicators[eindex].Style = tempstyle

	if (!advhudindicators[eindex].Factor) then // First-time register
		advhudindicators[eindex].Factor = 0
		advhudindicators[eindex].Value = 0
		advhudindicators[eindex].HideHUD = false
		advhudindicators[eindex].BoxWidth = 100
	end
	AdvHUDFormatDescription( eindex )

	//--Position method tacked on the end of the end -Moggie100--//
	advhudindicators[eindex].positionMethod = net.ReadInt(16)

	//--Depending on which input mode we're in, we'll get differing input here...--//
	if( net.ReadInt(16) == 1 ) then
		//--Start XYZ Position--//
		advhudindicators[eindex].xPos = net.ReadFloat()
		advhudindicators[eindex].yPos = net.ReadFloat()
		advhudindicators[eindex].zPos = net.ReadFloat()

		//--Start XYZ Position--//
		advhudindicators[eindex].xEnd = net.ReadFloat()
		advhudindicators[eindex].yEnd = net.ReadFloat()
		advhudindicators[eindex].zEnd = net.ReadFloat()

		advhudindicators[eindex].useWorldCoords = 1
	else
		//--Position data tacked on the end.--//
		advhudindicators[eindex].xPos = net.ReadFloat()
		advhudindicators[eindex].yPos = net.ReadFloat()

		//--End XY Position--//
		advhudindicators[eindex].xEnd = net.ReadFloat()
		advhudindicators[eindex].yEnd = net.ReadFloat()
	end

end
net.Receive("AdvHUDIndicatorRegister", AdvHUDIndicatorRegister)

local function AdvHUDIndicatorUnRegister()
	local eindex = net.ReadInt(16)
	advhudindicators[eindex] = nil
end
net.Receive("AdvHUDIndicatorUnRegister", AdvHUDIndicatorUnRegister)

local function AdvHUDIndicatorFactor()
	local eindex = net.ReadInt(16)
	AdvCheckHITableElement(eindex)

	advhudindicators[eindex].Factor = net.ReadFloat()
	advhudindicators[eindex].Value = net.ReadFloat()
	AdvHUDFormatDescription( eindex )
end
net.Receive("AdvHUDIndicatorFactor", AdvHUDIndicatorFactor)

local function AdvHUDIndicatorHideHUD()
	local eindex = net.ReadInt(16)
	AdvCheckHITableElement(eindex)

	advhudindicators[eindex].HideHUD = net.ReadBool()
end
net.Receive("AdvHUDIndicatorHideHUD", AdvHUDIndicatorHideHUD)

//--Forces the HUD data to be updated -Moggie100
local function AdvHUDIndicatorUpdatePosition()
	//--Get the table index
	local eindex = net.ReadInt(16)

	//--Ensure it exists and is ready to use
	AdvCheckHITableElement(eindex)

	//--Update the data for this indicator
	advhudindicators[eindex].xPos = net.ReadFloat()
	advhudindicators[eindex].yPos = net.ReadFloat()
	advhudindicators[eindex].positionMethod = net.ReadInt(16)
	advhudindicators[eindex].useWorldCoords = 0
end
net.Receive("AdvHUDIndicatorUpdatePosition", AdvHUDIndicatorUpdatePosition)




//--Forces the HUD data to be updated -Moggie100
local function AdvHUDIndicatorUpdatePositionTwo()
	//--Get the table index
	local eindex = net.ReadInt(16)

	//--Ensure it exists and is ready to use
	AdvCheckHITableElement(eindex)

	//--Update the data for this indicator
	advhudindicators[eindex].xEnd = net.ReadFloat()
	advhudindicators[eindex].yEnd = net.ReadFloat()
	advhudindicators[eindex].positionMethod = net.ReadInt(16)
	advhudindicators[eindex].useWorldCoords = 0
end
net.Receive("AdvHUDIndicatorUpdatePositionTwo", AdvHUDIndicatorUpdatePositionTwo)



//--BETA BETA BETA BETA BETA--//
//--String data to set the FullText variable to!--//
//--May just explode in everyone's faces!--//
local function AdvHUDIndicator_UpdateSTRING()
	//--Get the table index
	local eindex = net.ReadInt(16)

	//--Ensure it exists and is ready to use
	AdvCheckHITableElement(eindex)

	//--Update the data for this indicator
	advhudindicators[eindex].Description = net.ReadString()
end
net.Receive("AdvHUDIndicator_STRING", AdvHUDIndicator_UpdateSTRING)





//--Forces the HUD data to be updated from 3D position data -Moggie100
local function AdvHUDIndicatorUpdate3DPosition()
	//--Get the table index
	local eindex = net.ReadInt(16)

	//--Ensure it exists and is ready to use
	AdvCheckHITableElement(eindex)

	//--Update the data for this indicator
	advhudindicators[eindex].xPos = net.ReadFloat()
	advhudindicators[eindex].yPos = net.ReadFloat()
	advhudindicators[eindex].zPos = net.ReadFloat()
	advhudindicators[eindex].useWorldCoords = 1
end
net.Receive("AdvHUDIndicatorUpdate3DPosition", AdvHUDIndicatorUpdate3DPosition)


//--Forces the HUD data to be updated from 3D position data -Moggie100
local function AdvHUDIndicatorUpdate3DPositionTwo()
	//--Get the table index
	local eindex = net.ReadInt(16)

	//--Ensure it exists and is ready to use
	AdvCheckHITableElement(eindex)

	//--Update the data for this indicator
	advhudindicators[eindex].xEnd = net.ReadFloat()
	advhudindicators[eindex].yEnd = net.ReadFloat()
	advhudindicators[eindex].zEnd = net.ReadFloat()
	advhudindicators[eindex].useWorldCoords = 1
end
net.Receive("AdvHUDIndicatorUpdate3DPositionTwo", AdvHUDIndicatorUpdate3DPositionTwo)



//-- Seeing as this is the only function to set up colours, I'm calling it on a creation/update event even if its not this
//-- indicator type. -Moggie100
local function AdvHUDIndicatorStylePercent()
	local eindex = net.ReadInt(16)
	local ainfo = string.Explode("|", net.ReadString())
	local binfo = string.Explode("|", net.ReadString())
	AdvCheckHITableElement(eindex)

	advhudindicators[eindex].AColor = { r = ainfo[1], g = ainfo[2], b = ainfo[3]}
	advhudindicators[eindex].BColor = { r = binfo[1], g = binfo[2], b = binfo[3]}
end
net.Receive("AdvHUDIndicatorStylePercent", AdvHUDIndicatorStylePercent)

local function AdvHUDIndicatorStyleFullCircle()
	local eindex = net.ReadInt(16)
	AdvCheckHITableElement(eindex)

	advhudindicators[eindex].FullCircleAngle = net.ReadFloat()
	AdvHUDFormatDescription( eindex ) // So the gauge updates with FullCircleAngle factored in
end
net.Receive("AdvHUDIndicatorStyleFullCircle", AdvHUDIndicatorStyleFullCircle)





//-- EXTENDED I/O UMSG HOOKS --//
local function AdvHUDIndicator_EXIO()
	local eindex = net.ReadInt(16)
	AdvCheckHITableElement(eindex)

	local key = net.ReadInt(16);
	local value = net.ReadFloat();

	if( key == 1 ) then								//-- SIZE update --//
		advhudindicators[eindex].exio_size = value
	elseif( key == 2 ) then							//-- LBrace update --//
		advhudindicators[eindex].exio_lbrace = value
	elseif( key == 3 ) then							//-- RBrace update --//
		advhudindicators[eindex].exio_rbrace = value
	elseif( key == 4 ) then							//-- Width update --//
		advhudindicators[eindex].exio_width = value
	elseif( key == 5 ) then							//-- Height update --//
		advhudindicators[eindex].exio_height = value
	elseif( key == 6 ) then							//-- Height update --//
		advhudindicators[eindex].exio_x = value
	elseif( key == 7 ) then							//-- Height update --//
		advhudindicators[eindex].exio_y = value
	end

	//--Msg("[II] Updated EXIO value index=" ..key.. " value=" ..value.. "\n")

end
net.Receive("AdvHUDIndicator_EXIO", AdvHUDIndicator_EXIO)







// Check for updates every 1/50 seconds
local function AdvHUDIndicatorCheck()
	if (CurTime() < nextupdate) then return end

	nextupdate = CurTime() + 0.02

	// Now check readiness
	for eindex,indinfo in pairs(advhudindicators) do

		//-- Force a description update --//
		AdvHUDFormatDescription(eindex)

		//-- NOW check readiness --//
		if (!indinfo.Ready) then
			advhudindicators[eindex].Ready = true // Don't need to do any additional checks
		end
	end
end
hook.Add("Think", "WireAdvHUDIndicatorCVarCheck", AdvHUDIndicatorCheck)
