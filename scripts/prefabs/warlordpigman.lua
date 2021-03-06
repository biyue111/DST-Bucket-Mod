local assets =
{
    Asset("ANIM", "anim/ds_pig_basic.zip"),
    Asset("ANIM", "anim/ds_pig_actions.zip"),
    Asset("ANIM", "anim/pig_build.zip"),
    Asset("ANIM", "anim/pigspotted_build.zip"),
    Asset("SOUND", "sound/pig.fsb"),
}

local prefabs =
{
    "featherhat",
    "goldnugget"
}

for i = 1, NUM_HALLOWEENCANDY do
    table.insert(prefabs, "halloweencandy_"..i)
end

local function launchitem(item, giver, angle)
    if not giver.components.inventory:IsFull() then
      giver.components.inventory:GiveItem(item)
    else
      local speed = math.random() * 4 + 2
      angle = (angle + math.random() * 60 - 30) * DEGREES
      item.Physics:SetVel(speed * math.cos(angle), math.random() * 2 + 8, speed * math.sin(angle))
    end
end

local function ontradeforgold(inst, item, giver)
    inst.SoundEmitter:PlaySound("dontstarve/pig/attack")

--    local x, y, z = inst.Transform:GetWorldPosition()
--    y = 4.5
--
--    local angle
--    if giver ~= nil and giver:IsValid() then
--        angle = 180 - giver:GetAngleToPoint(x, 0, z)
--    else
--        local down = TheCamera:GetDownVec()
--        angle = math.atan2(down.z, down.x) / DEGREES
--        giver = nil
--    end
--
--    for k = 1, item.components.tradable.goldvalue do
--        local nug = SpawnPrefab("goldnugget")
--        nug.Transform:SetPosition(x, y, z)
--        launchitem(nug, giver,angle)
--    end

	-- spawn soldierpigman
	local x, y, z = inst.Transform:GetWorldPosition()
	local angle = inst.Transform:GetRotation() / DEGREES
	local soldierpigman = SpawnPrefab("soldierpigman")
	if soldierpigman ~= nil then
		local rad = soldierpigman:GetPhysicsRadius(0) + inst:GetPhysicsRadius(0) + .25
		soldierpigman.Transform:SetPosition(x + rad * math.cos(angle), 0, z + rad * math.sin(angle))
		giver.components.leader:AddFollower(soldierpigman)
		soldierpigman.components.follower:AddLoyaltyTime(TUNING.PIG_LOYALTY_MAXTIME)
        soldierpigman.components.follower.maxfollowtime =
        giver:HasTag("polite")
        and TUNING.PIG_LOYALTY_MAXTIME + TUNING.PIG_LOYALTY_POLITENESS_MAXTIME_BONUS
        or TUNING.PIG_LOYALTY_MAXTIME
	end
  inst.AnimState:PlayAnimation("idle_angry")
  inst.AnimState:PushAnimation("idle_loop", true)

--    if item.components.tradable.tradefor ~= nil then
--        for _, v in pairs(item.components.tradable.tradefor) do
--            local item = SpawnPrefab(v)
--            if item ~= nil then
--                item.Transform:SetPosition(x, y, z)
--                launchitem(item, giver,angle)
--            end
--        end
--    end

--    if IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS) then
--        -- pick out up to 3 types of candies to throw out
--        local candytypes = { math.random(NUM_HALLOWEENCANDY), math.random(NUM_HALLOWEENCANDY), math.random(NUM_HALLOWEENCANDY) }
--        local numcandies = (item.components.tradable.halloweencandyvalue or 1) + math.random(2) + 2
--
--        -- only people in costumes get a good amount of candy!      
--        if giver ~= nil and giver.components.skinner ~= nil then
--            for _, item in pairs(giver.components.skinner:GetClothing()) do
--				if DoesItemHaveTag(item, "COSTUME") then
--					numcandies = numcandies + math.random(4) + 2
--					break
--				end
--            end
--        end
--
--        for k = 1, numcandies do
--            local candy = SpawnPrefab("halloweencandy_"..GetRandomItem(candytypes))
--            candy.Transform:SetPosition(x, y, z)
--            launchitem(candy, giver, angle)
--        end
--    end    
end

local function onplayhappysound(inst)
    inst.SoundEmitter:PlaySound("dontstarve/pig/PigKingHappy")
end

local function onendhappytask(inst)
    inst.happy = false
    inst.endhappytask = nil
end

local function OnGetItemFromPlayer(inst, giver, item)
    local is_event_item = IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS) and item.components.tradable.halloweencandyvalue and item.components.tradable.halloweencandyvalue > 0

    --if item.components.tradable.goldvalue > 0 or is_event_item then
	if item.components.edible.foodtype == FOODTYPE.ELEMENTAL and item.components.edible.hungervalue == 2 then
	-- get gold nugget from player
        inst:DoTaskInTime(20/30, ontradeforgold, item, giver)
        inst:DoTaskInTime(1.5, onplayhappysound)
        inst.happy = true
        if inst.endhappytask ~= nil then
            inst.endhappytask:Cancel()
        end
        inst.endhappytask = inst:DoTaskInTime(5, onendhappytask)
    end
end

local function OnRefuseItem(inst, giver, item)
    inst.SoundEmitter:PlaySound("dontstarve/pig/PigKingReject")
    inst.happy = false
    inst:FacePoint(giver:GetPosition())
    inst.AnimState:PlayAnimation("pig_reject")
    inst.AnimState:PushAnimation("idle_loop", true)
end

local function AcceptTest(inst, item)
    local is_event_item = IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS) and item.components.tradable.halloweencandyvalue and item.components.tradable.halloweencandyvalue > 0
	local is_goldnugget = item.components.edible.foodtype == FOODTYPE.ELEMENTAL and item.components.edible.hungervalue == 2
    return is_event_item or is_goldnugget --or item.components.tradable.goldvalue > 0 
end

--local function OnIsNight(inst, isnight)
--    if isnight then
--        inst.components.trader:Disable()
--        inst.AnimState:PlayAnimation("sleep_pre")
--        inst.AnimState:PushAnimation("sleep_loop", true)
--    else
--        inst.components.trader:Enable()
--        inst.AnimState:PlayAnimation("sleep_pst")
--        inst.AnimState:PushAnimation("idle", true)
--    end
--end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(1.5, .75)
    inst.Transform:SetFourFaced()
    
    MakeObstaclePhysics(inst, 1, .5)

    --inst.Transform:SetScale(1.5, 1.5, 1.5)

    inst:AddTag("pig")
    inst:AddTag("scarytoprey")
    inst.AnimState:SetBank("pigman")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:Hide("hat")
    inst.AnimState:SetBuild("pig_build")

    --trader (from trader component) added to pristine state for optimization
    inst:AddTag("trader")

    inst:AddTag("antlion_sinkhole_blocker")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("trader")

    inst.components.trader:SetAcceptTest(AcceptTest)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem
    
    inst:AddComponent("named")
    inst.components.named.possiblenames = STRINGS.PIGNAMES
    inst.components.named:PickNewName()

--    inst:WatchWorldState("isnight", OnIsNight)
--    OnIsNight(inst, TheWorld.state.isnight)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        if inst.components.trader and inst.components.trader.enabled then
            OnRefuseItem(inst)
            return true
        end
        return false
    end)
  
    inst:AddComponent("inventory")
    local featherhat = SpawnPrefab("featherhat")
    inst.components.inventory:Equip(featherhat)
    inst.AnimState:Show("hat")

    return inst
end

return Prefab("warlordpigman", fn, assets, prefabs)
