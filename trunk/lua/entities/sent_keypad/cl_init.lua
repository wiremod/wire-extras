include('shared.lua')

local X = -50
local Y = -100
local W = 100
local H = 200

local KeyPos = {
	{X+5   , Y+100  , 25, 25, -2.2, 3.45,  1.3 ,  0  }, -- 1
	{X+37.5, Y+100  , 25, 25, -0.6, 1.85,  1.3 ,  0  }, -- 2
	{X+70  , Y+100  , 25, 25,  1.0, 0.25,  1.3 ,  0  }, -- 3
	
	{X+5   , Y+132.5, 25, 25, -2.2, 3.45,  2.9 , -1.6}, -- 4
	{X+37.5, Y+132.5, 25, 25, -0.6, 1.85,  2.9 , -1.6}, -- 5
	{X+70  , Y+132.5, 25, 25,  1.0, 0.25,  2.9 , -1.6}, -- 6
	
	{X+5   , Y+165  , 25, 25, -2.2, 3.45,  4.55, -3.3}, -- 7
	{X+37.5, Y+165  , 25, 25, -0.6, 1.85,  4.55, -3.3}, -- 8
	{X+70  , Y+165  , 25, 25,  1.0, 0.25,  4.55, -3.3}, -- 9
	
	{X+5   , Y+ 67.5, 40, 25, -2.2, 4.25, -0.3 ,  1.6}, -- abort
	{X+55  , Y+ 67.5, 40, 25,  0.3, 1.65, -0.3 ,  1.6}, -- ok
}

surface.CreateFont( "Trebuchet34", {
	font 		= "Trebuchet",
	size 		= 34,
	weight 		= 400,
	antialias 	= true,
	additive 	= false} )
surface.CreateFont( "Trebuchet24AA", {
	font 		= "Trebuchet",
	size 		= 24,
	weight 		= 400,
	antialias 	= true,
	additive 	= false} )

local highlight_key, highlight_until
function ENT:Draw()
	
	self:DrawModel()
	local Ply = LocalPlayer()
	
	local Dist = (Ply:GetShootPos() - self:GetPos()):Length()
	if (Dist > 750) then return end
	
	local pos = self:GetPos() + (self:GetForward() * 1.1)
	local ang = self:GetAngles()
	local rot = Vector(-90, 90, 0)
	
	ang:RotateAroundAxis(ang:Right(), 	rot.x)
	ang:RotateAroundAxis(ang:Up(), 		rot.y)
	ang:RotateAroundAxis(ang:Forward(), rot.z)
	
	cam.Start3D2D(pos, ang, 0.05)
		local trace = Ply:GetEyeTrace()
		
		local pos = self:WorldToLocal(trace.HitPos)
		local Num = self:GetNetworkedInt("keypad_num")
		local Access = self:GetNetworkedBool("keypad_access")
		local ShowAccess = self:GetNetworkedBool("keypad_showaccess")
		local Secure = self:GetNetworkedBool("keypad_secure")
		
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(X-5, Y-5, W+10, H+10)
		
		surface.SetDrawColor(50, 75, 50, 255)
		surface.DrawRect(X+5, Y+5, 90, 50)
		
		for k,v in pairs(KeyPos) do
			local text = k
			local textx = v[1] + 9
			local texty = v[2] + 4
			local x = (pos.y - v[5]) / (v[5] + v[6])
			local y = 1 - (pos.z + v[7]) / (v[7] + v[8])
			local highlight_current_key = highlight_key == k and highlight_until >= CurTime()
			
			if (k == 10) then
				text = "ABORT"
				textx = v[1] + 2
				texty = v[2] + 4
				surface.SetDrawColor(150, 25, 25, 255)
			elseif (k == 11) then
				text = "OK"
				textx = v[1] + 12
				texty = v[2] + 5
				surface.SetDrawColor(25, 150, 25, 255)
			else
				surface.SetDrawColor(150, 150, 150, 255)
			end
			
			if highlight_current_key or (trace.Entity == self and x >= 0 and y >= 0 and x <= 1 and y <= 1) then
				if (k <= 9) then
					surface.SetDrawColor(200, 200, 200, 255)
				elseif (k == 10) then
					surface.SetDrawColor(200, 50, 50, 255)
				elseif (k == 11) then
					surface.SetDrawColor(50, 200, 50, 255)
				end
				
				if Ply:KeyDown(IN_USE) and not Ply.KeyOnce and not highlight_current_key then
					if (k <= 9) then
						Ply:ConCommand("gmod_keypad "..self:EntIndex().." "..k.."\n")
					elseif (k == 10) then
						Ply:ConCommand("gmod_keypad "..self:EntIndex().." reset\n")
					elseif (k == 11) then
						Ply:ConCommand("gmod_keypad "..self:EntIndex().." accept\n")
					end
					Ply.KeyOnce = true
				end
			end
			surface.DrawRect(v[1], v[2], v[3], v[4])
			draw.DrawText(text, "Trebuchet18", textx, texty, Color(0, 0, 0, 255))
		end
		
		if (Num != 0) and not (ShowAccess) then
			if (Secure) then
				local Text = string.rep("*", string.len(Num))
				draw.DrawText(Text, "Trebuchet34", X+17, Y+10, Color(255, 255, 255, 255))
			else
				draw.DrawText(Num, "Trebuchet34", X+17, Y+10, Color(255, 255, 255, 255))
			end
		elseif (Access) and (ShowAccess) then
			draw.DrawText("ACCESS","Trebuchet24AA", X+17, Y+7, Color(0, 255, 0, 255))
			draw.DrawText("GRANTED","Trebuchet24AA", X+7, Y+27, Color(0, 255, 0, 255))
		elseif not (Access) and (ShowAccess) then
			draw.DrawText("ACCESS","Trebuchet24", X+17, Y+7, Color(255, 0, 0, 255))
			draw.DrawText("DENIED","Trebuchet24", X+19, Y+27, Color(255, 0, 0, 255))
		end
		
	cam.End3D2D()
	
end

hook.Add("KeyRelease", "Keypad_KeyReleased", function(Ply, key)
	Ply.KeyOnce = false
end)

local binds = {
	-- ["bind"] = { "argument for gmod_keypad", key_index },
	["+gm_special 1" ] = { "1"     , 1  },
	["+gm_special 2" ] = { "2"     , 2  },
	["+gm_special 3" ] = { "3"     , 3  }, 
	["+gm_special 4" ] = { "4"     , 4  },
	["+gm_special 5" ] = { "5"     , 5  },
	["+gm_special 6" ] = { "6"     , 6  },
	["+gm_special 7" ] = { "7"     , 7  },
	["+gm_special 8" ] = { "8"     , 8  },
	["+gm_special 9" ] = { "9"     , 9  },
	["+gm_special 11"] = { "accept", 11 },
	["+gm_special 12"] = { "reset" , 10 },
}

hook.Add("PlayerBindPress", "keypad_PlayerBindPress", function(ply, bind, pressed)
	if not pressed then return end
	local command = binds[bind]
	if not command then return end
	
	local trace = ply:GetEyeTraceNoCursor()
	local ent = trace.Entity
	if not IsValid(ent) then return end
	
	if ent:GetClass() ~= "sent_keypad" and ent:GetClass() ~= "sent_keypad_wire" then return end
	
	ply:ConCommand("gmod_keypad "..ent:EntIndex().." "..command[1].."\n")
	highlight_key, highlight_until = command[2], CurTime()+0.5
	return true
end)
