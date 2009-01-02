TOOL.Category		= "Wire - Detection"
TOOL.Name		= "Money Detector"
TOOL.Command		= nil
TOOL.ConfigName		= nil
TOOL.Model		= "models/props_combine/breenclock.mdl"

cleanup.Register("wire_moneydetector")

if CLIENT then
	language.Add("Tool_wire_moneydetector_name", "Wire Money Detector Tool")
	language.Add("Tool_wire_moneydetector_desc", "Spawns a wire money detector")
	language.Add("Tool_wire_moneydetector_0", "Left click to place the detector.")
	language.Add("Undone_WireMoneyDetector", "Wire Money Detector undone")
	language.Add("SBoxLimit_wire_moneydetector", "You've hit the Wire Money Detector limit!")
end

if SERVER then
        CreateConVar('sbox_maxwire_moneydetector', 20)

        function MakeWireMoneyDetector(pl, Model, Ang, Pos)
                if not pl:CheckLimit( "wire_moneydetector" ) then return false end

                local wmd = ents.Create("gmod_wire_moneydetector")

                if not ValidEntity(wmd) then return nil end
                wmd:SetPos(Pos)
		wmd:SetAngles(Ang)
                wmd:SetModel(Model)
                wmd:Spawn()
                wmd:SetPlayer(pl)

                if wmd:GetPhysicsObject():IsValid() then
                        local Phys = wmd:GetPhysicsObject()
                        Phys:EnableMotion(not frozen)
                end

                local ttable = {
                        pl = pl
                }
                table.Merge(wmd:GetTable(), ttable)

                pl:AddCount("wire_moneydetector", wmd)
                pl:AddCleanup("wire_moneydetector", wmd)

                return wmd
        end

        duplicator.RegisterEntityClass("gmod_wire_moneydetector", MakeWireMoneyDetector, "Model", "Ang", "Pos")
end

function TOOL:LeftClick(trace)
	if not trace.HitPos or trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end

	local ply = self:GetOwner()

	if not self:GetSWEP():CheckLimit("wire_moneydetector") then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local moneydetector = MakeWireMoneyDetector(ply, self.Model, Ang, trace.HitPos)

	local min = moneydetector:OBBMins()
	moneydetector:SetPos(trace.HitPos - trace.HitNormal * min.z)

	local const, nocollide
	if trace.Entity:IsValid() then
		const, nocollide = constraint.Weld(moneydetector, trace.Entity, 0, trace.PhysicsBone, 0, true)
	end

	moneydetector.Entity:GetPhysicsObject():SetMass(3)
	duplicator.StoreEntityModifier(moneydetector, "MassMod", {Mass = 3})

	undo.Create("WireMoneyDetector")
		undo.AddEntity(moneydetector)
		undo.AddEntity(const)
		undo.SetPlayer(ply)
	undo.Finish()
	
	ply:AddCleanup("wire_moneydetector", moneydetector)
	ply:AddCleanup("wire_moneydetector", const)

	return true
end

function TOOL:UpdateGhostWireMoneyDetector(ent, player)
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

	self:UpdateGhostWireMoneyDetector(self.GhostEntity, self:GetOwner())
end

function TOOL.BuildCPanel(panel)
        panel:AddControl("Header", {
		Text = "#Tool_wire_moneydetector_name",
		Description = "#Tool_wire_moneydetector_desc"
	})

        ModelPlug_AddToCPanel(panel, "moneydetector", "wire_moneydetector", "#WireMoneyDetectorTool_model", nil, "#WireMoneyDetectorTool_model")
end
