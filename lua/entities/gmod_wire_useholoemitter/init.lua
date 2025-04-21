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
	self:SetModel( "models/jaanus/wiretool/wiretool_range.mdl" );
	
	// setup physics
	self:PhysicsInit( SOLID_VPHYSICS );
	self:SetMoveType( MOVETYPE_VPHYSICS );
	self:SetSolid( SOLID_VPHYSICS );
	
	// vars
	self:SetNWFloat( "X", 0 );
	self:SetNWFloat( "Y", 0 );
	self:SetNWFloat( "Z", 0 );
	self:SetNWFloat( "FadeRate", 50 );
	self:SetNWFloat( "PointSize", 0.2 );
	self:SetNWBool( "ShowBeam", true );
	self:SetNWBool( "GroundBeam", true );
	self:SetNWBool( "Active", false );
	self:SetNWBool( "UseGPS", false );
	self:SetNWInt( "LastClear", 0 );
	self:SetNWEntity( "grid", self );

	// create inputs.
	self.Inputs = WireLib.CreateSpecialInputs( self, { "X", "Y", "Z", "Vector", "Active", "FadeRate", "Clear" }, { "NORMAL", "NORMAL", "NORMAL", "VECTOR", "NORMAL", "NORMAL", "NORMAL" } );
	self.Outputs = WireLib.CreateSpecialOutputs( self, { "Pressed X","Pressed Y","Pressed Z","Pressed Vector" }, {"NORMAL","NORMAL","NORMAL","VECTOR"} )
	
	Wire_TriggerOutput( self,"Pressed X",0)
	Wire_TriggerOutput( self,"Pressed Y",0)
	Wire_TriggerOutput( self,"Pressed Z",0)
	Wire_TriggerOutput( self,"Pressed Vector",Vector(0,0,0))
end

// link to grid
function ENT:LinkToGrid( ent )
	self:SetNWEntity( "grid", ent );
end

// trigger input
function ENT:TriggerInput( inputname, value, iter )
	// store values.
	if(not value) then return end;
	if (inputname == "Clear" and value != 0)  then
		self.LastClear = self.LastClear + 1
		self:SetNWInt( "Clear", self.LastClear );
		
	elseif ( inputname == "Active" ) then
		self:SetNWBool( "Active", value > 0 );
		
	// store float values.
	elseif ( inputname == "Vector" ) and ( type(value) == "Vector" ) then
		self:SetNWFloat( "X", value.x );
		self:SetNWFloat( "Y", value.y );
		self:SetNWFloat( "Z", value.z );
	elseif (inputname && inputname != "") then
		self:SetNWFloat( inputname, tonumber(value) );
	end
end


if ( SERVER ) then
	function MakeWireUseHoloemitter( pl, pos, ang, r, g, b, a, showbeams, groundbeams, size, frozen )
		// check the players limit
		if( !pl:CheckLimit( "wire_useholoemitters" ) ) then return; end
		
		// create the emitter
		local emitter = ents.Create( "gmod_wire_useholoemitter" )
		emitter:SetPos( pos );
		emitter:SetAngles( ang );
		emitter:Spawn();
		emitter:Activate();
		
		if emitter:GetPhysicsObject():IsValid() then
			local Phys = emitter:GetPhysicsObject()
			Phys:EnableMotion(!frozen)
		end

		// setup the emitter.
		emitter:SetColor( Color(r, g, b, a) );
		emitter:SetPlayer( pl );
		
		// update size and show states
		emitter:SetNWBool( "ShowBeam", showbeams );
		emitter:SetNWBool( "GroundBeam", groundbeams );
		emitter:SetNWFloat( "PointSize", size );
		
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

	grid = self:GetNWEntity( "grid" )
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

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

concommand.Add("HoloInteract", function(ply, cmd, args)
	local entid = tonumber(args[1])
	if not entid or entid <= 0 then return end

	local ent = ents.GetByIndex(entid)
	if not ent:IsValid() or ent:GetClass() ~= "gmod_wire_useholoemitter" then return end

	local x = tonumber(args[2])
	if not x then return end

	local y = tonumber(args[3])
	if not y then return end

	local z = tonumber(args[4])
	if not z then return end

	if not gamemode.Call("PlayerUse", ply, ent) then return end
	
	Wire_TriggerOutput(ent.Entity, "Pressed X", x)
	Wire_TriggerOutput(ent.Entity, "Pressed Y", y)
	Wire_TriggerOutput(ent.Entity, "Pressed Z", z)
	Wire_TriggerOutput(ent.Entity, "Pressed Vector", Vector(x, y, z))
end)
