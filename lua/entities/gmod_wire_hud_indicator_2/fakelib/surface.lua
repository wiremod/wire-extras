surface = {
	textureID = 0,
	width = 1024,
	height = 768,
	texture = {
		size = 25
	}
}

function surface.CreateFont() print( "$surface.CreateFont$" ) end

function surface.DrawLine( startX, startY, endX, endY)
	print("[FAKE]", "surface.DrawLine( " ..tostring(startX).. ", " ..tostring(startY).. ", " ..tostring(endX).. ", " ..tostring(endY).. " )")
end

function surface.DrawOutlinedRect() print("$surface.DrawOutlinedRect$") end

function surface.DrawPoly() print("$surface.DrawPoly$") end

function surface.DrawRect( x, y, w, h )
	print("[FAKE]","surface.DrawRect( " ..tostring(x).. ", " ..tostring(y).. ", " ..tostring(w).. ", " ..tostring(h).. " )")
end

function surface.DrawText() print("$surface.DrawText$") end

function surface.DrawTexturedRect() print("$surface.DrawTexturedRect$") end

function surface.DrawTexturedRectRotated() print("$surface.DrawTexturedRectRotated$") end

function surface.GetHUDTexture()
	print("[FAKE]", "surface.GetHUDTexture() = 0")
	return 0
end

function surface.GetTextSize()
	print("[FAKE]", "surface.GetTextSize() = 25")
	return 25
end

function surface.GetTextureID()
	print("[FAKE]", "surface.GetTextureID() = " ..tostring(surface.textureID))
	return surface.textureID
end

function surface.GetTextureSize()
	print("[FAKE]", "surface.GetTextureSize() = " ..tostring(surface.texture.size) )
	return surface.texture.size
end

function surface.PlaySound() print("$surface.PlaySound$") end

function surface.ScreenHeight()
	print("[FAKE]", "surface.Screenheight() = " ..tostring(surface.height) )
	return surface.height
end

function surface.ScreenWidth()
	print("[FAKE]", "surface.ScreenWidth() = " ..tostring(surface.width) )
	return surface.width
end

function surface.SetDrawColor( r, g, b, a )
	print("[FAKE]", "surface.SetDrawColor( " ..tostring(r).. ", " ..tostring(g).. ", " ..tostring(b).. ", " ..tostring(a).. " )" )
end

function surface.SetFont() print("$surface.SetFont$") end

function surface.SetMaterial() print("$surface.SetMaterial$") end

function surface.SetTextColor() print("$surface.SetTextColor$") end

function surface.SetTextPos() print("$surface.SetTextPos$") end

function surface.SetTexture( newTex )
	print("[FAKE]", "surface.SetTexture( " ..tostring(newTex).. ")" )
	surface.textureID = newTex
end
