AddCSLuaFile( "cl_init.lua" );
AddCSLuaFile( "shared.lua" );
include( "shared.lua" );

// wire debug and overlay crap.
ENT.WireDebugName	= "High speed Holographic Emitter"
ENT.OverlayDelay 	= 0;
ENT.LastClear       = 0;

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
	self.Entity:SetNetworkedBool( "UseGPS", false );
	self.Entity:SetNetworkedInt( "LastClear", 0 );
	self.Entity:SetNetworkedEntity( "grid", self.Entity );

	// create inputs.
	self.Inputs = Wire_CreateInputs( self.Entity, { "Active", "Reset" } )
	self.Outputs = Wire_CreateOutputs( self.Entity, { "Memory" } )
	
	self:Setup()
end

function ENT:Setup()
	self.Memory = {}
	
	//Memory:
	//0 - Active
	//2 - point size
	//3 - show beam
	//4 - number of points
	//5... - points list
	
	for i = 0, 2047 do
		self.Memory[i] = 0
	end
	
	self:ShowOutput()
end

// link to grid
function ENT:LinkToGrid( ent )
	self.Entity:SetNetworkedEntity( "grid", ent );
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

function ENT:ShowOutput()
	local txt = "High Speed Holoemitter\nNumber of points: " .. self.Memory[4]
	self:SetOverlayText(txt)
end

function ENT:TriggerInput( inputname, value )
	if(not value) then return; end
	if (inputname == "Reset" and value != 0)  then
		self:WriteCell(4,0)
	elseif (inputname == "Active") then
		self:WriteCell(0,value)
	end
end

function ENT:ReadCell( Address )
	if ( Address >= 0 and Address <= 2047 ) then
		return self.Memory[Address]
	end
end

function ENT:WriteCell( Address, Value )
	if ( Address >= 0 and Address <= 2047 ) then
		self.Memory[Address] = Value
		
		local rp = RecipientFilter()
		rp:AddAllPlayers()

		umsg.Start("hsholoemitter_datamessage", rp)
			umsg.Long(self:EntIndex())
			umsg.Long(Address)
			umsg.Float(Value)
		umsg.End()
		
		return true
	end
end

function HSHoloInteract(ply,cmd,args)
	local entid = tonumber(args[1])
	local num = tonumber(args[2])
	if (!entid || entid <= 0) then return end
	ent = ents.GetByIndex(entid)
	if (!ent || !ent:IsValid()) then return end
	if (ent:GetClass() != "gmod_wire_hsholoemitter") then return end
	if (num < 0 || num > 680) then return end
	if ( !gamemode.Call( "PlayerUse", ply, ent ) ) then return end
	
	ent:WriteCell(1,num)
end
concommand.Add("HSHoloInteract",HSHoloInteract)


