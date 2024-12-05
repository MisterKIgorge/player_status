local StatsList = {}
local function AddStatusData(id, data)
    assert(type(id) == "string", "ID is unknown " .. (data.tooltip or ""))

    local StatusData = {}
    for opt, val in pairs(data) do
        StatusData[opt] = val
    end
    StatusData.id = id

    local pos = data.pos or #StatsList + 1
    table.insert(StatsList, pos, StatusData)

    if not StatusData.tooltip and STRINGS.PLAYER_STAT_DISPLAYER and STRINGS.PLAYER_STAT_DISPLAYER[string.upper(id)] then
        StatusData.tooltip = STRINGS.PLAYER_STAT_DISPLAYER[string.upper(id)]
    end

    if TheGlobalInstance then
        TheGlobalInstance:PushEvent("new_statdata")
    end
end

local function GetStatusData()
    return StatsList
end

local function EmitateAttack(inst)
    local ent = CreateEntity()
    ent.prefab = "DEBUG_DAMAGE"
    ent.entity:AddTransform()
    ent.Transform:SetPosition(999999, 0, 0)
    ent:AddComponent("combat")
    ent.components.combat:SetBaseDamage(ent, 0)
    ent:DoTaskInTime(0, ent.Remove)

    local base_damage = inst.components.combat:GetBaseDamage()
    local attack = Attack(inst, ent)
            :SetDamage(base_damage) 
            :SetTarget(ent) -- Сделать атакующим не игрока, а его копию, а иначе вернуть deepcopy
        
    return attack
end

local function PowersDamageCalc(inst, crit)
    local base_damage = inst.components.combat:GetBaseDamage()
    local attack = EmitateAttack(inst)
    local powers = inst.components.powermanager:GetAllPowersInAcquiredOrder() 
    local outputs = {
        damage_delta = base_damage,
    }

    for _, pow in pairs(powers) do 
        if pow.def.damage_mod_fn then 
            pow.def.damage_mod_fn(pow, attack, outputs)
        end 
    end 

    local val = crit and (attack:GetCrit() and 1 or attack:GetTotalCritChance()) or
        (outputs.damage_delta == base_damage and 0 or (outputs.damage_delta / base_damage - 1) * 100)

    return val
end

local function PowersDefenceCalc(inst)
    local base_damage = inst.components.combat:GetBaseDamage()
    local attack = EmitateAttack(inst)
    local powers = inst.components.powermanager:GetAllPowersInAcquiredOrder() 
    local outputs = {
        damage_delta = 0,
    }

    for _, pow in pairs(powers) do 
        if pow.def.defend_mod_fn then 
            pow.def.defend_mod_fn(pow, attack, outputs)
        end
    end 
    
    return outputs.damage_delta
end

return {
    AddStatusData = AddStatusData,
    GetStatusData = GetStatusData,

    EmitateAttack = EmitateAttack,
    PowersDamageCalc = PowersDamageCalc,
    PowersDefenceCalc = PowersDefenceCalc,
}
