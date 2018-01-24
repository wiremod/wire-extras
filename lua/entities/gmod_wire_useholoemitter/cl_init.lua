include( "shared.lua" );
CreateClientConVar("cl_wire_holoemitter_minfaderate",10,true,false);
// mats
local matbeam = Material( "tripmine_laser" );
local matpoint = Material( "sprites/gmdm_pickups/light" );

// init
function ENT:Initialize( )
	// point list
	self.PointList = {};
	self.LastClear = self:GetNetworkedBool("Clear");
	
	// active point
	self.ActivePoint = Vector( 0, 0, 0 );
	
	// boundry.
	self.RBound = Vector(1024,1024,1024)
end

// calculate point
function ENT:CalculatePixelPoint( pos, emitterPos, fwd, right, up )
	// calculate point
	return emitterPos + ( up * pos.z ) + ( fwd * pos.x ) + ( right * pos.y );
end

// think
function ENT:Think( )
	// read point.
	local point = Vector(
		self:GetNetworkedFloat( "X" ),
		self:GetNetworkedFloat( "Y" ),
		self:GetNetworkedFloat( "Z" )
	);

	lastclear = self:GetNetworkedInt("Clear")
	if(lastclear != self.LastClear) then
		self.PointList = {}
		self.LastClear = lastclear
	end
	
	-- To make it visible across the entire map
	local p = LocalPlayer():GetPos()
	self:SetRenderBoundsWS( p - self.RBound, p + self.RBound )
	
	// did the point differ from active point?
	if( point != self.ActivePoint && self:GetNetworkedBool( "Active" ) ) then
		// fetch color.
		local a = self:GetColor().a;
	
		// store this point inside the point list
		local tempfaderate
		if (game.SinglePlayer()) then
			tempfaderate = math.Clamp( self:GetNetworkedFloat( "FadeRate" ), 0.1, 255 )
		else
			-- Due to a request, in Multiplayer, the people can controle this with a CL side cvar (aVoN)
			local minfaderate = GetConVarNumber("cl_wire_holoemitter_minfaderate") or 10;
			tempfaderate = math.Clamp( self:GetNetworkedFloat( "FadeRate" ),minfaderate, 255 )
		end
		table.insert( self.PointList, { pos = self.ActivePoint, alpha = a, faderate = tempfaderate } );
		
		// store new active point
		self.ActivePoint = point;
		
	end
	
end

// draw
function ENT:Draw( )
	// render model
	self:DrawModel();
	
	// are we rendering?
	if( !self:GetNetworkedBool( "Active" ) ) then return; end
	
	// read emitter.
	local emitter = self:GetNetworkedEntity( "grid" );
	if( !emitter || !emitter:IsValid() ) then return; end
	
	// calculate emitter position.
	local fwd 	= emitter:GetForward();
	local right 	= emitter:GetRight();
	local up 	= emitter:GetUp();
	local pos 	= emitter:GetPos() + up * 64;
	local usegps = emitter:GetNetworkedBool( "UseGPS" )

	// draw beam?
	local drawbeam	= self:GetNetworkedBool( "ShowBeam" );
	local groundbeam	= self:GetNetworkedBool( "GroundBeam" );
	
	// read point size
	local size	= self:GetNetworkedFloat( "PointSize" );
	local beamsize	= size * 0.25;
	
	// read color
	local color = self:GetColor();
	
	// calculate pixel point.
	local pixelpos
	if (usegps == true) then
		pixelpos = self.ActivePoint;
	else
		pixelpos = self:CalculatePixelPoint( self.ActivePoint, pos, fwd, right, up );
	end
	
	// draw active point - beam
	if( drawbeam && groundbeam) then
		render.SetMaterial( matbeam );
		render.DrawBeam(
			self:GetPos(),
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
	
	
	// draw fading points.
	local point, lastpos, i = nil, pixelpos;
	local newlist = {}
	for i = table.getn( self.PointList ), 1, -1 do
		// easy access
		local point = self.PointList[i];

		
		// I'm doing this here, to remove that extra loop in ENT:Think.
		// fade away
		point.alpha = point.alpha - point.faderate * FrameTime();
		
		// die?
		if( point.alpha <= 0 ) then
			table.remove( self.PointList, i );
		else
			table.insert( newlist, { pos = point.pos, alpha = point.alpha, faderate = point.faderate } );
			
			// calculate pixel point.
			local pixelpos
			if (usegps == true) then
				pixelpos = point.pos
			else
				pixelpos = self:CalculatePixelPoint( point.pos, pos, fwd, right, up );
			end
			
			// calculate color.
			local color = Color( r, g, b, point.alpha );
			
			// draw active point - beam
			if( drawbeam ) then
				if (groundbeam) then
					render.SetMaterial( matbeam );
					render.DrawBeam(
						self:GetPos(),
						pixelpos,
						beamsize,
						0, 1,
						color
					);
				end
				render.SetMaterial( matbeam )
				render.DrawBeam(
					lastpos,
					pixelpos,
					beamsize * 2,
					0, 1,
					color
				);
				lastpos = pixelpos;
				
			end
			
			// draw active point - sprite
			render.SetMaterial( matpoint );
			render.DrawSprite(
				pixelpos,
				size, size,
				color
			);
			
		end
		
	end
	self.PointList = newlist
end

function Player_EyeAngle(ply)
	EyeTrace = ply:GetEyeTrace()
	StartPos = EyeTrace.StartPos
	EndPos = EyeTrace.HitPos
	Distance = StartPos:Distance(EndPos)
	Temp = EndPos - StartPos
	return Temp:Angle()
end

local function HoloPressCheck( ply, key )
	if (key == IN_USE) then
		ply_EyeAng = Player_EyeAngle(ply)
		ply_EyeTrace = ply:GetEyeTrace()
		ply_EyePos = ply_EyeTrace.StartPos
		
		emitters = ents.FindByClass("gmod_wire_useholoemitter")
		if (#emitters > 0) then
			local ShortestDistance = 200
			local LastX = 0
			local LastY = 0
			local LastZ = 0
			local LastEnt = 0
			
			for _,v in ipairs( emitters ) do
				local emitter = v.Entity:GetNetworkedEntity( "grid" );
				if (v.Entity:GetNetworkedBool( "Active" )) then
					local fwd = emitter:GetForward();
					local right = emitter:GetRight();
					local up = emitter:GetUp();
					local pos = emitter:GetPos() + (up*64)
					count = table.getn( v.PointList )

					for i = count,1,-1 do
						point = v.PointList[i];
						
						if (v.Entity:GetNetworkedBool( "UseGPS" )) then
							pixelpos = point.pos
						else
							pixelpos = v:CalculatePixelPoint( point.pos, pos, fwd, right, up );
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
								LastX = point.pos.x
								LastY = point.pos.y
								LastZ = point.pos.z
								LastEnt = v:EntIndex()
							end
						end
					end
				end
			end
			
			if (LastEnt > 0) then
				RunConsoleCommand("HoloInteract",LastEnt,LastX,LastY,LastZ)
			end
		end
	end
end
hook.Add( "KeyPress", "HoloPress", HoloPressCheck )
