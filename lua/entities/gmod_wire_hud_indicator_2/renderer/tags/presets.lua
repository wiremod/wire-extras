---------------------------------
-- Preset HML tags for HML 1.0 --
---------------------------------
--
-- DO NOT EDIT!
--
-- Put custom tag definitions in lua files in this DIR instead!
-- Moggie100
--
--
-- Note: These should always return their children's draw context, or a string-type error message.
--       If they have NO children, then return their own draw context, followed by 'false' as a second arg


HMLRenderer.coreTags["marker"] = function ( self )
	local size = 20
	local markerType = "normal"
	local position	=	{ x=10, y=10 }
	local fColor, bColor
	local txt = ""
	
	-- Pick out the coordinates
	if( self.position ) then
		position.visible = true
		local buffer =  HUD_System.eval:Calc( self.position, { x=self.xOffset, y=self.yOffset, w=self.width, h=self.height } )
		
		if( buffer ) then
			if( buffer.value[3] ) then
				position = Vector( buffer.value[1].value, buffer.value[2].value, buffer.value[3].value ):ToScreen()
			else
				position.x = self.xOffset + buffer.value[1].value
				position.y = self.yOffset + buffer.value[2].value
			end
		end
		
	elseif( self.pos ) then
		position.visible = true
		local buffer =  HUD_System.eval:Calc( self.pos, { x=self.xOffset, y=self.yOffset, w=self.width, h=self.height } )
		
		if( buffer and buffer.value ) then
			if( buffer.value[3] ) then
				position = Vector( buffer.value[1].value, buffer.value[2].value, buffer.value[3].value ):ToScreen()
			else
				position.x = self.xOffset + buffer.value[1].value
				position.y = self.yOffset + buffer.value[2].value
			end
		end
	end


	-- Normal Marker (standard crosshair) --
	if( markerType == "normal" ) then
		surface.SetDrawColor(fColor.r, fColor.g, fColor.b, fColor.a)
		surface.DrawLine( position.x-size, position.y, position.x+size, position.y )
		surface.DrawLine( position.x, position.y-size, position.x, position.y+size )


	elseif( markerType == "boxed" ) then

		--Draw a background rectangle
		surface.SetDrawColor(bColor.r, bColor.g, bColor.b, bColor.a)
		surface.DrawRect(position.x-size, position.y-size, size*2, size*2)


		--Set the foreground color, and draw the bounding lines
		surface.SetDrawColor(fColor.r, fColor.g, fColor.b, fColor.a)

		surface.DrawLine(position.x-size, position.y-size, position.x-size, position.y-size+15)
		surface.DrawLine(position.x-size, position.y-size, position.x-size+15, position.y-size)

		surface.DrawLine(position.x+size, position.y-size, position.x+size, position.y-size+15)
		surface.DrawLine(position.x+size, position.y-size, position.x+size-15, position.y-size)

		surface.DrawLine(position.x-size, position.y+size, position.x-size, position.y+size-15)
		surface.DrawLine(position.x-size, position.y+size, position.x-size+15, position.y+size)

		surface.DrawLine(position.x+size, position.y+size, position.x+size, position.y+size-15)
		surface.DrawLine(position.x+size, position.y+size, position.x+size-15, position.y+size)

		if( txt ~= "" ) then
			surface.DrawLine( position.x+size, position.y+size, position.x+size+20, position.y+size+20 )
			draw.WordBox(8, position.x+size+20, position.y+size+12, txt, "Default", Color(50,255,50, 160), Color(0,0,0, 255) )
		end

	else
		HMLWarning("Unknown or invalid marker type! (" ..markerType.. ")")
	end


	return {}, false
end
