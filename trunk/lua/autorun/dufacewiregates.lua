//-----------------------------------------------------------------------------
// DuFace's Wire Gates
// -------------------
//
// Adds vector and entity based gates. Common to all gate sections are the
// following:
//
//   * Multiplexer/Demultiplexer
//   * Latch/D-latch
//   * Equal/Inequal/Less-than/Greater-than (where appropriate)
//
//
// Vector Gates
// ------------
//
//   * Add
//   * Subtract
//   * Negate
//   * Multiply/Divide by constant
//   * Dot/Cross Product
//   * Yaw/Pitch
//   * Yaw/Pitch (Radian)
//   * Magnitude
//   * Conversion To/From
//   * Normalise
//   * Identity
//   * Random (really needed?)
//   * Component Derivative
//   * Component Integral
//
//
// Entity Gates
// ------------
//
//   * Activator
//   * Owner
//   * Identity
//   * Name
//   * Position
//   * Colour
//   * EntId
//   * Class
//   * Parent
//   * Null
//   * Velocity
//   * Forward/Right/Up vectors
//   * Max Health/Health
//   * Model
//   * Skin/Skin Count
//   * IsPlayer
//   * IsConstrained
//   * IsInWorld
//   * IsNPC
//   * IsOnFire
//   * IsOnGround
//   * IsPlayerHolding
//   * IsVehicle
//   * IsWeapon
//   * Can See
//
//
// Player Gates
// ------------
//
// Still strictly entity gates, but will output nil or zero (whichever is more
// appropriate) if the input entity is not a player.
//
//   * Alive
//   * Armour
//   * Chat Print
//   * Crouching
//   * Death/Kill Count
//   * Aim Vector
//   * InVehicle
//   * SteamID
//   * Team ID/Name
//   * Seconds Connected
//   * IsLockedOnto
//
//
// Thats all I can think of for the time being. If you can think of anything
// you'd like added then either PM me or start a thread on the Wiremod forums.
// You could leave a message on the FP forums if you wanted but I probably wont
// read it. I tend to lurk moar at Wiremod.com ;-)
//-----------------------------------------------------------------------------

AddCSLuaFile ("autorun/dufacewiregates.lua")


//-----------------------------------------------------------------------------
// Encapsulate to prevent up-fuckery.
//-----------------------------------------------------------------------------

local function AddWireGates_DuFace ()

//-----------------------------------------------------------------------------
// Controlling convars
//-----------------------------------------------------------------------------

    // Behaviour of chatprint gate is to be controlled to prevent exploitation
    // by mingebags:
    //   0 - Gate completely disabled (still spawns, just won't do anything)
    //   1 - Can only act on owning player (entity input ignored)
    //   2 - Full operation allowed
    //CreateConVar ("sv_wiregates_chatprint_act", "1", FCVAR_ARCHIVE)


//-----------------------------------------------------------------------------
// Vector gates
//-----------------------------------------------------------------------------

// Add
    GateActions["vector_add"] = {
        group = "Vector",
        name = "Addition",
        inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
        inputtypes = { "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR" },
        compact_inputs = 2,
        outputtypes = { "VECTOR" },
        output = function (gate, ...)
            local sum = Vector (0, 0, 0)
            for _, v in pairs (arg) do
                if (v and IsVector (v)) then
                    sum = sum + v
                end
            end
            return sum
        end,
        label = function (Out, ...)
            local tip = ""
            for _, v in ipairs (arg) do
                if (v) then tip = tip .. " + " .. v end
            end
            return string.format ("%s = (%d,%d,%d)", string.sub (tip, 3),
                Out.x, Out.y, Out.z)
        end
    }
// Subtract
    GateActions["vector_sub"] = {
        group = "Vector",
        name = "Subtraction",
        inputs = { "A", "B" },
        inputtypes = { "VECTOR", "VECTOR" },
        outputtypes = { "VECTOR" },
        output = function (gate, A, B)
            if !IsVector (A) then A = Vector (0, 0, 0) end
            if !IsVector (B) then B = Vector (0, 0, 0) end
            return (A - B)
        end,
        label = function (Out, A, B)
            return string.format ("%s - %s = (%d,%d,%d)", A, B, Out.x, Out.y, Out.z)
        end
    }
