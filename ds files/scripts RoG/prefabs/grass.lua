local assets=
{
	Asset("ANIM", "anim/grass.zip"),
	Asset("ANIM", "anim/grass1.zip"),
	Asset("SOUND", "sound/common.fsb"),
}


local prefabs =
{
    "cutgrass",
    "dug_grass",
}    

local function ontransplantfn(inst)
	if inst.components.pickable then
		inst.components.pickable:MakeBarren()
	end
end

local function dig_up(inst, chopper)
	if inst.components.pickable and inst.components.pickable:CanBePicked() then
		inst.components.lootdropper:SpawnLootPrefab("cutgrass")
	end
	if inst.components.pickable and not inst.components.pickable.withered then
		local bush = inst.components.lootdropper:SpawnLootPrefab("dug_grass")
	else
		inst.components.lootdropper:SpawnLootPrefab("cutgrass")
	end
	inst:Remove()
end

local function onregenfn(inst)
	inst.AnimState:PlayAnimation("grow") 
	inst.AnimState:PushAnimation("idle", true)
end

local function makeemptyfn(inst)
	if inst.components.pickable and inst.components.pickable.withered then
		inst.AnimState:PlayAnimation("dead_to_empty")
		inst.AnimState:PushAnimation("picked")
	else
		inst.AnimState:PlayAnimation("picked")
	end
end

local function makebarrenfn(inst)
	if inst.components.pickable and inst.components.pickable.withered then
		if not inst.components.pickable.hasbeenpicked then
			inst.AnimState:PlayAnimation("full_to_dead")
		else
			inst.AnimState:PlayAnimation("empty_to_dead")
		end
		inst.AnimState:PushAnimation("idle_dead")
	else
		inst.AnimState:PlayAnimation("idle_dead")
	end
end


local function onpickedfn(inst)
	inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds") 
	inst.AnimState:PlayAnimation("picking") 
	
	if inst.components.pickable and inst.components.pickable:IsBarren() then
		inst.AnimState:PushAnimation("idle_dead")
	else
		inst.AnimState:PushAnimation("picked")
	end

end


local function makefn(stage)
	local function fn(Sim)
		local inst = CreateEntity()
		local trans = inst.entity:AddTransform()
		local anim = inst.entity:AddAnimState()
	    local sound = inst.entity:AddSoundEmitter()
		local minimap = inst.entity:AddMiniMapEntity()

		minimap:SetIcon( "grass.png" )
	    
	    anim:SetBank("grass")
	    anim:SetBuild("grass1")
	    anim:PlayAnimation("idle",true)
	    anim:SetTime(math.random()*2)
	    local color = 0.75 + math.random() * 0.25
	    anim:SetMultColour(color, color, color, 1)

		inst:AddComponent("pickable")
		inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"
		
		inst.components.pickable:SetUp("cutgrass", TUNING.GRASS_REGROW_TIME)
		inst.components.pickable.onregenfn = onregenfn
		inst.components.pickable.onpickedfn = onpickedfn
		inst.components.pickable.makeemptyfn = makeemptyfn
		inst.components.pickable.makebarrenfn = makebarrenfn
		inst.components.pickable.max_cycles = 20
		inst.components.pickable.cycles_left = 20   
		inst.components.pickable.ontransplantfn = ontransplantfn

		local variance = math.random() * 4 - 2
		inst.makewitherabletask = inst:DoTaskInTime(TUNING.WITHER_BUFFER_TIME + variance, function(inst) inst.components.pickable:MakeWitherable() end)

	    if stage == 1 then
			inst.components.pickable:MakeBarren()
		end

		inst:AddComponent("lootdropper")
	    inst:AddComponent("inspectable")    
	    
		inst:AddComponent("workable")
	    inst.components.workable:SetWorkAction(ACTIONS.DIG)
	    inst.components.workable:SetOnFinishCallback(dig_up)
	    inst.components.workable:SetWorkLeft(1)
	    
	    ---------------------        

	    MakeMediumBurnable(inst)
	    MakeSmallPropagator(inst)
	    inst.components.burnable:MakeDragonflyBait(1)

		MakeNoGrowInWinter(inst)  
		  
	    ---------------------   
	    
	    return inst
	end

    return fn
end    


local function grass(name, stage)
    return Prefab("forest/objects/"..name, makefn(stage), assets, prefabs)
end

return grass("grass", 0),
		grass("depleted_grass", 1) 
