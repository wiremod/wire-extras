
TOOL.Category   = "Wire - Advanced"
TOOL.Name       = "String Buffer"
TOOL.Command    = nil
TOOL.ConfigName = ""

if (CLIENT) then
    // General GMod strings:
    language.Add ("Tool_wire_stringbuf_name",   "String Buffer (Wire)")
    language.Add ("Tool_wire_stringbuf_desc",   "Spawns a String Buffer for use with the wire system.")
    language.Add ("Tool_wire_stringbuf_0",      "Left-Click:  Create/Update Wire String Buffer.")
    language.Add ("sboxlimit_wire_stringbufs",  "You've hit the string buffer limit!")
    language.Add ("undone_wire_stringbuf",      "Undone wire string buffer.")
    language.Add ("cleanup_wire_stringbufs",    "String Buffers (Wire)")
    language.Add ("cleaned_wire_stringbufs",    "Cleaned up all string buffers.")
    
    // Control panel UI strings:
    language.Add ("WireStringBuffer_Model",     "Model:")
    language.Add ("WireStringBuffer_Offset1",   "String 1 Offset:")
    language.Add ("WireStringBuffer_Offset2",   "String 2 Offset:")
    language.Add ("WireStringBuffer_Offset3",   "String 3 Offset:")
    language.Add ("WireStringBuffer_Offset4",   "String 4 Offset:")
    language.Add ("WireStringBuffer_Size1",     "String 1 Size:")
    language.Add ("WireStringBuffer_Size2",     "String 2 Size:")
    language.Add ("WireStringBuffer_Size3",     "String 3 Size:")
    language.Add ("WireStringBuffer_Size4",     "String 4 Size:")
end

if (SERVER) then
    CreateConVar ("sbox_maxwire_stringbufs", 20)
end

// Control panel values
TOOL.ClientConVar["model"]          = "models/jaanus/wiretool/wiretool_gate.mdl"
TOOL.ClientConVar["space1offset"]   = 0
TOOL.ClientConVar["space1size"]     = 0
TOOL.ClientConVar["space2offset"]   = 0
TOOL.ClientConVar["space2size"]     = 0
TOOL.ClientConVar["space3offset"]   = 0
TOOL.ClientConVar["space3size"]     = 0
TOOL.ClientConVar["space4offset"]   = 0
TOOL.ClientConVar["space4size"]     = 0

if (SERVER) then
    ModelPlug_Register ("stringbuf")
end

cleanup.Register ("wire_stringbufs")


//-----------------------------------------------------------------------------
// Name: TOOL:LeftClick()
// Desc: Create or update ourselves a wire string buffer.
//-----------------------------------------------------------------------------

function TOOL:LeftClick (trace)
    if (!trace.HitPos) then return false end
    if (trace.Entity:IsPlayer ()) then return false end
    if (CLIENT) then return true end
    
    // Get our owner
    local ply = self:GetOwner ()
    
    // Get the clients' console variables
    local model   = self:GetClientInfo ("model")

    // Update an existing wire string buffer
    if (trace.Entity:IsValid () and trace.Entity:GetClass () == "gmod_wire_stringbuf" and trace.Entity:GetPlayer () == ply) then
        local Offsets = { self:GetClientNumber ("space1offset"),
                          self:GetClientNumber ("space2offset"),
                          self:GetClientNumber ("space3offset"),
                          self:GetClientNumber ("space4offset") }
        local Sizes   = { self:GetClientNumber ("space1size"),
                          self:GetClientNumber ("space2size"),
                          self:GetClientNumber ("space3size"),
                          self:GetClientNumber ("space4size") }
        trace.Entity:Setup (Offsets, Sizes)
        return true
    end
    
    // Make sure we're good to spawn
    if (!self:GetSWEP ():CheckLimit ("wire_stringbufs")) then return false end
    
    // Check the model the player wants to use
    if (!util.IsValidModel (model)) then return false end
    if (!util.IsValidProp  (model)) then return false end

    // Spawn the entity 
    local Ang = trace.HitNormal:Angle ()
    Ang.pitch = Ang.pitch + 90
    local StringBuf = MakeWireStringBuffer (ply, model, trace.HitPos, Ang,
        self:GetClientNumber ("space1offset"), self:GetClientNumber ("space2offset"),
        self:GetClientNumber ("space3offset"), self:GetClientNumber ("space4offset"),
        self:GetClientNumber ("space1size"),   self:GetClientNumber ("space2size"),
        self:GetClientNumber ("space3size"),   self:GetClientNumber ("space4size"))
    local min = StringBuf:OBBMins ()
	StringBuf:SetPos (trace.HitPos - trace.HitNormal * min.z)

    // WireLib.Weld handles all of this "don't weld to world but weld to a
    //  prop as long as that prop has been spawned by you" stuff
    local const = WireLib.Weld (StringBuf, trace.Entity, trace.PhysicsBone, true)
    
    // Finally, make sure our player can undo this and cleanup and whatever
    undo.Create ("wire_stringbuf")
        undo.AddEntity (StringBuf)
        undo.AddEntity (const)
        undo.SetPlayer (ply)
    undo.Finish ()
    
    ply:AddCleanup ("wire_stringbufs", StringBuf)
    
    return true
end


//-----------------------------------------------------------------------------
// Name: MakeWireStringBuffer()
// Desc: Funky duplicator func.
//-----------------------------------------------------------------------------