// Negate
    GateActions["vector_neg"] = {
        group = "Vector",
        name = "Negate",
        inputs = { "A" },
        inputtypes = { "VECTOR" },
        outputtypes = { "VECTOR" },
        output = function (gate, A)
            if !IsVector (A) then A = Vector (0, 0, 0) end
            return Vector (-A.x, -A.y, -A.z)
        end,
        label = function (Out, A)
            return string.format ("-%s = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
        end
    }
// Multiply/Divide by constant
    GateActions["vector_mul"] = {
        group = "Vector",
        name = "Multiplication",
        inputs = { "A", "B" },
        inputtypes = { "VECTOR", "NORMAL" },
        outputtypes = { "VECTOR" },
        output = function (gate, A, B)
            if !IsVector (A) then A = Vector (0, 0, 0) end
            return (A * B)
        end,
        label = function (Out, A, B)
            return string.format ("%s * %s = (%d,%d,%d)", A, B, Out.x, Out.y, Out.z)
        end
    }
    GateActions["vector_divide"] = {
        group = "Vector",
        name = "Division",
        inputs = { "A", "B" },
        inputtypes = { "VECTOR", "NORMAL" },
        outputtypes = { "VECTOR" },
        output = function (gate, A, B)
            if !IsVector (A) then A = Vector (0, 0, 0) end
            if (B) then
                return (A / B)
            end
            return Vector (0, 0, 0)
        end,
        label = function (Out, A, B)
            return string.format ("%s / %s = (%d,%d,%d)", A, B, Out.x, Out.y, Out.z)
        end
    }
// Dot/Cross Product
    GateActions["vector_dot"] = {
        group = "Vector",
        name = "Dot Product",
        inputs = { "A", "B" },
        inputtypes = { "VECTOR", "VECTOR" },
        outputtypes = { "NORMAL" },
        output = function (gate, A, B)
            if !IsVector (A) then A = Vector (0, 0, 0) end
            if !IsVector (B) then B = Vector (0, 0, 0) end
            return A:Dot (B)
        end,
        label = function (Out, A, B)
            return string.format ("dot(%s, %s) = %d", A, B, Out)
        end
    }
    GateActions["vector_cross"] = {
        group = "Vector",
        name = "Cross Product",
        inputs = { "A", "B" },
        inputtypes = { "VECTOR", "VECTOR" },
        outputtypes = { "VECTOR" },
        output = function (gate, A, B)
            if !IsVector (A) then A = Vector (0, 0, 0) end
            if !IsVector (B) then B = Vector (0, 0, 0) end
            return A:Cross (B)
        end,
        label = function (Out, A, B)
            return string.format ("cross(%s, %s) = (%d,%d,%d)", A, B, Out.x, Out.y, Out.z)
        end
    }
// Yaw/Pitch
    GateActions["vector_ang"] = {
        group = "Vector",
        name = "Angles (Degree)",
        inputs = { "A" },
        inputtypes = { "VECTOR" },
        outputs = { "Yaw", "Pitch" },
        outputtypes = { "NORMAL", "NORMAL" },
        output = function (gate, A)
            if !IsVector (A) then A = Vector (0, 0, 0) end
            local ang = A:Angle ()
            return ang.y, ang.p
        end,
        label = function (Out, A)
            return string.format ("ang(%s) = %d, %d", A, Out.Yaw, Out.Pitch)
        end
    }
// Yaw/Pitch (Radian)
    GateActions["vector_angrad"] = {
        group = "Vector",
        name = "Angles (Radian)",
        inputs = { "A" },
        inputtypes = { "VECTOR" },
        outputs = { "Yaw", "Pitch" },
        outputtypes = { "NORMAL", "NORMAL" },
        output = function (gate, A)
            if !IsVector (A) then A = Vector (0, 0, 0) end
            local ang = A:Angle ()
            return (ang.y * math.pi / 180), (ang.p * math.pi / 180)
        end,
        label = function (Out, A)
            return string.format ("angr(%s) = %d, %d", A, Out.Yaw, Out.Pitch)
        end
    }
// Magnitude
    GateActions["vector_mag"] = {
        group = "Vector",
        name = "Magnitude",
        inputs = { "A" },
        inputtypes = { "VECTOR" },
        outputtypes = { "NORMAL" },
        output = function (gate, A)
            if !IsVector (A) then A = Vector (0, 0, 0) end
            return A:Length ()
        end,
        label = function (Out, A)
            return string.format ("|%s| = %d", A, Out)
        end
    }
// Conversion To/From
    GateActions["vector_convto"] = {
        group = "Vector",
        name = "Compose",
        inputs = { "X", "Y", "Z" },
        inputtypes = { "NORMAL", "NORMAL", "NORMAL" },
        outputtypes = { "VECTOR" },
        output = function (gate, X, Y, Z)
            return Vector (X, Y, Z)
        end,
        label = function (Out, X, Y, Z)
            return string.format ("vector(%s,%s,%s) = (%d,%d,%d)", X, Y, Z, Out.x, Out.y, Out.z)
        end
    }
    GateActions["vector_convfrom"] = {
        group = "Vector",
        name = "Decompose",
        inputs = { "A" },
        inputtypes = { "VECTOR" },
        outputs = { "X", "Y", "Z" },
        outputtypes = { "NORMAL", "NORMAL", "NORMAL" },
        output = function (gate, A)
            if (A and IsVector (A)) then
                return A.x, A.y, A.z
            end
            return 0, 0, 0
        end,
        label = function (Out, A)
            return string.format ("%s -> X:%d Y:%d Z:%d", A, Out.X, Out.Y, Out.Z)
        end
    }
// Normalise
    GateActions["vector_norm"] = {
        group = "Vector",
        name = "Normalise",
        inputs = { "A" },
        inputtypes = { "VECTOR" },
        outputtypes = { "VECTOR" },
        output = function (gate, A)
            if !IsVector (A) then A = Vector (0, 0, 0) end
            return A:Normalize ()
        end,
        label = function (Out, A)
            return string.format ("norm(%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
        end
    }
// Identity
    GateActions["vector_ident"] = {
        group = "Vector",
        name = "Identity",
        inputs = { "A" },
        inputtypes = { "VECTOR" },
        outputtypes = { "VECTOR" },
        output = function (gate, A)
            if !IsVector (A) then A = Vector (0, 0, 0) end
            return A
        end,
        label = function (Out, A)
            return string.format ("%s = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
        end
    }
// Random (really needed?)
    GateActions["vector_rand"] = {
        group = "Vector",
        name = "Random",
        inputs = {  },
        inputtypes = {  },
        outputtypes = { "VECTOR" },
        timed = true,
        output = function (gate)
            local vec = Vector (math.random (), math.random (), math.random ())
            return vec:Normalize ()
        end,
        label = function (Out)
            return "Random Vector"
        end
    }
// Component Derivative
    GateActions["vector_derive"] = {
        group = "Vector",
        name = "Component Derivative",
        inputs = { "A" },
        inputtypes = { "VECTOR" },
        outputtypes = { "VECTOR" },
        timed = true,
        output = function (gate, A)
            local t = CurTime ()
            if !IsVector (A) then A = Vector (0, 0, 0) end
            local dT, dA = t - gate.LastT, A - gate.LastA
            gate.LastT, gate.LastA = t, A
            if (dT) then
                return Vector (dA.x/dT, dA.y/dT, dA.z/dT)
            else
                return Vector (0, 0, 0)
            end
        end,
        reset = function (gate)
            gate.LastT, gate.LastA = CurTime (), Vector (0, 0, 0)
        end,
        label = function (Out, A)
            return string.format ("diff(%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
        end
    }
// Component Integral
    GateActions["vector_cint"] = {
        group = "Vector",
        name = "Component Integral",
        inputs = { "A" },
        inputtypes = { "VECTOR" },
        outputtypes = { "VECTOR" },
        timed = true,
        output = function (gate, A)
            local t = CurTime ()
            if !IsVector (A) then A = Vector (0, 0, 0) end
            local dT = t - (gate.LastT or t)
            gate.LastT, gate.Integral = t, (gate.Integral or Vector (0, 0, 0)) + A * dT
            // Lifted (kinda) from wiregates.lua to prevent massive values
            local TempInt = gate.Integral:Length ()
            if (TempInt > 100000) then
                gate.Integral = gate.Integral:Normalize () * 100000
            end
            if (TempInt < -100000) then
                gate.Integral = gate.Integral:Normalize () * -100000
            end
            return gate.Integral
        end,
        reset = function (gate)
            gate.Integral, gate.LastT = Vector (0, 0, 0), CurTime ()
        end,
        label = function (Out, A)
            return string.format ("int(%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
        end
    }
// Multiplexer
    GateActions["vector_mux"] = {
        group = "Vector",
        name = "Multiplexer",
        inputs = { "Sel", "A", "B", "C", "D", "E", "F", "G", "H" },
        inputtypes = { "NORMAL", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR" },
        compact_inputs = 3,
        outputtypes = { "VECTOR" },
        output = function (gate, Sel, ...)
            Sel = math.floor (Sel)
            if (Sel > 0 && Sel <= 8) then
                return arg[Sel]
            end
            return Vector (0, 0, 0)
        end,
        label = function (Out, Sel, ...)
            return string.format ("Select: %s  Out: (%d,%d,%d)",
                Sel, Out.x, Out.y, Out.z)
        end
    }
// Demultiplexer
    GateActions["vector_dmx"] = {
        group = "Vector",
        name = "Demultiplexer",
        inputs = { "Sel", "In" },
        inputtypes = { "NORMAL", "VECTOR" },
        outputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
        outputtypes = { "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR" },
        output = function (gate, Sel, In)
            local Out = { Vector (0, 0, 0), Vector (0, 0, 0), Vector (0, 0, 0), Vector (0, 0, 0), 
                Vector (0, 0, 0), Vector (0, 0, 0), Vector (0, 0, 0), Vector (0, 0, 0) }
            Sel = math.floor (Sel)
            if (Sel > 0 && Sel <= 8) then
                Out[Sel] = In
            end
            return unpack (Out)
        end,
        label = function (Out, Sel, In)
            if !IsVector (In) then In = Vector (0, 0, 0) end
            if !Sel then Sel = 0 end
            return string.format ("Select: %s, In: (%d,%d,%d)",
                Sel, In.x, In.y, In.z)
        end
    }
// Latch
    GateActions["vector_latch"] = {
        group = "Vector",
        name = "Latch",
        inputs = { "In", "Clk" },
        inputtypes = { "VECTOR", "NORMAL" },
        outputtypes = { "VECTOR" },
        output = function (gate, In, Clk)
            Clk = (Clk > 0)
            if (gate.PrevClk != Clk) then
                gate.PrevClk = Clk
                if (Clk) then
                    if !IsVector (In) then In = Vector (0, 0, 0) end
                    gate.LatchStore = In
                end
            end
            return gate.LatchStore or Vector (0, 0, 0)
        end,
        reset = function (gate)
            gate.LatchStore = Vector (0, 0, 0)
            gate.PrevValue  = 0
        end,
        label = function (Out, In, Clk)
            return string.format ("Latch Data: %s  Clock: %s  Out: (%d,%d,%d)",
                In, Clk, Out.x, Out.y, Out.z)
        end
    }
// D-latch
    GateActions["vector_dlatch"] = {
        group = "Vector",
        name = "D-Latch",
        inputs = { "In", "Clk" },
        inputtypes = { "VECTOR", "NORMAL" },
        outputtypes = { "VECTOR" },
        output = function (gate, In, Clk)
            if (Clk > 0) then
                if !IsVector (In) then In = Vector (0, 0, 0) end
                gate.LatchStore = In
            end
            return gate.LatchStore or Vector (0, 0, 0)
        end,
        reset = function (gate)
            gate.LatchStore = Vector (0, 0, 0)
        end,
        label = function (Out, In, Clk)
            return string.format ("Latch Data: %s  Clock: %s  Out: (%d,%d,%d)",
                In, Clk, Out.x, Out.y, Out.z)
        end
    }
// Equal
    GateActions["vector_compeq"] = {
        group = "Vector",
        name = "Equal",
        inputs = { "A", "B" },
        inputtypes = { "VECTOR", "VECTOR" },
        outputtypes = { "NORMAL" },
        output = function (gate, A, B)
            if (A == B) then return 1 end
            return 0
        end,
        label = function (Out, A, B)
            return string.format ("(%s == %s) = %d", A, B, Out)
        end
    }
// Inequal
    GateActions["vector_compineq"] = {
        group = "Vector",
        name = "Inequal",
        inputs = { "A", "B" },
        inputtypes = { "VECTOR", "VECTOR" },
        outputtypes = { "NORMAL" },
        output = function (gate, A, B)
            if (A == B) then return 0 end
            return 1
        end,
        label = function (Out, A, B)
            return string.format ("(%s != %s) = %d", A, B, Out)
        end
    }
// Less-than
    GateActions["vector_complt"] = {
        group = "Vector",
        name = "Less Than",
        inputs = { "A", "B" },
        inputtypes = { "VECTOR", "VECTOR" },
        outputtypes = { "NORMAL" },
        output = function (gate, A, B)
            if !IsVector (A) then A = Vector (0, 0, 0) end
            if !IsVector (B) then B = Vector (0, 0, 0) end
            if (A:Length () < B:Length ()) then return 1 end
        end,
        label = function (Out, A, B)
            return string.format ("(|%s| < |%s|) = %d", A, B, Out)
        end
    }
// Less-than or Equal-to
    GateActions["vector_complteq"] = {
        group = "Vector",
        name = "Less Than or Equal To",
        inputs = { "A", "B" },
        inputtypes = { "VECTOR", "VECTOR" },
        outputtypes = { "NORMAL" },
        output = function (gate, A, B)
            if !IsVector (A) then A = Vector (0, 0, 0) end
            if !IsVector (B) then B = Vector (0, 0, 0) end
            if (A:Length () <= B:Length ()) then return 1 end
            return 0
        end,
        label = function (Out, A, B)
            return string.format ("(|%s| <= |%s|) = %d", A, B, Out)
        end
    }
// Greater-than
    GateActions["vector_compgt"] = {
        group = "Vector",
        name = "Greater Than",
        inputs = { "A", "B" },
        inputtypes = { "VECTOR", "VECTOR" },
        output = function (gate, A, B)
            if !IsVector (A) then A = Vector (0, 0, 0) end
            if !IsVector (B) then B = Vector (0, 0, 0) end
            if (A:Length () > B:Length ()) then return 1 end
            return 0
        end,
        label = function (Out, A, B)
            return string.format ("(|%s| > |%s|) = %d", A, B, Out)
        end
    }
// Greater-than or Equal-to
    GateActions["vector_compgteq"] = {
        group = "Vector",
        name = "Greater Than or Equal To",
        inputs = { "A", "B" },
        inputtypes = { "VECTOR", "VECTOR" },
        output = function (gate, A, B)
            if !IsVector (A) then A = Vector (0, 0, 0) end
            if !IsVector (B) then B = Vector (0, 0, 0) end
            if (A:Length () < B:Length ()) then return 1 end
            return 0
        end,
        label = function (Out, A, B)
            return string.format ("(|%s| >= |%s|) = %d", A, B, Out)
        end
    }


//-----------------------------------------------------------------------------
// Entity Gates
//-----------------------------------------------------------------------------

// Activator (TODO... maybe)
// Owner
    GateActions["entity_owner"] = {
        group = "Entity",
        name = "Owner",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        outputtypes = { "ENTITY" },
        output = function (gate, A)
            gate.Action.timed = false
            if (A and IsEntity (A) and A:IsValid ()) then return A:GetOwner () end
            return NULL
        end,
        label = function (Out, A)
            local strEnt = "(none)"
            if (Out != NULL and IsEntity (Out)) then strEnt = Out:GetName () end
            return string.format ("A: %s  Owner: %s", A, strEnt)
        end
    }
// Spawner
    GateActions["entity_player"] = {
        group = "Entity",
        name = "You",
        inputs = {  },
        inputtypes = {  },
        outputtypes = { "ENTITY" },
        output = function (gate)
            local ply = gate.Entity:GetTable ().pl or nil
            if (ply and ply:IsValid () and ply:IsPlayer ()) then return ply end
            return NULL
        end,
        label = function (Out)
            if (IsEntity (Out) and Out:IsPlayer ()) then
                return "You are " .. Out:GetName ()
            end

            return "Unknown player!"
        end
    }
// Identity
    GateActions["entity_ident"] = {
        group = "Entity",
        name = "Identity",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        outputtypes = { "ENTITY" },
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid ()) then return A end
            return nil
        end,
        label = function (Out, A)
            local strEnt = "(none)"
            if (IsEntity (Out)) then strEnt = Out:GetName () end
            return string.format ("%s = %s", A, strEnt)
        end
    }
// Name
    GateActions["entity_name"] = {
        group = "Entity",
        name = "Name",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        outputtypes = { "STRING" },
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid ()) then
                return A:GetName ()
            end
            return ""
        end,
        label = function (Out, A)
            return string.format ("A: %s  Name: %s", A, Out)
        end
    }
// Position
    GateActions["entity_pos"] = {
        group = "Entity",
        name = "Position",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        outputtypes = { "VECTOR" },
        timed = true,
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid ()) then return A:GetPos () end
            return Vector (0, 0, 0)
        end,
        label = function (Out, A)
            return string.format ("A: %s  Position: (%d,%d,%d)",
                A, Out.x, Out.y, Out.z)
        end
    }
// Colour
    GateActions["entity_clr"] = {
        group = "Entity",
        name = "Colour",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        outputs = { "Red", "Green", "Blue", "Alpha" },
        outputtypes = { "NORMAL", "NORMAL", "NORMAL", "NORMAL" },
        timed = true,
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid ()) then return A:GetColor () end
            return 0, 0, 0, 0
        end,
        label = function (Out, A)
            return string.format ("A: %s  Color: %d, %d, %d, %d", 
                A, Out.Red, Out.Green, Out.Blue, Out.Alpha)
        end
    }
// Class
    GateActions["entity_class"] = {
        group = "Entity",
        name = "Class",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        outputtypes = { "STRING" },
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid ()) then return A:GetClass () end
            return "(unknown)"
        end,
        label = function (Out, A)
            return string.format ("A: %s  Class: %s", A, Out)
        end
    }
// EntId
    GateActions["entity_entid"] = {
        group = "Entity",
        name = "Entity ID",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid ()) then return A:EntIndex () end
            return 0
        end,
        label = function (Out, A)
            return string.format ("A: %s  ID: %d", A, Out)
        end
    }
