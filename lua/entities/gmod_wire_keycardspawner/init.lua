AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "KeycardSpawner"

util.PrecacheSound('buttons/button9.wav')
util.PrecacheSound('buttons/button11.wav')

local MODEL = Model("models/keycardspawner/keycardspawner.mdl")

local function GetEntityOwner(ent)
    if not IsValid(ent) then return nil end
    if IsValid(ent:GetCreator()) then return ent:GetCreator() end
    if ent.CPPIGetOwner and IsValid(ent:CPPIGetOwner()) then return ent:CPPIGetOwner() end
    if IsValid(ent.Owner) then return ent.Owner end
    if IsValid(ent:GetOwner()) then return ent:GetOwner() end
    return nil
end

function ENT:Initialize()
    self:SetModel( MODEL )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self.LockCode = self.LockCode or 0
    self.Inputs = Wire_CreateInputs(self, { "Spawn" })
    self:ShowOutput()
end

function ENT:SetLockCode(value)
    self.LockCode = (value or 0)
    self:ShowOutput()
end

function ENT:TriggerInput(iname, value)
    if (iname == "Spawn" and value == 1) then
        local owner = GetEntityOwner(self)
        local keycard = MakeWireKeycard(owner, self:GetAngles(), self:GetPos() + (self:GetUp() * 4), self.LockCode)
        if (keycard) then
            self:EmitSound('buttons/button9.wav')
        else
            self:EmitSound('buttons/button11.wav')
        end
    end
end

function MakeWireKeycard( pl, ang, Pos, lockcode )
    local wire_keycard = ents.Create( "gmod_wire_keycard" )
    if not IsValid(wire_keycard) then return false end

    wire_keycard:SetPos( Pos )
    wire_keycard:SetAngles( ang )
    wire_keycard:Spawn()

    if IsValid(pl) then
        wire_keycard:SetCreator(pl)
        wire_keycard.Owner = pl
        if wire_keycard.CPPISetOwner then
            wire_keycard:CPPISetOwner(pl)
        end
        if wire_keycard.Setup then
            wire_keycard:Setup(pl)
        end
    end

    if wire_keycard.SetLockCode then
        wire_keycard:SetLockCode(lockcode or 0)
    end
    if wire_keycard.ResetValues then
        wire_keycard:ResetValues()
    end

    return wire_keycard
end

function ENT:ShowOutput()
    self:SetOverlayText("Wire Keycard Spawner\nLock Code: " .. (self.LockCode or 0))
end
