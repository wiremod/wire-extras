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
	
    if(!ent.Memory) then return; end
    
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
	self:DrawModel();
	
    if(!self.Memory) then return; end
    
	// are we rendering?
	if( self.Memory[0] == 0 ) then return; end
	
	// read emitter.
	local emitter = self:GetNetworkedEntity( "grid" );
	if( !emitter || !emitter:IsValid() ) then return; end
	
	// calculate emitter position.
	local fwd 	= emitter:GetForward();
	local right 	= emitter:GetRight();
	local up 	= emitter:GetUp();
	local pos 	= emitter:GetPos() + up * 64;
	local usegps = emitter:GetNetworkedBool( "UseGPS" )

	// evaluate flags
	local flags = self.Memory[3];
	local drawbeam	    = (flags % 2 == 1)
	usegps = usegps or    (math.floor(flags*0.5) % 2 == 1)
	local perPointColor = (math.floor(flags*0.25) % 2 == 1)
	
	
	// if we dont draw beams, we set the point material before the loop:
	if ( drawbeam == false ) then 
		render.SetMaterial( matpoint );
	end
	
	// read point size
	local size	= self.Memory[2];
	local beamsize	= size * 0.25;
	
	// read color
	local color = self:GetColor();
	
	self:SetRenderBounds( Vector()*-8192, Vector()*8192 )	
	
	local num_points = math.Min(self.Memory[4],GetConVarNumber("hsholoemitter_max_points"))
    if (perPointColor) then
      num_points = math.Min(num_points,291)
    end
	
	// get the size of a point struct
	local cbPointStruct = 3;
	if (perPointColor) then
		cbPointStruct = cbPointStruct + 4
	end
	for i = 0, num_points-1 do
	
		local h = i*cbPointStruct+5
		local pixelpos
		local pos2 = Vector(self.Memory[h], self.Memory[h+1], self.Memory[h+2])
		if (perPointColor == true) then
			color = Color( self.Memory[h+3], self.Memory[h+4], self.Memory[h+5], self.Memory[h+6] ) 
		end
		if (usegps == true) then
			pixelpos = pos2
		else
			pixelpos = self:CalculatePixelPoint( pos2, pos, fwd, right, up );
		end
		
		if( drawbeam == true) then
			render.SetMaterial( matbeam );
			render.DrawBeam(
				self:GetPos(),
				pixelpos,
				beamsize,
				0, 1,
				color
			);
			// no need to set the material again and again if it is not changed:
			render.SetMaterial( matpoint );
		end
	
		// draw active point - sprite
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
					local count = v.Memory[4]
                    
                    local ps = 3
                    if (math.floor(v.Memory[3]*0.25)%2 == 1) then
                      ps = 7
                    end

					for i = 0, count-1 do
						
						local pos2 = Vector(v.Memory[i*ps + 5], v.Memory[i*ps + 6], v.Memory[i*ps + 7])
						if (v.Entity:GetNetworkedBool( "UseGPS" ) or (math.floor(v.Memory[3]*0.5)%2 == 1)) then
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

