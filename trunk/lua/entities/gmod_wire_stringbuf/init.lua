AddCSLuaFile ("cl_init.lua")
AddCSLuaFile ("shared.lua")

include ("shared.lua")

ENT.WireDebugName = "Wire String Buffer"


//-----------------------------------------------------------------------------
// Name: ENT:Initialize()
// Desc: Get this entity ready to do something
//-----------------------------------------------------------------------------

function ENT:Initialize ()
    self.Entity:PhysicsInit (SOLID_VPHYSICS)
    self.Entity:SetMoveType (MOVETYPE_VPHYSICS)
    self.Entity:SetSolid    (SOLID_VPHYSICS)

    // Some nice local variables
    self.Buffer = {}
    self.Spaces = {}
    self.Dirty  = false
    
    // Wire I/O
    self.Inputs  = WireLib.CreateSpecialInputs  (self.Entity, { "String1", "String2",
        "String3", "String4" }, { "STRING", "STRING", "STRING", "STRING" })
    self.Outputs = WireLib.CreateSpecialOutputs (self.Entity, { "Memory", "String1",
        "String2", "String3", "String4" }, { "NORMAL", "STRING", "STRING", "STRING", "STRING" })
        
    // Tooltip
    self:SetOverlayText ("String Buffer")
end


//-----------------------------------------------------------------------------
// Name: ENT:Setup()
// Desc: Called by the stool to adjust the wire outputs.
//-----------------------------------------------------------------------------

function ENT:Setup (Offsets, Sizes)
    self.Spaces, self.Buffer = {}, {}
    RestoreInput = RestoreInput or false
    
    // Store parameters
    local nSize = 0
    for i = 1, 4 do
        // Save space information
        self.Spaces[i] = {}
        self.Spaces[i].Offset = Offsets[i] or 0
        self.Spaces[i].Size   = Sizes[i] or 0
        self.Spaces[i].End    = self.Spaces[i].Offset + self.Spaces[i].Size
        
        // Allocate buffer
        self.Buffer[i] = {}
        for j = 1, self.Spaces[i].Size do
            self.Buffer[i][j] = 0
        end
    end

    // Restore input (this is only really required to keep the data stored
    // within to seem persistent... even though it isn't)
    for k, v in pairs (self.Inputs) do
        self:TriggerInput (k, v.Value)
    end
end


//-----------------------------------------------------------------------------
// Name: ENT:Think()
// Desc: Output strings here to prevent lag.
//-----------------------------------------------------------------------------

function ENT:Think ()
    self.BaseClass.Think (self)
    
    // Only actually do anything we're dirty (oooh yeeeah!)
    if (self.Dirty == true) then
        self.Dirty = false
        
        // Update all four strings
        for i = 1, 4 do
            Wire_TriggerOutput (self.Entity, "String"..i, self:GetStringBuffer (i))
        end
    end
    
    // Do this fairly infrequently
    self.Entity:NextThink (CurTime () + 0.5)
end


//-----------------------------------------------------------------------------
// Name: ENT:TriggerInput()
// Desc: Recieve input from the wire system
//-----------------------------------------------------------------------------

function ENT:TriggerInput (iname, value)
    if (iname == nil) then return end

    for i = 1, 4 do
        if (iname == "String"..i) then
            // Copy into memory
            self.Buffer[i] = { string.byte (value, 1, self.Spaces[i].Size) }

            // We need to update the outupt now because address space is shared
            self.Dirty = true
        end
    end
end


//-----------------------------------------------------------------------------
// Name: ENT:ReadCell()
// Desc: Data access function for hispeed link.
//-----------------------------------------------------------------------------

function ENT:ReadCell (nAddr)
    for i = 1, 4 do
        if (nAddr >= self.Spaces[i].Offset and nAddr < self.Spaces[i].End) then
            return self.Buffer[i][nAddr - self.Spaces[i].Offset + 1]
        end
    end
    
    return nil
end


//-----------------------------------------------------------------------------
// Name: ENT:WriteCell()
// Desc: Data access function for hispeed link.
//-----------------------------------------------------------------------------

function ENT:WriteCell (nAddr, aVal)
    nAddr = math.floor (nAddr)
    aVal  = math.Clamp (math.Round (aVal), 0, 255)
    
    for i = 1, 4 do
        if (nAddr >= self.Spaces[i].Offset and nAddr < self.Spaces[i].End) then
            self.Buffer[i][nAddr - self.Spaces[i].Offset + 1] = aVal
            self.Dirty = true
            return true
        end
    end
    
    // Invalid address
    return false
end


//-----------------------------------------------------------------------------
// Name: ENT:GetStringBuffer()
// Desc: Gets the given buffer as a string.
//-----------------------------------------------------------------------------

function ENT:GetStringBuffer (nIndex)
    if (!self.Buffer[nIndex] or self.Spaces[nIndex].Size == 0) then return "" end
    
    // Convert into table of characters, and then implode it
    local str = { string.char (unpack (self.Buffer[nIndex])) }
    return string.Implode ("", str)
end


//*/
