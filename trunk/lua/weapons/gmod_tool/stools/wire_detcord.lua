TOOL.Category		= "Wire - Physics"
TOOL.Name		= "Detonation Cord"
TOOL.Command		= nil
TOOL.ConfigName		= nil
TOOL.Model		= "models/Items/CrossbowRounds.mdl"

TOOL.ClientConVar[ "range" ] = 120
TOOL.ClientConVar[ "nocollide" ] = 0

cleanup.Register("wire_detcord")

if CLIENT then
	language.Add("Tool_wire_detcord_name", "Wired Detonation Cord Tool")
	language.Add("Tool_wire_detcord_desc", "Spawns a wire detcord explosive for building demolition")
	language.Add("Tool_wire_detcord_0", "Left click to place the cord.")
	language.Add("WireDetcordTool_range", "Range:")
	language.Add("WireDetcordTool_nocollide", "No collide all but world:")
	language.Add("Undone_WireDetcord", "Wired Detonation Cord undone")
	language.Add("SBoxLimit_wire_detcord", "You've hit the Wired Detcord limit!")
end

if SERVER then
        CreateConVar('sbox_maxwire_detcord', 20)

        function MakeWireDetcord(pl, Model, Ang, Pos, range)
                if not pl:CheckLimit( "wire_detcord" ) then return false end

                local wdc = ents.Create("gmod_wire_detcord")

		if not wdc then
			print("WDC is nil")
		end


                if not ValidEntity(wdc) then return nil end
		wdc:Setup()
                wdc:SetPos(Pos)
		wdc:SetAngles(Ang)
                wdc:SetRange(range)
                wdc:SetModel(Model)
                wdc:Spawn()
                wdc:SetPlayer(pl)

                if wdc:GetPhysicsObject():IsValid() then
                        local Phys = wdc:GetPhysicsObject()
                        Phys:EnableMotion(not frozen)
                end

                local ttable = {
                        pl = pl,
                        range = range
                }
                table.Merge(wdc:GetTable(), ttable)

                pl:AddCount("wire_detcord", wdc)
                pl:AddCleanup("wire_detcord", wdc)

                return wdc
        end

        duplicator.RegisterEntityClass("gmod_wire_detcord", MakeWireDetcord, "Model", "Ang", "Pos", "range")
end

function TOOL:LeftClick(trace)
	if not trace.HitPos or trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end

	local ply = self:GetOwner()

	if not ply:IsAdmin() and not ply:IsSuperAdmin() then
		ply:PrintMessage(2, "This STOOL is Admin-only!")
		return false
	end

	if not self:GetSWEP():CheckLimit("wire_detcord") then return false end

	local range = self:GetClientNumber("range")

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local detcord = MakeWireDetcord(ply, self.Model, Ang, trace.HitPos, range)

	local min = detcord:OBBMins()
	detcord:SetPos(trace.HitPos - trace.HitNormal * min.z)

	local const, nocollide
	if trace.Entity:IsValid() then
		const, nocollide = constraint.Weld(detcord, trace.Entity, 0, trace.PhysicsBone, 0, collision == 0, true)
	end

	detcord.Entity:GetPhysicsObject():SetMass(3)
	duplicator.StoreEntityModifier(detcord, "MassMod", {Mass = 3})

	undo.Create("WireDetcord")
		undo.AddEntity(detcord)
		undo.AddEntity(const)
		undo.SetPlayer(ply)
	undo.Finish()
	
	ply:AddCleanup("wire_detcord", detcord)
	ply:AddCleanup("wire_detcord", const)

	return true
end

function TOOL:UpdateGhostWireDetcord(ent, player)
	if not ent or not ent:IsValid() then return end

	local tr = utilx.GetPlayerTrace(player, player:GetCursorAimVector())
	local trace = util.TraceLine(tr)

	if not trace.Hit or trace.Entity:IsPlayer() then
		ent:SetNoDraw(true)
		return
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local min = ent:OBBMins()
	ent:SetPos(trace.HitPos - trace.HitNormal * min.z)
	ent:SetAngles(Ang)

	ent:SetNoDraw(false)
end

function TOOL:Think()
	if not self.GhostEntity or not self.GhostEntity:IsValid() or self.GhostEntity:GetModel() ~= self.Model then
		if not self.Model then return end

		self:MakeGhostEntity(self.Model, Vector(0,0,0), Angle(0,0,0))
	end

	self:UpdateGhostWireDetcord(self.GhostEntity, self:GetOwner())
end

function TOOL.BuildCPanel(panel)
        panel:AddControl("Header", {
		Text = "#Tool_wire_detcord_name",
		Description = "#Tool_wire_detcord_desc"
	})

	panel:AddControl("Slider", {
        	Label = "#WireDetcordTool_range",
                Type = "Integer",
                Min = 0,
                Max = 200,
                Command = "wire_detcord_range"
        })

        ModelPlug_AddToCPanel(panel, "detcord", "wire_detcord", "#WireDetcordTool_model", nil, "#WireDetcordTool_model")
end
