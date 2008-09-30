
include('shared.lua')

ENT.RenderGroup 		= RENDERGROUP_BOTH

local advhudindicators = {}
// Default HUD x/y
local hudx = 0
local hudy = 0
local nextupdate = 0
local animation_frame = 0

// Text Height Constant
local dtextheight = draw.GetFontHeight("Default")

// So we don't need to calculate this every frame w/ Percent Bar style
local pbarheight = dtextheight + 16

// Y Offset constants
local offsety = {32, 32, 32, 92 + dtextheight, 60 + dtextheight}

// Texture IDs for Full/Semi-Circle styles
local fullcircletexid = surface.GetTextureID("hudindicator/hi_fullcircle")
local semicircletexid = surface.GetTextureID("hudindicator/hi_semicircle")

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
	return (ply != self:GetPlayer() && !self.Entity:GetNetworkedBool(plyuid))
end

// Used by STool for unregister control panel
// Only allowed to unregister HUD Indicators that aren't yours
// and for those that aren't pod-only registers
function AdvHUDIndicator_GetCurrentRegistered()
	local registered = {}
	for eindex,_ in pairs(advhudindicators) do
		local ent = ents.GetByIndex(eindex)
		if (ent && ent:IsValid()) then
			if (ent:CheckClientRegister()) then
				local entry = {}
				entry.EIndex = eindex
				entry.Description = advhudindicators[eindex].Description
				table.insert(registered, entry)
			end
		end
	end
	
	return registered
end

local function isInsideZone( x, y, minX, minY, maxX, maxY )

	if( x > minX && x < maxX ) then
		if( y > minY && y < maxY ) then
			return true
		end
	end
	
	return false
end

local function DrawAdvHUDIndicators()

	if (!LocalPlayer():Alive()) then return end
	
	local screenWidth = surface.ScreenWidth()
	local screenHeight = surface.ScreenHeight()
	
	local halfScreenWidth = screenWidth/2
	local halfScreenHeight = screenHeight/2
	
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
						//--Msg( "Position Method: " ..indinfo.positionMethod.. "\n" )
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
					
					local alphaVal = 160
					if( indinfo.alpha != nil ) then
						alphaVal = indinfo.alpha
					end

					//-- Access the colors for this indicator, and update the local variables --//
					local AColor = indinfo.AColor
					local BColor = indinfo.BColor

					//-- Basic --//
					if (indinfo.Style == 0) then
						//--draw.WordBox(8, xPos, yPos, txt, "Default", Color(50, 50, 75, 192), Color(255, 255, 255, 255))
						
						draw.DrawText( txt, "ScoreboardText", xPos, yPos, indinfo.DisplayColor, indinfo.TextColor )
					
					
					//-- Boxed Text (rounded corners...) --//
					elseif (indinfo.Style == 1) then
												
						//draw.WordBox(8, xPos, yPos, txt, "Default", indinfo.DisplayColor, indinfo.TextColor)
						draw.WordBox(8, xPos, yPos, txt, "Default", Color(BColor.r, BColor.g, BColor.b, BColor.a), Color(AColor.r, AColor.g, AColor.b, AColor.a))
					
					
					//-- Percent Bar (Style 1) --//
					elseif (indinfo.Style == 10) then
					
						local pbarwidth = 200
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
					
					//--Animating target marker (triangular)--//
					//--Offsets 100 from the normal indicators, so I have room to group types--//
					elseif( indinfo.Style == 100 ) then
					
						local frame = animation_frame*3.6
						
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
					
					//-----------------------------------------------------------------------------------------------//
					//-- [Extended I/O] [Extended I/O] [Extended I/O] [Extended I/O] [Extended I/O] [Extended I/O] --//
					//-----------------------------------------------------------------------------------------------//
					//-- These inputs have other IO functions on the SENT, so can access the exio values           --//
					//-----------------------------------------------------------------------------------------------//
					if( indinfo.Style > 999 ) then
					
						//-- Targetting Rectangle --//
						if (indinfo.Style == 1000) then
						
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
							if( indinfo.exio_lbrace != nil ) then
								if( indinfo.exio_lbrace > 0 ) then
									surface.DrawLine( xPos-30, yPos-10, xPos-30, yPos+10 )
									surface.DrawLine( xPos-30, yPos-10, xPos-25, yPos-10 )
									surface.DrawLine( xPos-30, yPos+10, xPos-25, yPos+10 )
								end
							end
							
							//-- Right Brace --//
							if( indinfo.exio_rbrace != nil ) then
								if( indinfo.exio_rbrace > 0 ) then
									surface.DrawLine( xPos+30, yPos-10, xPos+30, yPos+10 )
									surface.DrawLine( xPos+30, yPos-10, xPos+25, yPos-10 )
									surface.DrawLine( xPos+30, yPos+10, xPos+25, yPos+10 )
								end
							end
						end
							
					end
					
				end
				
			else
				// Clear this from the table so we don't check again
				advhudindicators[index] = nil
			end
		end
	end
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
		advhudindicators[eindex].FullText = indinfo.Description.." "..string.format("%.1f", ((indinfo.Factor or 0) * 100)).."%"
	elseif (indinfo.ShowValue == 2) then // Value
		// Round to up to 2 places
		advhudindicators[eindex].FullText = indinfo.Description.." "..string.format("%g", math.Round((indinfo.Value or 0) * 100) / 100)..""
	end
	
	// Do any extra processing for certain HUD styles
	// so we aren't calculating this every frame
	surface.SetFont("Default")
	indinfo.BoxWidth = surface.GetTextSize(advhudindicators[eindex].FullText)
	
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
local function AdvHUDIndicatorRegister( um )
	local eindex = um:ReadShort()
	AdvCheckHITableElement(eindex)
	
	advhudindicators[eindex].Description = um:ReadString()
	advhudindicators[eindex].ShowValue = um:ReadShort()
	local tempstyle = um:ReadShort()
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
	
	
	//Position data tacked on the end. -Moggie100
	advhudindicators[eindex].xPos = um:ReadShort()
	advhudindicators[eindex].yPos = um:ReadShort()
	
	//Position method tacked on the end of the end -Moggie100
	advhudindicators[eindex].positionMethod = um:ReadShort()
	
