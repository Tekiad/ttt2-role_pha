if SERVER then
	AddCSLuaFile()
else -- CLIENT
	SWEP.PrintName = "ankh_name"
	SWEP.Slot = 7

	SWEP.ViewModelFOV = 10
	SWEP.ViewModelFlip = false
	SWEP.DrawCrosshair = false

	SWEP.EquipMenuData = {
		type = "item_weapon",
		desc = "ankh_desc"
	}

	SWEP.Icon = "vgui/ttt/icon_ankh"
end

SWEP.Base = "weapon_tttbase"

SWEP.HoldType = "normal"

SWEP.ViewModel = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/props_lab/reciever01b.mdl"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 1.0

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Delay = 1.0

SWEP.Kind = WEAPON_EQUIP2
SWEP.CanBuy = nil
SWEP.LimitedStock = true -- only buyable once

SWEP.AllowDrop = false
SWEP.NoSights = true

function SWEP:OnDrop()
	self:Remove()
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	if SERVER then
		self:AnkhStick()
	end
end

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)

	if SERVER then
		self:AnkhStick()
	end
end

if SERVER then
	function SWEP:AnkhStick()
		local ply = self:GetOwner()

		if not IsValid(ply) or self.Planted then return end

		local ignore = {ply, self}
		local spos = ply:GetShootPos()
		local epos = spos + ply:GetAimVector() * 100

		local tr = util.TraceLine({
			start = spos,
			endpos = epos,
			filter = ignore,
			mask = MASK_SOLID
		})

		if not tr.HitWorld then return end

		-- only allow placement on level ground
		local dot_a_b = tr.HitNormal:Dot(Vector(0, 0, 1))
		local len_a = tr.HitNormal:Length()
		local angle = math.acos(dot_a_b / len_a)

		if angle ~= 0 then return end

		local ankh = ents.Create("ttt_ankh")
		if not IsValid(ankh) then return end

		ankh:PointAtEntity(ply)

		local tr_ent = util.TraceEntity({
			start = spos,
			endpos = epos,
			filter = ignore,
			mask = MASK_SOLID
		}, ankh)

		if not tr_ent.HitWorld then return end

		local ang = tr_ent.HitNormal:Angle()

		ankh:SetPos(tr_ent.HitPos + ang:Forward() * 2.5)
		ankh:SetAngles(ang)
		ankh:SetOwner(ply)
		ankh:Spawn()

		local phys = ankh:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion(false)
		end

		ankh.IsOnWall = true

		self:PlacedAnkh(ankh)
	end
end

function SWEP:PlacedAnkh(ankh)
	-- start ankh handling
	PHARAOH_HANDLER:PlacedAnkh(self:GetOwner())

	self:GetOwner().ankh = ankh

	self:TakePrimaryAmmo(1)

	if not self:CanPrimaryAttack() then
		self:Remove()

		self.Planted = true
	end

end

function SWEP:Reload()
	return false
end

if CLIENT then
	function SWEP:OnRemove()
		if not IsValid(self:GetOwner()) or self:GetOwner() ~= LocalPlayer() or not self:GetOwner():Alive() then return end

		RunConsoleCommand("lastinv")
	end

	function SWEP:Initialize()
		self:AddHUDHelp("ankh_help_pri", nil, true)

		return self.BaseClass.Initialize(self)
	end
end

function SWEP:Deploy()
	self:GetOwner():DrawViewModel(false)

	return true
end

function SWEP:DrawWorldModel()
	if IsValid(self:GetOwner()) then return end

	self:DrawModel()
end

function SWEP:DrawWorldModelTranslucent()

end
