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
	self:SetModel( "models/jaanus/wiretool/wiretool_range.mdl" );
	
	// setup physics
	self:PhysicsInit( SOLID_VPHYSICS );
	self:SetMoveType( MOVETYPE_VPHYSICS );
	self:SetSolid( SOLID_VPHYSICS );
	
	// vars
	self:SetNetworkedBool( "UseGPS", false );
	self:SetNetworkedInt( "LastClear", 0 );
	self:SetNetworkedEntity( "grid", self );

	// create inputs.
	self.Inputs = Wire_CreateInputs( self, { "Active", "Reset" } )
	self.Outputs = Wire_CreateOutputs( self, { "Memory" } )
	
	self:Setup()
end

function ENT:Setup()
	self.Memory = {}
	
	self.packetStartAddr = 0
	self.lastWrittenAddr = 0
	self.packetLen = 0
	self.lastThinkChange = false
	
	-- Memory:
	-- 0 - Active
	-- 1 - readonly: point that is interacted with
	-- 2 - point size
	-- 3 - bitmask: 1: show beam 2: global positions 4: individual colors for points
	-- 4 - number of points
	-- 5... - points list, format: X,Y,Z, X,Y,Z
	--	or X,Y,Z,R,G,B,A, X,Y,Z,R,G,B,A with individual color bit set
	
	for i = 0, 2047 do
		self.Memory[i] = 0
	end
	
	self:ShowOutput()
end

// link to grid
function ENT:LinkToGrid( ent )
	self:SetNetworkedEntity( "grid", ent );
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	grid = self:GetNetworkedEntity( "grid" )
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

function ENT:SendData()
	if ( self.packetLen > 0 ) then
		local rp = RecipientFilter()
		rp:AddAllPlayers()

		umsg.Start("hsholoemitter_datamsg", rp)
			umsg.Long(self:EntIndex())
			umsg.Long(self.packetStartAddr)
			umsg.Long(self.packetLen)
			for i = 0, self.packetLen-1 do
				umsg.Float(self.Memory[self.packetStartAddr + i])
			end
		umsg.End()
	end
	self.packetLen = 0
	self.packetStartAddr = 0
end

function ENT:ReadCell( Address )
    if(!self.Memory) then return; end
	if ( Address >= 0 and Address <= 4 + 3*GetConVarNumber("hsholoemitter_max_points") ) then
		return self.Memory[Address]
	end
end

function ENT:WriteCell( Address, Value )
	if ( Address >= 0 and Address <= 4 + 3*GetConVarNumber("hsholoemitter_max_points") ) then
		self.Memory[Address] = Value
		self.lastThinkChange = true
		
		if( self.packetLen == 0 ) then
			self.packetLen = 1
			self.packetStartAddr = Address
		elseif( (Address - self.lastWrittenAddr) == 1 ) then
			self.packetLen = self.packetLen + 1
			if( self.packetLen >= 30 ) then
				self:SendData()
			end
		else
			self:SendData()
			self.packetLen = 1
			self.packetStartAddr = Address
		end
		
		self.lastWrittenAddr = Address
		return true
	end
	return false
end

function ENT:Think()
	if( not self.lastThinkChange ) then
		self:SendData()
	end
	self.lastThinkChange = false
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
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