// Parent
    GateActions["entity_parent"] = {
        group = "Entity",
        name = "Parent",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        outputtypes = { "ENTITY" },
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid ()) then return A:GetParent () end
            return NULL
        end,
        label = function (Out, A)
            local strParent = "(none)"
            if (Out != NULL and IsEntity (Out)) then strParent = Out:GetName () end
            return string.format ("A: %s  Parent  %s", A, strParent)
        end
    }
// Null (not actually worth the effort)
// Velocity
    GateActions["entity_vel"] = {
        group = "Entity",
        name = "Velocity",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        outputtypes = { "VECTOR" },
        timed = true,
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid ()) then return A:GetVelocity () end
            return Vector (0, 0, 0)
        end,
        label = function (Out, A)
            return string.format ("A: %s  Velocity: (%d,%d,%d)", A, Out.x, Out.y, Out.z)
        end
    }
--[[
    GateActions["entity_angvel"] = {
        group = "Entity",
        name = "Angular Velocity",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        outputtypes = { "VECTOR" },
        timed = true,
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid ()) then 
                local phys = A:GetPhysicsObject ()
                return phys:GetAngleVelocity () 
            end
            return Vector (0, 0, 0)
        end,
        label = function (Out, A)
            return string.format ("A: %s  Angular Velocity: (%d,%d,%d)",
                A, Out.x, Out.y, Out.z)
        end
    }
]]
// Forward/Right/Up vectors
    GateActions["entity_fruvecs"] = {
        group = "Entity",
        name = "Relational Vectors",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        outputs = { "Up", "Right", "Forward" },
        outputtypes = { "VECTOR", "VECTOR", "VECTOR" },
        timed = true,
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid ()) then 
                return A:GetUp (), A:GetRight (), A:GetForward ()
            end
            return Vector (0, 0, 0), Vector (0, 0, 0), Vector (0, 0, 0)
        end,
        label = function (Out, A)
            return string.format ("A: %s  Up: (%d,%d,%d) Right: (%d,%d,%d) Forward: (%d,%d,%d)",
                A, Out.Up.x, Out.Up.y, Out.Up.z, Out.Right.x, Out.Right.y, Out.Right.z,
                Out.Forward.x, Out.Forward.y, Out.Forward.z)
        end
    }
