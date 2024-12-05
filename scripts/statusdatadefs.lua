local StatusDefs = require ("statusdata")
local AddStatusData = StatusDefs.AddStatusData
local PowersDamageCalc = StatusDefs.PowersDamageCalc

AddStatusData("damage", { -- "Damage mult"
    fn = function(inst)
        return PowersDamageCalc(inst)
    end,

    events = {"activate_skill", "add_state_tag", "attack_end", "attack_start", "death", "do_damage", "dodge", "dodge_cancel", "dying", "enter_room", "exit_room", "foley_footstep", "hammer_thumped", "healthchanged", "heavy_attack", "hitboxcollided_invincible", "hitboxtriggered", "hitstreak", "hitstreak_killed", "juggernaut_force_remove", "kill", "light_attack", "parry", "power_charged_damage", "power_stacks_changed", "projectile_launched", "remove_state_tag", "revive", "shotput_landed", "start_gameplay", "take_damage", "take_heal", "timerdone"},

    image = "images/icons_ftf/inventory_weapon_hammer.tex",
    ispercent = true,
})

AddStatusData("crit_chance", { -- "Critical Chance"
    fn = function(inst)
        return (math.min(1, PowersDamageCalc(inst, true))) * 100
    end,
    
    events = {"speed_mult_changed", "crit_chance_changed", "hitboxcollided_invincible", "light_attack", "heavy_attack"},

    image = "images/icons_ftf/stat_crit_chance.tex",
    ispercent = true,
})

AddStatusData("armor", { -- "Armor"
    fn = function(inst)
        local dungeon_tier_damage_mult = math.max(TUNING.GEAR.MINIMUM_DUNGEONTIER_DAMAGE_MULT, 1.15 - inst.components.combat.dungeontierdamagereductionmult:Get())
        return (1 - dungeon_tier_damage_mult) * 100 
    end,
    
    events = {"loadout_changed"},
    -- accuracy = 0, -- 0 number after ',' example: 3.5 -> 4

    image = "images/icons_ftf/inventory_head.tex",
    ispercent = true,
})

AddStatusData("speed", { -- "Speed mult"
    fn = function(inst)
        return (inst.components.locomotor.total_speed_mult - 1) * 100
    end,
    
    events = {"speed_mult_changed"},

    image = "images/icons_ftf/inventory_legs.tex",
    ispercent = true,
})

-- for i = 1, 128 do
--     AddStatusData("n_" .. i, {
--         fn = function(inst)
--             return math.random(1, 100)
--         end,

--         events = {"activate_skill", "add_state_tag", "attack_end", "attack_start", "death", "do_damage", "dodge", "dodge_cancel", "dying", "enter_room", "exit_room", "foley_footstep", "hammer_thumped", "healthchanged", "heavy_attack", "hitboxcollided_invincible", "hitboxtriggered", "hitstreak", "hitstreak_killed", "juggernaut_force_remove", "kill", "light_attack", "parry", "power_charged_damage", "power_stacks_changed", "projectile_launched", "remove_state_tag", "revive", "shotput_landed", "start_gameplay", "take_damage", "take_heal", "timerdone"},

--         tooltip = "n_" .. math.random(),
--         image = "images/icons_ftf/inventory_weapon_hammer.tex",
--         ispercent = true,
--     })
-- end