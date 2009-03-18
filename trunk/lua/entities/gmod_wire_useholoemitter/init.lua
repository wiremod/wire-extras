AddCSLuaFile( "cl_init.lua" );
AddCSLuaFile( "shared.lua" );
include( "shared.lua" );

// wire debug and overlay crap.
ENT.WireDebugName	= "Interactable Holographic Emitter"
ENT.OverlayDelay 	= 0;
ENT.LastClear           = 0;

// init.
function ENT:Initialize( )
	// set model
	util.PrecacheModel( "models/jaanus/wiretool/wiretool_range.mdl" );
	self.Entity:SetModel( "models/jaanus/wiretool/wiretool_range.mdl" );
	
	// setup physics
	self.Entity:PhysicsInit( SOLID_VPHYSICS );
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS );
	self.Entity:SetSolid( SOLID_VPHYSICS );
	
	// vars
	self.Entity:SetNetworkedFloat( "X", 0 );
	self.Entity:SetNetworkedFloat( "Y", 0 );
	self.Entity:SetNetworkedFloat( "Z", 0 );
	self.Entity:SetNetworkedFloat( "FadeRate", 50 );
	self.Entity:SetNetworkedFloat( "PointSize", 0.2 );
	self.Entity:SetNetworkedBool( "ShowBeam", true );
	self.Entity:SetNetworkedBool( "GroundBeam", true );
	self.Entity:SetNetworkedBool( "Active", false );
	self.Entity:SetNetworkedBool( "UseGPS", false );
	self.Entity:SetNetworkedInt( "LastClear", 0 );
	self.Entity:SetNetworkedEntity( "grid", self.Entity );

	// create inputs.
	self.Inputs = WireLib.CreateSpecialInputs( self.Entity, { "X", "Y", "Z", "Vector", "Active", "FadeRate", "Clear" }, { "NORMAL", "NORMAL", "NORMAL", "VECTOR", "NORMAL", "NORMAL", "NORMAL" } );
	self.Outputs = WireLib.CreateSpecialOutputs( self.Entity, { "Pressed X","Pressed Y","Pressed Z","Pressed Vector" }, {"NORMAL","NORMAL","NORMAL","VECTOR"} )
	
	Wire_TriggerOutput( self.Entity,"Pressed X",0)
	Wire_TriggerOutput( self.Entity,"Pressed Y",0)
	Wire_TriggerOutput( self.Entity,"Pressed Z",0)
	Wire_TriggerOutput( self.Entity,"Pressed Vector",Vector(0,0,0))
end

// link to grid
function ENT:LinkToGrid( ent )
	self.Entity:SetNetworkedEntity( "grid", ent );
end

// trigger input
function ENT:TriggerInput( inputname, value, iter )
	// store values.
	if(not value) then return end;
	if (inputname == "Clear" and value != 0)  then
		self.LastClear = self.LastClear + 1
		self.Entity:SetNetworkedInt( "Clear", self.LastClear );
		
	elseif ( inputname == "Active" ) then
		self.Entity:SetNetworkedBool( "Active", value > 0 );
		
	// store float values.
	elseif ( inputname == "Vector" ) and ( type(value) == "Vector" ) then
		self.Entity:SetNetworkedFloat( "X", value.x );
		self.Entity:SetNetworkedFloat( "Y", value.y );
		self.Entity:SetNetworkedFloat( "Z", value.z );
	elseif (inputname && inputname != "") then
		self.Entity:SetNetworkedFloat( inputname, tonumber(value) );
	end
end


if ( SERVER ) then
	function MakeWireUseHoloemitter( pl, pos, ang, r, g, b, a, showbeams, groundbeams, size, frozen )
		// check the players limit
		if( !pl:CheckLimit( "wire_useholoemitters" ) ) then return; end
		
		// create the emitter
		local emitter = ents.Create( "gmod_wire_useholoemitter" );
			emitter:SetPos( pos );
			emitter:SetAngles( ang );
		emitter:Spawn();
		emitter:Activate();
		
		if emitter:GetPhysicsObject():IsValid() then
			local Phys = emitter:GetPhysicsObject()
			Phys:EnableMotion(!frozen)
		end

		// setup the emitter.
		emitter:SetColor( r, g, b, a );
		emitter:SetPlayer( pl );
		
		// update size and show states
		emitter:SetNetworkedBool( "ShowBeam", showbeams );
		emitter:SetNetworkedBool( "GroundBeam", groundbeams );
		emitter:SetNetworkedFloat( "PointSize", size );
		
		// store the color on the table.
		local tbl = {
			r = r,
			g = g,
			b = b,
			a = a,
			showbeams = showbeams,
			groundbeams = groundbeams,
			size = size,
		};
		table.Merge( emitter:GetTable(), tbl );
		
		// add to the players count
		pl:AddCount( "wire_holoemitters", emitter );
		
		//
		return emitter;
	end
	duplicator.RegisterEntityClass( "gmod_wire_useholoemitter", MakeWireUseHoloemitter, "pos", "ang", "r", "g", "b", "a", "showbeams", "groundbeams", "size", "frozen" );
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	grid = self.Entity:GetNetworkedEntity( "grid" )
	if (grid) and (grid:IsValid()) then
		info.holoemitter_grid = grid:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	local grid = nil
	if (info.holoemitter_grid) then
		grid = GetEntByID(info.holoemitter_grid)
		if (!grid) then
		grid = ents.GetByIndex(info.holoemitter_grid)
		end
	end
	if (grid && grid:IsValid()) then
		self:LinkToGrid(grid)
	end
end

function HoloInteract(ply,cmd,args)
	local entid = tonumber(args[1])
	local x = tonumber(args[2])
	local y = tonumber(args[3])
	local z = tonumber(args[4])
	if (!entid || entid <= 0) then return end
	ent = ents.GetByIndex(entid)
	if (!ent || !ent:IsValid()) then return end
	if (ent:GetClass() != "gmod_wire_useholoemitter") then return end
	if (!x || !y || !z) then return end
	if ( !gamemode.Call( "PlayerUse", ply, ent ) ) then return end
	
	Wire_TriggerOutput( ent.Entity,"Pressed X",x)
	Wire_TriggerOutput( ent.Entity,"Pressed Y",y)
	Wire_TriggerOutput( ent.Entity,"Pressed Z",z)
	Wire_TriggerOutput( ent.Entity,"Pressed Vector",Vector(x,y,z))
end
concommand.Add("HoloInteract",HoloInteract)