// Max Health/Health
    GateActions["entity_health"] = {
        group = "Entity",
        name = "Health",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        outputs = { "Health", "MaxHealth" },
        timed = true,
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid ()) then 
                return A:Health (), A:GetMaxHealth ()
            end
            return 0, 0
        end,
        label = function (Out, A)
            return string.format ("A: %s  Health: %d  Max. Health: %d",
                A, Out.Health, Out.MaxHealth)
        end
    }
// Model
    GateActions["entity_model"] = {
        group = "Entity",
        name = "Model Name",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        outputtypes = { "STRING" },
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid ()) then return A:GetModel () end
            return ""
        end,
        label = function (Out, A)
            return string.format ("A: %s  Model: %s", A, Out)
        end
    }
// Skin/Skin Count
    GateActions["entity_skin"] = {
        group = "Entity",
        name = "Skin Info",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        outputs = { "Skin", "SkinCount" },
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid ()) then 
                return A:GetSkin (), A:SkinCount ()
            end
            return 0, 0
        end,
        label = function (Out, A)
            return string.format ("A: %s  Skin ID: %d  Count: %d",
                A, Out.Skin, Out.SkinCount)
        end
    }
// IsValid
    GateActions["entity_isvalid"] = {
        group = "Entity",
        name = "Is Valid",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        timed = true,
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid ()) then
                return 1
            end
            return 0
        end,
        label = function (Out, A)
            local strNot = "no"
            if (Out == 1) then strNot = "yes" end
            return string.format ("A: %s  Is Valid: %s", A, strNot)
        end
    }
