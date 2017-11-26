local assets =
{
    Asset("ANIM", "anim/staffs.zip"),
    Asset("ANIM", "anim/swap_staffs.zip"),
}

local prefabs =
{
    blue =
    {
        "ice_projectile",
    },

    red =
    {
        "fire_projectile",
        "cutgrass",
    },

    --purple = nil,

    orange =
    {
        "sand_puff_large_front",
        "sand_puff_large_back",
        "reticule",
    },

    green =
    {
        "splash_ocean",
        "collapse_small",
    },

    yellow =
    {
        "stafflight",
        "reticule",
    },

    opal =
    {
        "staffcoldlight",
        "reticule",
    },
}

---------BLUE STAFF---------

local function onattack_blue(inst, attacker, target, skipsanity)
    if not skipsanity and attacker ~= nil and attacker.components.sanity ~= nil then
        attacker.components.sanity:DoDelta(-TUNING.SANITY_SUPERTINY)
    end

    if not target:IsValid() then
        --target killed or removed in combat damage phase
        return
    end

	if attacker.components.leader ~= nil then
		-- attacker.components.leader:OnNewTarget(target)
		for k, v in pairs(attacker.components.leader.followers) do
        if k.components.combat ~= nil and k.components.follower ~= nil and k.components.follower.canaccepttarget then
            k.components.combat:SetTarget(target)
        end
    end
	end
	
    -- if target.components.sleeper ~= nil and target.components.sleeper:IsAsleep() then
        -- target.components.sleeper:WakeUp()
    -- end

    -- if target.components.combat ~= nil then
        -- target.components.combat:SuggestTarget(attacker)
    -- end

    -- if target.sg ~= nil and not target.sg:HasStateTag("frozen") then
        -- target:PushEvent("attacked", { attacker = attacker, damage = 0, weapon = inst })
    -- end

    -- if target.components.freezable ~= nil then
        -- target.components.freezable:AddColdness(1)
        -- target.components.freezable:SpawnShatterFX()
    -- end
end

local function onhauntblue(inst, haunter)
    if math.random() <= TUNING.HAUNT_CHANCE_RARE then
        local x, y, z = inst.Transform:GetWorldPosition() 
        local ents = TheSim:FindEntities(x, y, z, 6, { "freezable" }, { "INLIMBO" })
        if #ents > 0 then
            for i, v in ipairs(ents) do
                if v:IsValid() and not v:IsInLimbo() then
                    onattack_blue(inst, haunter, v, true) 
                end
            end
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_LARGE
            return true
        end
    end
    return false
end

---------COMMON FUNCTIONS---------

local function onfinished(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
    inst:Remove()
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function onunequip_skinned(inst, owner)
    if inst:GetSkinBuild() ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    onunequip(inst, owner)
end

local function commonfn(colour, tags, hasskin)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("staffs")
    inst.AnimState:SetBuild("staffs")
    inst.AnimState:PlayAnimation(colour.."staff")

    if tags ~= nil then
        for i, v in ipairs(tags) do
            inst:AddTag(v)
        end
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -------
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(onfinished)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("tradable")

    inst:AddComponent("equippable")

    if hasskin then
        inst.components.equippable:SetOnEquip(function(inst, owner)
            local skin_build = inst:GetSkinBuild()
            if skin_build ~= nil then
                owner:PushEvent("equipskinneditem", inst:GetSkinName())
                owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "swap_"..colour.."staff", inst.GUID, "swap_staffs")
            else
                owner.AnimState:OverrideSymbol("swap_object", "swap_staffs", "swap_"..colour.."staff")
            end
            owner.AnimState:Show("ARM_carry")
            owner.AnimState:Hide("ARM_normal")
        end)
        inst.components.equippable:SetOnUnequip(onunequip_skinned)
    else
        inst.components.equippable:SetOnEquip(function(inst, owner)
            owner.AnimState:OverrideSymbol("swap_object", "swap_staffs", "swap_"..colour.."staff")
            owner.AnimState:Show("ARM_carry")
            owner.AnimState:Hide("ARM_normal")
        end)
        inst.components.equippable:SetOnUnequip(onunequip)
    end

    return inst
end

---------COLOUR SPECIFIC CONSTRUCTIONS---------

local function blue()
    local inst = commonfn("blue", { "icestaff", "rangedweapon", "extinguisher" }, true)

    inst.projectiledelay = FRAMES

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(0)
    inst.components.weapon:SetRange(15, 10)
    inst.components.weapon:SetOnAttack(onattack_blue)
    inst.components.weapon:SetProjectile(nil)

    inst.components.finiteuses:SetMaxUses(TUNING.ICESTAFF_USES)
    inst.components.finiteuses:SetUses(TUNING.ICESTAFF_USES)

    MakeHauntableLaunch(inst)
    AddHauntableCustomReaction(inst, onhauntblue, true, false, true)

    return inst
end

return Prefab("commandstaff", blue, assets, prefabs.blue)
    -- Prefab("firestaff", red, assets, prefabs.red),
    -- Prefab("telestaff", purple, assets, prefabs.purple),
    -- Prefab("orangestaff", orange, assets, prefabs.orange),
    -- Prefab("greenstaff", green, assets, prefabs.green),
    -- Prefab("yellowstaff", yellow, assets, prefabs.yellow),
    -- Prefab("opalstaff", opal, assets, prefabs.opal)
