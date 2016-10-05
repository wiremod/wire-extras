draw = {}

function draw.DrawText( value, font, x, y, color, alignment )
	print( "[FAKE]", "draw.DrawText( " .. tostring(value) .. ", " ..tostring(font).. ", " ..tostring(x).. ", " ..tostring(y).. ", " ..tostring(color).. ", " ..tostring(alignment).. " )" )
end
	
function draw.GetFontHeight()
	print( "[FAKE]", "$draw.GetFontHeight$" )
	return 25
end

function draw.NoTexture()
	print( "[FAKE]", "$draw.NoTexture$" )
end

function draw.RoundedBox()
	print( "[FAKE]", "$draw.RoundedBox$" )
end

function draw.SimpleText()
	print( "[FAKE]", "$draw.SimpleText$" )
end

function draw.SimpleTextOutlined()
	print( "[FAKE]", "$draw.SimpleTextOutlined$" )
end

function draw.Text()
	print( "[FAKE]", "$draw.Text$" )
end

function draw.TextShadow()
	print( "[FAKE]", "$draw.TextShadow$" )
end

function draw.TexturedQuad()
	print( "[FAKE]", "$draw.TexturedQuad$" )
end

function draw.WordBox( bordersize, x, y, text, font, color, fontColor )
	print( "[FAKE]", "$draw.WordBox$ - would have printed '".. text .."' at (" ..x.. "x" ..y..")" )
end