end
usermessage.Hook("AdvHUDIndicatorRegister", AdvHUDIndicatorRegister)

local function AdvHUDIndicatorUnRegister( um )
	local eindex = um:ReadShort()
	advhudindicators[eindex] = nil
end
usermessage.Hook("AdvHUDIndicatorUnRegister", AdvHUDIndicatorUnRegister)

local function AdvHUDIndicatorFactor( um )
	local eindex = um:ReadShort()
	AdvCheckHITableElement(eindex)
	
	advhudindicators[eindex].Factor = um:ReadFloat()
	advhudindicators[eindex].Value = um:ReadFloat()
	AdvHUDFormatDescription( eindex )
end
usermessage.Hook("AdvHUDIndicatorFactor", AdvHUDIndicatorFactor)

local function AdvHUDIndicatorHideHUD( um )
	local eindex = um:ReadShort()
	AdvCheckHITableElement(eindex)
	
	advhudindicators[eindex].HideHUD = um:ReadBool()
end
usermessage.Hook("AdvHUDIndicatorHideHUD", AdvHUDIndicatorHideHUD)


//--Forces the HUD data to be updated for angles
local function AdvHUDIndicatorUpdateAngles( um )
	//--Get the table index
	local eindex = um:ReadShort()
	
	//--Ensure it exists and is ready to use
	AdvCheckHITableElement(eindex)
	
	//--Update the data for this indicator
	advhudindicators[eindex].pitch = um:ReadFloat()
	advhudindicators[eindex].yaw = um:ReadFloat()
	advhudindicators[eindex].roll = um:ReadFloat()
end
usermessage.Hook("AdvHUDIndicatorUpdateAngles", AdvHUDIndicatorUpdateAngles)



//--Forces the HUD data to be updated -Moggie100
local function AdvHUDIndicatorUpdatePosition( um )
	//--Get the table index
	local eindex = um:ReadShort()
	
	//--Ensure it exists and is ready to use
	AdvCheckHITableElement(eindex)
	
	//--Update the data for this indicator
	advhudindicators[eindex].xPos = um:ReadFloat()
	advhudindicators[eindex].yPos = um:ReadFloat()
	advhudindicators[eindex].positionMethod = um:ReadShort()
	advhudindicators[eindex].useWorldCoords = 0
end
usermessage.Hook("AdvHUDIndicatorUpdatePosition", AdvHUDIndicatorUpdatePosition)




//--Forces the HUD data to be updated -Moggie100
local function AdvHUDIndicatorUpdatePositionTwo( um )
	//--Get the table index
	local eindex = um:ReadShort()
	
	//--Ensure it exists and is ready to use
	AdvCheckHITableElement(eindex)
	
	//--Update the data for this indicator
	advhudindicators[eindex].xEnd = um:ReadFloat()
	advhudindicators[eindex].yEnd = um:ReadFloat()
	advhudindicators[eindex].positionMethod = um:ReadShort()
	advhudindicators[eindex].useWorldCoords = 0
end
usermessage.Hook("AdvHUDIndicatorUpdatePositionTwo", AdvHUDIndicatorUpdatePositionTwo)





//--Forces the HUD data to be updated from 3D position data -Moggie100
local function AdvHUDIndicatorUpdate3DPosition( um )
	//--Get the table index
	local eindex = um:ReadShort()
	
	//--Ensure it exists and is ready to use
	AdvCheckHITableElement(eindex)
	
	//--Update the data for this indicator
	advhudindicators[eindex].xPos = um:ReadFloat()
	advhudindicators[eindex].yPos = um:ReadFloat()
	advhudindicators[eindex].zPos = um:ReadFloat()
	advhudindicators[eindex].useWorldCoords = 1