if (SERVER) then
    function MakeWireStringBuffer (ply, Model, Pos, Ang, Offset1, Offset2, Offset3,
            Offset4, Size1, Size2, Size3, Size4)
        // Make sure we're allowed to spawn
        if (!ply:CheckLimit ("wire_stringbufs")) then return false end

        // Spawn the string buffer
        local StringBuf = ents.Create ("gmod_wire_stringbuf")
        if (!StringBuf:IsValid ()) then return false end

        // Configure this thing
        StringBuf:SetModel (Model)
        StringBuf:SetAngles (Ang)
        StringBuf:SetPos (Pos)
        StringBuf:Spawn ()
        StringBuf:SetPlayer (ply)

        // Set up the address spaces
        StringBuf:Setup ({ Offset1, Offset2, Offset3, Offset4 }, { Size1, Size2, Size3, Size4 })
        
        // Set stuff up for the duplicator
        local ttable = {
            ply     = ply,
            Offset1 = Offset1,
            Offset2 = Offset2,
            Offset3 = Offset3,
            Offset4 = Offset4,
            Size1   = Size1,
            Size2   = Size2,
            Size3   = Size3,
            Size4   = Size4
        }
        table.Merge (StringBuf:GetTable (), ttable)

        // Keep track of these things!
        ply:AddCount ("wire_stringbufs", StringBuf)
        return StringBuf
    end
    duplicator.RegisterEntityClass ("gmod_wire_stringbuf", MakeWireStringBuffer, "Model", "Pos", "Ang", 
        "Offset1", "Offset2", "Offset3", "Offset4", "Size1", "Size2", "Size3", "Size4")
end


//-----------------------------------------------------------------------------
// Name: TOOL:UpdateGhostWireStringBuffer()
// Desc: Aid with positioning...
//-----------------------------------------------------------------------------

function TOOL:UpdateGhostWireStringBuffer (ent, ply)
    if (!ent or !ent:IsValid ()) then return end

    local trace = util.TraceLine (utilx.GetPlayerTrace (ply, ply:GetCursorAimVector ()))
    if (!trace.Hit) then return end

    if (trace.Entity and trace.Entity:GetClass () == "gmod_wire_stringbuf" or trace.Entity:IsPlayer ()) then
        ent:SetNoDraw (true)
        return
    end

    local Ang = trace.HitNormal:Angle ()
    Ang.pitch = Ang.pitch + 90

    ent:SetPos (trace.HitPos - trace.HitNormal * ent:OBBMins ().z)
    ent:SetAngles (Ang)

    ent:SetNoDraw (false)
end


//-----------------------------------------------------------------------------
// Name: TOOL:Think()
// Desc: As above...
//-----------------------------------------------------------------------------

function TOOL:Think ()
    if (!self.GhostEntity or !self.GhostEntity:IsValid () or self.GhostEntity:GetModel () != self:GetClientInfo ("model") or (not self.GhostEntity:GetModel ())) then
        self:MakeGhostEntity (self:GetClientInfo ("model"), Vector (0, 0, 0), Angle (0, 0, 0))
    end

    self:UpdateGhostWireStringBuffer (self.GhostEntity, self:GetOwner ())
end


//-----------------------------------------------------------------------------
// Name: TOOL.BuildCPanel()
// Desc: Called by the stool to adjust the wire outputs.
//-----------------------------------------------------------------------------

function TOOL.BuildCPanel (panel)
    panel:AddControl ("Header", { Text = "#Tool_wire_stringbuf_name", Description = "#Tool_wire_stringbuf_desc" })
    
    panel:AddControl ("Slider",  { Label = "#WireStringBuffer_Offset1",
                                   Command = "wire_stringbuf_space1offset",
                                   Type = "Integer",
                                   Min = "0",
                                   Max = "16777216"}) // Limit to 24bits because BP did :-)

    panel:AddControl ("Slider",  { Label = "#WireStringBuffer_Size1",
                                   Command = "wire_stringbuf_space1size",
                                   Type = "Integer",
                                   Min = "0",
                                   Max = "2048"}) // ... but this is more sensible for buffer size

    panel:AddControl ("Slider",  { Label = "#WireStringBuffer_Offset2",
                                   Command = "wire_stringbuf_space2offset",
                                   Type = "Integer",
                                   Min = "0",
                                   Max = "16777216"})

    panel:AddControl ("Slider",  { Label = "#WireStringBuffer_Size2",
                                   Command = "wire_stringbuf_space2size",
                                   Type = "Integer",
                                   Min = "0",
                                   Max = "2048"})

    panel:AddControl ("Slider",  { Label = "#WireStringBuffer_Offset3",
                                   Command = "wire_stringbuf_space3offset",
                                   Type = "Integer",
                                   Min = "0",
                                   Max = "16777216"})

    panel:AddControl ("Slider",  { Label = "#WireStringBuffer_Size3",
                                   Command = "wire_stringbuf_space3size",
                                   Type = "Integer",
                                   Min = "0",
                                   Max = "2048"})

    panel:AddControl ("Slider",  { Label = "#WireStringBuffer_Offset4",
                                   Command = "wire_stringbuf_space4offset",
                                   Type = "Integer",
                                   Min = "0",
                                   Max = "16777216"})

    panel:AddControl ("Slider",  { Label = "#WireStringBuffer_Size4",
                                   Command = "wire_stringbuf_space4size",
                                   Type = "Integer",
                                   Min = "0",
                                   Max = "2048"})

    ModelPlug_AddToCPanel (panel, "gate", "wire_stringbuf", "#WireStringBuffer_Model",
        nil, "#WireStringBuffer_Model")
end

//*/
