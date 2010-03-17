--EGP Lib Element Functions

function EGP.ELEMENT.box(v)
	if v.Ang and v.Ang != 0 then
		return EGP.ELEMENT.boxangle(v)
	end
	if v.material then
		surface.DrawTexturedRect(v.X,v.Y,v.W,v.H)
	else
		surface.DrawRect(v.X,v.Y,v.W,v.H)
	end
end

function EGP.ELEMENT.boxangle(v)
	surface.DrawTexturedRectRotated(v.X,v.Y,v.W,v.H,v.Ang)
end

function EGP.ELEMENT.boxoutline(v)
	surface.DrawOutlinedRect(v.X,v.Y,v.W,v.H)
end

function EGP.ELEMENT.text(v)
	surface.SetTextColor(v.R,v.G,v.B,v.A)
	local fsize = math.floor(math.Clamp(v.fsize,4,200))
	local fname = EGP.ValidFonts[v.fid]
	local ffname = "WireGPU_ConsoleFont"
	
	if fname then
		ffname = "WireEGP_"..fsize.."_"..fname
		if not EGP.CachedFonts[ffname] then
			surface.CreateFont(fname,fsize,800,true,false,ffname)
			EGP.CachedFonts[ffname] = true
		end
	end
	
	surface.SetFont(ffname)
	local textwidth, textheight = surface.GetTextSize(v.text)
	local falign = v.falign
	local halign, valign = falign%10, math.floor(falign/10)
				
	local X = v.X - (textwidth * (halign/2))
	local Y = v.Y - (textheight * (valign/2))
	surface.SetTextPos(X,Y)
	surface.DrawText(v.text)
end

function EGP.ELEMENT.text1(v,ent)
	surface.SetTextColor(v.R,v.G,v.B,v.A)
	local fsize = math.floor(math.Clamp(v.fsize,4,200))
	local fname = EGP.ValidFonts[v.fid]
	local ffname = "WireGPU_ConsoleFont"
	if fname then
		ffname = "WireEGP_"..fsize.."_"..fname
		if not EGP.CachedFonts[ffname] then
			surface.CreateFont(fname,fsize,800,true,false,ffname)
			EGP.CachedFonts[ffname] = true
		end
	end
	surface.SetFont(ffname)
	local falign = v.falign
	local halign, valign = falign%10, math.floor(falign/10)
		
	ent.layouter = MakeTextScreenLayouter()
	ent.layouter:DrawText(v.text, v.X, v.Y, v.W, v.H, halign, valign)
	-- vertical alignment is not (yet) supported, but i'll pass it anyway...
	--Arg Tomy Y pass it if its usless? I'll allow it for this recode if you support it later!
end

function EGP.ELEMENT.line(v)
	surface.DrawLine(v.X,v.Y,v.X1,v.Y1)
end

function EGP.ELEMENT.circle(v)
	local h = v.W / 2
	local w  = v.H / 2
	local x = v.X
	local y = v.Y
	local numsides = 36
	local astart = 0
	local aend = 7
	local astep = (aend-astart) / numsides
										
	for i=1,numsides do
		local vertices = {
			{
				x = x + w*math.sin(astart+astep*(i+0)),
				y = y + h*math.cos(astart+astep*(i+0)),
				u = 0,
				v = 0,
			},
			{
				x = x,
				y = y,
				u = 0,
				v = 0,
			},
			{
				x = x + w*math.sin(astart+astep*(i+1)),
				y = y + h*math.cos(astart+astep*(i+1)),
				u = 0,
				v = 0,
			},
		}
						
		surface.SetDrawColor(v.R,v.G,v.B,v.A)
		surface.DrawPoly(vertices)
	end					
end

function EGP.ELEMENT.triangle(v)
	local vertices = {
		{
			x = v.X,
			y = v.Y,
			u = 0,
			v = 0,
		},
		{
			x = v.X1,
			y = v.Y1,
			u = 0,
			v = 0,
		},
		{
			x = v.X2,
			y = v.Y2,
			u = 0,
			v = 0,
		},
	}
					
	surface.SetDrawColor(v.R,v.G,v.B,v.A)
	surface.DrawPoly(vertices)
end

function EGP.ELEMENT.poly(v)
	surface.SetDrawColor(v.R,v.G,v.B,v.A)
	surface.DrawPoly(v.vertices)
end

function EGP.ELEMENT.E(v)
	--EMPTY YAY!
end

				--[[ I HAZ NO PLACE TO HIDE THIS AND YOU DIDNT SEE IT!
				elseif v.image == "camera" then
					local CamData = {}
					CamData.angles = Angle( v.angle,v.extra,v.sides )
					CamData.origin = Vector(v.R,v.G,v.B)
					CamData.x = v.X
					CamData.y = v.Y
					CamData.w = v.W
					CamData.h = v.H
					CamData.set = true
					--CamData.fov = 0
					render.RenderView( CamData )
					--shhhhhh you never saw this.
					--Msg("EGP_DEBUG: Camera " .. tostring(v.R) .. " " .. tostring(v.G) .. " " .. tostring(v.B) .."\n")
					--Debug {REMOVE ME}
				]]--NO REALY IT DOSNT EXIST :(