end
usermessage.Hook("AdvHUDIndicatorUpdate3DPosition", AdvHUDIndicatorUpdate3DPosition)


//--Forces the HUD data to be updated from 3D position data -Moggie100
local function AdvHUDIndicatorUpdate3DPositionTwo( um )
	//--Get the table index
	local eindex = um:ReadShort()
	
	//--Ensure it exists and is ready to use
	AdvCheckHITableElement(eindex)
	
	//--Update the data for this indicator
	advhudindicators[eindex].xEnd = um:ReadFloat()
	advhudindicators[eindex].yEnd = um:ReadFloat()
	advhudindicators[eindex].zEnd = um:ReadFloat()
	advhudindicators[eindex].useWorldCoords = 1
end
usermessage.Hook("AdvHUDIndicatorUpdate3DPositionTwo", AdvHUDIndicatorUpdate3DPositionTwo)



//-- Seeing as this is the only function to set up colours, I'm calling it on a creation/update event even if its not this
//-- indicator type. -Moggie100
local function AdvHUDIndicatorStylePercent( um )
	local eindex = um:ReadShort()
	local ainfo = string.Explode("|", um:ReadString())
	local binfo = string.Explode("|", um:ReadString())
	AdvCheckHITableElement(eindex)
	
	advhudindicators[eindex].AColor = { r = ainfo[1], g = ainfo[2], b = ainfo[3]}
	advhudindicators[eindex].BColor = { r = binfo[1], g = binfo[2], b = binfo[3]}
end
usermessage.Hook("AdvHUDIndicatorStylePercent", AdvHUDIndicatorStylePercent)

local function AdvHUDIndicatorStyleFullCircle( um )
	local eindex = um:ReadShort()
	AdvCheckHITableElement(eindex)
	
	advhudindicators[eindex].FullCircleAngle = um:ReadFloat()
	AdvHUDFormatDescription( eindex ) // So the gauge updates with FullCircleAngle factored in
end
usermessage.Hook("AdvHUDIndicatorStyleFullCircle", AdvHUDIndicatorStyleFullCircle)





//-- EXTENDED I/O UMSG HOOKS --//
local function AdvHUDIndicator_EXIO( um )
	local eindex = um:ReadShort()
	AdvCheckHITableElement(eindex)
	
	local key = um:ReadShort();
	local value = um:ReadFloat();
	
	if( key == 1 ) then								//-- SIZE update --//
		advhudindicators[eindex].exio_size = value
	elseif( key == 2 ) then							//-- LBrace update --//
		advhudindicators[eindex].exio_lbrace = value
	elseif( key == 3 ) then							//-- RBrace update --//
		advhudindicators[eindex].exio_rbrace = value
	end
	
end
usermessage.Hook("AdvHUDIndicator_EXIO", AdvHUDIndicator_EXIO)







// Check for updates every 1/50 seconds
local function AdvHUDIndicatorCheck()
	if (CurTime() < nextupdate) then return end
	
	//--Increment the animation frame, rotate it around 360;
	animation_frame = animation_frame + 1;
	if (animation_frame > 360) then animation_frame = 0 end
	
	nextupdate = CurTime() + 0.02
	// Keep x/y within range (the 50 and 100 are arbitrary and may change)
	hudx = math.Clamp(GetConVarNumber("wire_hudindicator_hudx") or 22, 0, ScrW() - 50)
	hudy = math.Clamp(GetConVarNumber("wire_hudindicator_hudy") or 200, 0, ScrH() - 100)
	
	// Now check readiness
	for eindex,indinfo in pairs(advhudindicators) do
		
		//-- Force a description update --//
		AdvHUDFormatDescription(eindex)
		
		//-- NOW check readiness --//
		if (!indinfo.Ready) then
			if (indinfo.Style == 0) then // Basic
				advhudindicators[eindex].Ready = true // Don't need to do any additional checks
			elseif (indinfo.Style == 1) then // Gradient
				advhudindicators[eindex].Ready = (indinfo.DisplayColor && indinfo.TextColor)
			elseif (indinfo.Style == 2) then // Percent Bar
				advhudindicators[eindex].Ready = (indinfo.BoxWidth && indinfo.W1 && indinfo.W2 && indinfo.AColor && indinfo.BColor)
			elseif (indinfo.Style == 3) then // Full Circle Gauge
				advhudindicators[eindex].Ready = (indinfo.BoxWidth && indinfo.LineX && indinfo.LineY && indinfo.FullCircleAngle)
			elseif (indinfo.Style == 4) then // Semi-Circle Gauge
				advhudindicators[eindex].Ready = (indinfo.BoxWidth && indinfo.LineX && indinfo.LineY)
			end
		end
	end
end
hook.Add("Think", "WireAdvHUDIndicatorCVarCheck", AdvHUDIndicatorCheck)