// IsPlayer
    GateActions["entity_isplayer"] = {
        group = "Entity",
        name = "Is Player",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid () and A:IsPlayer ()) then
                return 1
            end
            return 0
        end,
        label = function (Out, A)
            local strNot = "no"
            if (Out == 1) then strNot = "yes" end
            return string.format ("A: %s  Is Player: %s", A, strNot)
        end
    }
// IsConstrained
    GateActions["entity_isconstrained"] = {
        group = "Entity",
        name = "Is Constrained",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        timed = true,
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid () and A:IsConstrained ()) then
                return 1
            end
            return 0
        end,
        label = function (Out, A)
            local strNot = "no"
            if (Out == 1) then strNot = "yes" end
            return string.format ("A: %s  Is Constrained: %s", A, strNot)
        end
    }
// IsInWorld
    GateActions["entity_isinworld"] = {
        group = "Entity",
        name = "Is In World",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        timed = true,
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid () and A:IsInWorld ()) then
                return 1
            end
            return 0
        end,
        label = function (Out, A)
            local strNot = "no"
            if (Out == 1) then strNot = "yes" end
            return string.format ("A: %s  Is In World: %s", A, strNot)
        end
    }
// IsNPC
    GateActions["entity_isnpc"] = {
        group = "Entity",
        name = "Is NPC",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid () and A:IsNPC ()) then
                return 1
            end
            return 0
        end,
        label = function (Out, A)
            local strNot = "no"
            if (Out == 1) then strNot = "yes" end
            return string.format ("A: %s  Is NPC: %s", A, strNot)
        end
    }
