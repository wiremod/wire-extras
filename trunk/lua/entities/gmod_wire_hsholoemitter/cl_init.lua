include( "shared.lua" );
// mats
local matbeam = Material( "tripmine_laser" );
local matpoint = Material( "sprites/gmdm_pickups/light" );

// init
function ENT:Initialize( )
	self.Memory = {}

	for i = 0, 2047 do
		self.Memory[i] = 0
	end
end

function HSHoloemitter_DataMsg( um )
	local ent = ents.GetByIndex(um:ReadLong())
	local start = um:ReadLong()
	local len = um:ReadLong()
	
	for i = 0, len-1 do
		ent.Memory[start + i] = um:ReadFloat()
	end
end
usermessage.Hook("hsholoemitter_datamsg", HSHoloemitter_DataMsg)

// calculate point
function ENT:CalculatePixelPoint( pos, emitterPos, fwd, right, up )
	// calculate point
	return emitterPos + ( up * pos.z ) + ( fwd * pos.x ) + ( right * pos.y );
end

function ENT:Think( )
	self:ShowOutput()
end

function ENT:ShowOutput()
	local txt = "High Speed Holoemitter\nNumber of points: " .. self.Memory[4]
	self:SetOverlayText(txt)
end

// draw
function ENT:Draw( )
	// render model
	self.Entity:DrawModel();
	
	// are we rendering?
	if( self.Memory[0] == 0 ) then return; end
	
	// read emitter.
	local emitter = self.Entity:GetNetworkedEntity( "grid" );
	if( !emitter || !emitter:IsValid() ) then return; end
	
	// calculate emitter position.
	local fwd 	= emitter:GetForward();
	local right 	= emitter:GetRight();
	local up 	= emitter:GetUp();
	local pos 	= emitter:GetPos() + up * 64;
	local usegps = emitter:GetNetworkedBool( "UseGPS" )

	// draw beam?
	local drawbeam	= self.Memory[3];
	
	// read point size
	local size	= self.Memory[2];
	local beamsize	= size * 0.25;
	
	// read color
	local r, g, b, a = self.Entity:GetColor();
	local color = Color( r, g, b, a );
	
	self.Entity:SetRenderBounds( Vector()*-8192, Vector()*8192 )	
	
	local num_points = math.Min(self.Memory[4],GetConVarNumber("hsholoemitter_max_points"))
	
	for i = 0, num_points-1 do
	
		local pixelpos
		local pos2 = Vector(self.Memory[i*3 + 5], self.Memory[i*3 + 6], self.Memory[i*3 + 7])
		if (usegps == true) then
			pixelpos = pos2
		else
			pixelpos = self:CalculatePixelPoint( pos2, pos, fwd, right, up );
		end
		
		if( drawbeam != 0) then
			render.SetMaterial( matbeam );
			render.DrawBeam(
				self.Entity:GetPos(),
				pixelpos,
				beamsize,
				0, 1,
				color
			);
		
		end
	
		// draw active point - sprite
		render.SetMaterial( matpoint );
		render.DrawSprite(
			pixelpos,
			size,  size,
			color
		);
	end
	
end

function Player_EyeAngle(ply)
	EyeTrace = ply:GetEyeTrace()
	StartPos = EyeTrace.StartPos
	EndPos = EyeTrace.HitPos
	Distance = StartPos:Distance(EndPos)
	Temp = EndPos - StartPos
	return Temp:Angle()
end

local function HSHoloPressCheck( ply, key )
	if (key == IN_USE) then
		ply_EyeAng = Player_EyeAngle(ply)
		ply_EyeTrace = ply:GetEyeTrace()
		ply_EyePos = ply_EyeTrace.StartPos
		
		emitters = ents.FindByClass("gmod_wire_hsholoemitter")
		if (#emitters > 0) then
			local ShortestDistance = 200
			local LastNum = 0
			local LastEnt = 0
			
			for _,v in ipairs( emitters ) do
				local emitter = v.Entity:GetNetworkedEntity( "grid" );
				if (v.Memory[0]) then
					local fwd = emitter:GetForward();
					local right = emitter:GetRight();
					local up = emitter:GetUp();
					local pos = emitter:GetPos() + (up*64)
					count = v.Memory[4]

					for i = 0, count-1 do
						
						local pos2 = Vector(v.Memory[i*3 + 5], v.Memory[i*3 + 6], v.Memory[i*3 + 7])
						if (v.Entity:GetNetworkedBool( "UseGPS" )) then
							pixelpos = pos2
						else
							pixelpos = v:CalculatePixelPoint( pos2, pos, fwd, right, up );
						end
						ObjPos = Vector(pixelpos.x,pixelpos.y,pixelpos.z)
						AbsDist = ply_EyePos:Distance(ObjPos)
						if (AbsDist <= ShortestDistance) then
							TempPos = ObjPos - ply_EyePos
							AbsAng = TempPos:Angle()
							PitchDiff = math.abs(AbsAng.p - ply_EyeAng.p)
							YawDiff = math.abs(AbsAng.y - ply_EyeAng.y)
							if (YawDiff <= 5 && PitchDiff <= 5) then
								ShortestDistance = AbsDist
								LastNum = i
								LastEnt = v:EntIndex()
							end
						end
					end
				end
			end
			
			if (LastEnt > 0) then
				RunConsoleCommand("HSHoloInteract",LastEnt,LastNum)
			end
		end
	end
end
hook.Add( "KeyPress", "HSHoloPress", HSHoloPressCheck )