// IsOnFire
    GateActions["entity_isonfire"] = {
        group = "Entity",
        name = "Is On Fire",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        timed = true,
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid () and A:IsOnFire ()) then
                return 1
            end
            return 0
        end,
        label = function (Out, A)
            local strNot = "no"
            if (Out == 1) then strNot = "yes" end
            return string.format ("A: %s  Is On Fire: %s", A, strNot)
        end
    }
// IsOnGround
    GateActions["entity_isongrnd"] = {
        group = "Entity",
        name = "Is On Ground",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        timed = true,
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid () and A:IsOnGround ()) then
                return 1
            end
            return 0
        end,
        label = function (Out, A)
            local strNot = "no"
            if (Out == 1) then strNot = "yes" end
            return string.format ("A: %s  Is On Ground: %s", A, strNot)
        end
    }
// IsPlayerHolding
    GateActions["entity_isheld"] = {
        group = "Entity",
        name = "Is Player Holding",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        timed = true,
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid () and A:IsPlayerHolding ()) then
                return 1
            end
            return 0
        end,
        label = function (Out, A)
            local strNot = "no"
            if (Out == 1) then strNot = "yes" end
            return string.format ("A: %s  Is Held By Player: %s", A, strNot)
        end
    }
// IsVehicle
    GateActions["entity_isvehicle"] = {
        group = "Entity",
        name = "Is Vehicle",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid () and A:IsVehicle ()) then
                return 1
            end
            return 0
        end,
        label = function (Out, A)
            local strNot = "no"
            if (Out == 1) then strNot = "yes" end
            return string.format ("A: %s  Is Vehicle: %s", A, strNot)
        end
    }
--[[// IsWeapon
    GateActions["entity_isweapon"] = {
        group = "Entity",
        name = "Is Weapon",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid () and A:IsWeapon ()) then
                return 1
            end
            return 0
        end,
        label = function (Out, A)
            local strNot = "no"
            if (Out == 1) then strNot = "yes" end
            return string.format ("A: %s  Is Weapon: %s", A, strNot)
        end
    }
]]
// Can See
    GateActions["entity_cansee"] = {
        group = "Entity",
        name = "Can See",
        inputs = { "A", "B" },
        inputtypes = { "ENTITY", "ENTITY" },
        timed = true,
        output = function (gate, A, B)
            if (A and IsEntity (A) and A:IsValid () and B and IsEntity (B) and B:IsValid ()) then
                if (A:Visible (B)) then
                    return 1
                end
            end
            return 0
        end,
        label = function (Out, A, B)
            local strNot = "not"
            if (Out == 1) then strNot = "" end
            return string.format ("Entity(%s) can%s see Entity(%s)", A, strNot, B)
        end
    }


//-----------------------------------------------------------------------------
// Player Gates
//-----------------------------------------------------------------------------

// Alive
    GateActions["player_isalive"] = {
        group = "Player",
        name = "Is Alive",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        timed = true,
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid () and A:IsPlayer () and A:Alive ()) then
                return 1
            end
            return 0
        end,
        label = function (Out, A)
            local strNot = "no"
            if (Out == 1) then strNot = "yes" end
            return string.format ("A: %s  Is Alive: %s", A, strNot)
        end
    }
// Armour
    GateActions["player_armour"] = {
        group = "Player",
        name = "Armour",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        timed = true,
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid () and A:IsPlayer ()) then 
                return A:Armor ()
            end
            return 0
        end,
        label = function (Out, A)
            return string.format ("A: %s  Armour: %d", A, Out)
        end
    }
--[[// Chat Print
    GateActions["player_printf"] = {
        group = "Player",
        name = "Chat Print",
        inputs = { "Player", "Message" },
        inputtypes = { "ENTITY", "STRING" },
        outputs = {  },
        output = function (gate, ply, msg)
            local act = GetConVarNumber ("sv_wiregates_chatprint_act")
            // Completely disabled
            if (Act == 0) then return end
            // May only work on spawning player
            if (Act == 1 and gate:GetOwner ():IsPlayer ()) then
                gate:GetOwner ():ChatPrint (msg)
                return
            end
            // Unrestricted usage
            if (Act == 2 and ply and ply:IsPlayer () and msg != "") then 
                ply:ChatPrint (msg)
            end
        end,
        label = function (Out, ply, msg)
            local act = GetConVarNumber ("sv_wiregates_chatprint_act")
            // Completely disabled
            if (act == 0) then
                return "Function Disabled!"
            end
            // Function enabled
            local _ply = nil
            if (act == 1 and gate:GetOwner ():IsPlayer ()) then
                _ply = gate:GetOwner ()
            elseif (act == 2 and ply and ply:IsPlayer ()) then 
                _ply = ply
            end
            // Include target in tooltip
            if (_ply) then
                return "Target: ".._ply:GetName ()
            else
                return "No Target"
            end
        end
    }
]]
// Crouching
    GateActions["player_iscrouching"] = {
        group = "Player",
        name = "Is Crouching",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        timed = true,
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid () and A:IsPlayer () and A:Crouching ()) then
                return 1
            end
            return 0
        end,
        label = function (Out, A)
            local strNot = "no"
            if (Out == 1) then strNot = "yes" end
            return string.format ("A: %s  Is Crouching: %s", A, strNot)
        end
    }
// Death/Kill Count
    GateActions["player_mdk"] = {
        group = "Player",
        name = "Death/Kill Count",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        outputs = { "Deaths", "Kills" },
        timed = true,
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid () and A:IsPlayer ()) then 
                return A:Deaths (), A:Frags ()
            end
            return 0, 0
        end,
        label = function (Out, A)
            return string.format ("A: %s  Kills: %d  Deaths: %d", A, Out.Kills, Out.Deaths)
        end
    }
// Aim Vector
    GateActions["player_aim"] = {
        group = "Player",
        name = "Aim Vector",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        outputtypes = { "VECTOR" },
        timed = true,
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid () and A:IsPlayer ()) then 
                return A:GetAimVector ()
            end
            return Vector (0, 0, 0)
        end,
        label = function (Out, A)
            return string.format ("A: %s  Aim Vector: (%d,%d,%d)",
                A, Out.x, Out.y, Out.z)
        end
    }
// InVehicle
    GateActions["player_invehicle"] = {
        group = "Player",
        name = "Is In Vehicle",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        timed = true,
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid () and A:IsPlayer () and A:InVehicle ()) then
                return 1
            end
            return 0
        end,
        label = function (Out, A)
            local strNot = "no"
            if (Out == 1) then strNot = "yes" end
            return string.format ("A: %s  In Vehicle: %s", A, strNot)
        end
    }
// SteamID
    GateActions["player_steamid"] = {
        group = "Player",
        name = "Steam ID",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        outputtypes = { "STRING" },
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid () and A:IsPlayer ()) then 
                return A:SteamID ()
            end
            return "(null)"
        end,
        label = function (Out, A)
            return string.format ("A: %s  Steam ID: %s", A, Out)
        end
    }
// Team ID/Name
    GateActions["player_team"] = {
        group = "Player",
        name = "Team Details",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        outputs = { "TeamID", "TeamName" },
        outputtypes = { "NORMAL", "STRING" },
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid () and A:IsPlayer ()) then 
                return A:Team (), team.GetName (A:Team ())
            end
            return 0, "(none)"
        end,
        label = function (Out, A)
            return string.format ("A: %s  Team: %s (%d)",
                A, Out.TeamName, Out.TeamID)
        end
    }
// Seconds Connected
    GateActions["player_connected"] = {
        group = "Player",
        name = "Time Connected",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        timed = true,
        output = function (gate, A)
            if (A and IsEntity (A) and A:IsValid () and A:IsPlayer ()) then 
                return A:TimeConnected ()
            end
            return 0
        end,
        label = function (Out, A)
            return string.format ("A: %s  Time Connected: %ds", A, Out)
        end
    }
// Is Locked Onto by [at least one] Target Finder
    GateActions["player_istarget"] = {
        group = "Player",
        name = "Is Locked Onto",
        inputs = { "A" },
        inputtypes = { "ENTITY" },
        timed = true,
        output = function (gate, A)
            if (IsEntity (A) and A:IsValid () and A:IsPlayer ()) then
                if (A.IsLockedOnto and A:IsLockedOnto ()) then
                    return 1
                end
            end
            return 0
        end,
        label = function (Out, A)
            local strNot = "no"
            if (Out == 1) then strNot = "yes" end
            return string.format ("A: %s  In Target: %s", A, strNot)
        end
    }


//-----------------------------------------------------------------------------
// Miscellaneous Gates
//-----------------------------------------------------------------------------

// Vector <-> E-Gate Vector
    GateActions["vector_convtoegate"] = {
        group = "Vector",
        name = "Convert To E-Gate Vector",
        inputs = { "A" },
        inputtypes = { "VECTOR" },
        output = function (gate, A)
            if IsVector (A) then
                WireModVectorIndex = WireModVectorIndex % 90 + 1
                WireModVector[WireModVectorIndex] = v
                return WireModVectorIndex + 9
            end
            return 0
        end,
        label = function (Out, A)
            return string.format ("%s => E-Gate Vector", A)
        end
    }
    GateActions["vector_convfromegate"] = {
        group = "Vector",
        name = "Convert From E-Gate Vector",
        inputs = { "A" },
        inputtypes = { "NORMAL" },
        outputtypes = { "VECTOR" },
        output = function (gate, A)
            local vec = WireModVector[A - 9] or nil
            if (vec and IsVector (vec)) then
                return vec
            end
            return Vector (0, 0, 0)
        end,
        label = function (Out, A, B)
            return string.format ("E-Gate Vector => (%d,%d,%d)", Out.x, Out.y, Out.z)
        end
    }
// Components <-> E-Gate Vector
    GateActions["vector_convtoegate_components"] = {
        group = "Vector",
        name = "Convert Components To E-Gate Vector",
        inputs = { "X", "Y", "Z" },
        inputtypes = { "NORMAL", "NORMAL", "NORMAL" },
        output = function (gate, X, Y, Z)
            WireModVectorIndex = WireModVectorIndex % 90 + 1
            WireModVector[WireModVectorIndex] = Vector (X, Y, Z)
            return WireModVectorIndex + 9
        end,
        label = function (Out, A)
            return string.format ("%s => E-Gate Vector", A)
        end
    }
    GateActions["vector_convfromegate_components"] = {
        group = "Vector",
        name = "Convert Components From E-Gate Vector",
        inputs = { "A" },
        inputtypes = { "NORMAL" },
        outputs = { "X", "Y", "Z" },
        output = function (gate, A)
            local vec = WireModVector[A - 9] or nil
            if (vec and IsVector (vec)) then
                return vec.x, vec.y, vec.z
            end
            return 0, 0, 0
        end,
        label = function (Out, A, B)
            return string.format ("E-Gate Vector => X:%d Y:%d Z:%d", Out.X, Out.Y, Out.Z)
        end
    }
// String <-> E-Gate Packet
    GateActions["string_convtoegate"] = {
        group = "String",
        name = "Convert String To E-Gate Packet",
        inputs = { "A" },
        inputtypes = { "STRING" },
        output = function (gate, A)
            if (A and A != "") then
                return WireGateExpressionSendPacket (string.byte (A, 1, string.len (A)))
            end
            return 0
        end,
        label = function (Out, A)
            return string.format ("%s => E-Gate Packet", A)
        end
    }
    GateActions["string_convfromegate"] = {
        group = "String",
        name = "Convert String From E-Gate Packet",
        inputs = { "A" },
        inputtypes = { "NORMAL" },
        outputtypes = { "STRING" },
        output = function (gate, A)
            A = A - 9
            if (WireModPacket[A]) then
                local str = { string.char (unpack (WireModPacket[A])) }
                return string.Implode ("", str)
            end
            return ""
        end,
        label = function (Out, A)
            return string.format ("E-Gate Packet => %s", Out)
        end
    }
    
    // Sort these gates correctly
    for name,gate in pairs(GateActions) do
        if !WireGatesSorted[gate.group] then WireGatesSorted[gate.group] = {} end
        WireGatesSorted[gate.group][name] = gate
    end
end


// Prevent this from loading before default wiregates and/or wiremod
timer.Simple (1, AddWireGates_DuFace)

//*/
