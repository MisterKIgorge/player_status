local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"

local list_spacing = 40
local icon_scale = 0.85
local text_scale = 1
local icon_opacity = 1
local text_opacity = 1

local stats_data = {}
function GLOBAL.stats_AddStatsData(image, events, tooltip, val, ispercent, d_pos)
    if stats_data[d_pos] then
        local _stats_data = GLOBAL.deepcopy(stats_data) -- замена
        for i = #stats_data, d_pos, -1 do 
            stats_data[i + 1] = _stats_data[i]
        end
    end
    stats_data[d_pos or #stats_data + 1] = {
        image = image,
        events = events,
        tooltip = tooltip,
        val = val,
        ispercent = ispercent,
    }
    GLOBAL.TheGlobalInstance:PushEvent("new_statdata")
end

local function FakeAttack(inst)
    local ent = GLOBAL.CreateEntity()
    ent.prefab = "DEBUG_DAMAGE"
    ent.entity:AddTransform()
    ent.Transform:SetPosition(999999, 0, 0)
    ent:AddComponent("combat")
    ent.components.combat:SetBaseDamage(ent, 0)
    ent:DoTaskInTime(0, ent.Remove)

    local base_damage = inst.components.combat.basedamage:Get()
    local attack = GLOBAL.Attack(inst, ent)
            :SetDamage(base_damage) 
            :SetTarget(ent) -- Сделать атакующим не игрока, а его копию, а иначе вернуть deepcopy
        
    return attack
end

local function Powers_damage_mod(inst, crit)
    local base_damage = inst.components.combat.basedamage:Get()
    local attack = FakeAttack(inst)
    local powers = inst.components.powermanager:GetAllPowersInAcquiredOrder() 
    local outputs = {
        damage_delta = base_damage,
    }

    for _, pow in pairs(powers) do 
        if pow.def.damage_mod_fn then 
            pow.def.damage_mod_fn(pow, attack, outputs)
        end 
    end 

    local val
    if crit then
        val = attack:GetCrit() and 1 or attack:GetTotalCritChance()
    else
        val = outputs.damage_delta == base_damage and 0 or (outputs.damage_delta / base_damage - 1) * 100
    end
    
    return val
end

local function Powers_defend_mod(inst)
    local base_damage = inst.components.combat.basedamage:Get()
    local attack = FakeAttack(inst)
    local powers = inst.components.powermanager:GetAllPowersInAcquiredOrder() 
    local outputs = {
        damage_delta = 0,
    }

    for _, pow in pairs(powers) do 
        if pow.def.defend_mod_fn then 
            pow.def.defend_mod_fn(pow, attack, outputs)
        end
    end 

    local damage = outputs.damage_delta
    
    return damage
end

--_bonus_crit_chance

GLOBAL.stats_AddStatsData(
    "icons_ftf/inventory_weapon_hammer", --Image
    {"activate_skill", "add_state_tag", "attack_end", "attack_start", "death", "do_damage", "dodge", "dodge_cancel", "dying", "enter_room", "exit_room", "foley_footstep", "hammer_thumped", "healthchanged", "heavy_attack", "hitboxcollided_invincible", "hitboxtriggered", "hitstreak", "hitstreak_killed", "juggernaut_force_remove", "kill", "light_attack", "parry", "power_charged_damage", "power_stacks_changed", "projectile_launched", "remove_state_tag", "revive", "shotput_landed", "start_gameplay", "take_damage", "take_heal", "timerdone",}, --Event
    "Damage mult", --tooltip text
    function(inst) return Powers_damage_mod(inst) end, -- Value
    true) -- Percent

GLOBAL.stats_AddStatsData(
    "icons_ftf/stat_crit_chance",
    {"speed_mult_changed", "crit_chance_changed", "hitboxcollided_invincible", "light_attack", "heavy_attack"},
    "Critical Chance",
    function(inst) return (math.min(1, Powers_damage_mod(inst, true))) * 100 end,
    true) 

GLOBAL.stats_AddStatsData(
    "icons_ftf/inventory_head",
    {"loadout_changed"},
    "Armor",
    function(inst) 
        local dungeon_tier_damage_mult = math.max(TUNING.GEAR.MINIMUM_DUNGEONTIER_DAMAGE_MULT, 1.15 - inst.components.combat.dungeontierdamagereductionmult:Get())
        return (1 - dungeon_tier_damage_mult) * 100 
    end,
    true)

GLOBAL.stats_AddStatsData(
    "icons_ftf/inventory_legs", 
    {"speed_mult_changed"}, 
    "Speed mult", 
    function(inst) return (inst.components.locomotor.total_speed_mult - 1) * 100 end, 
    true)  

local function GetStatsData(ispercent, val, owner)
    return ispercent and (val(owner) .. "%") or val(owner)
end

local function PlayerStatus(self)
    self.list_stats = self.root:AddChild(Widget("Gear Stats List"))
    -- the alignments below look like they make no sense
    -- but i think itll work fine, i had to adjust them like
    -- that because i moved the loot stack and that kinda messed
    -- up the alignment for this one
    -- playerstatuswidget will call these layout functions for
    -- every children of self.root whenever its layout changes
    -- each one represents a corner of the screen.
    -- (the function names are hard coded)
    function self.list_stats:TOP_LEFT()
        self
            :SetAnchors("left", "center")
            :LayoutChildrenInRow(list_spacing)
            :LayoutBounds("left", "above", self.bg)
            :Offset(200, 0)
        self.layout_fn = "TOP_LEFT"
    end
    function self.list_stats:TOP_RIGHT()
        self
            :SetAnchors("right", "center")
            :LayoutChildrenInRow(list_spacing)
            :LayoutBounds("right", "above", self.bg)
            :Offset(-200, 0)
        self.layout_fn = "TOP_RIGHT"
    end
    function self.list_stats:BOTTOM_LEFT()
        self
            :SetAnchors("left", "center")
            :LayoutChildrenInRow(list_spacing)
            :LayoutBounds("left", "below", self.bg)
            :Offset(200, 0)
        self.layout_fn = "BOTTOM_LEFT"
    end
    function self.list_stats:BOTTOM_RIGHT()
        self
            :SetAnchors("right", "center")
            :LayoutChildrenInRow(list_spacing)
            :LayoutBounds("right", "below", self.bg)
            :Offset(-200, 0)
        self.layout_fn = "BOTTOM_RIGHT"
    end
    -- this is for us to manually re-layout the stats when it rebuilds
    function self.list_stats:Layout()
        if self.layout_fn then
            local fn = self[self.layout_fn]
            fn()
        end
    end

    function self:stats_list_Rebuild()
        self.list_stats:RemoveAllChildren()
    
        for _, data in pairs(stats_data) do
            local item = self.list_stats:AddChild(Widget("Item"))
            item.icon = item:AddChild(Image("images/".. data.image ..".tex"))
                :SetToolTip(data.tooltip)
                :SetMultColor(1, 1, 1, icon_opacity)
                :SetScale(icon_scale)
            item.info = item:AddChild(Text(GLOBAL.FONTFACE.CODE, 65, GetStatsData(data.ispercent, data.val, self.owner), GLOBAL.UICOLORS.SUBTITLE))
                :EnableShadow()
                :SetShadowColor(GLOBAL.UICOLORS.BLACK)
                :SetShadowOffset(1, -1)
                :EnableOutline()
                :SetOutlineColor(GLOBAL.UICOLORS.BLACK)
                :SetBlocksMouse(false)
                :SetMultColor(1, 1, 1, text_opacity)
                :SetScale(text_scale)
                :LayoutBounds("center", "center", item.icon)

            self.list_stats:Layout()

            local function Listen()
                self.owner:DoTaskInTime(.1, function()
                    item.info:SetText(GetStatsData(data.ispercent, data.val, self.owner))
                end)
            end
            for _, event in pairs(data.events) do
                self.owner:RemoveEventCallback(event, Listen)
                self.owner:ListenForEvent(event, Listen)
            end
        end
    end

    -- change the loot stack position (loot picked up popups)
    local original_Layout = self._Layout
    function self:_Layout(anchors, to_middle)
        original_Layout(self, anchors, to_middle)

        local to_edge = -to_middle
        self.loot_stack
		    :LayoutBounds(anchors.left, anchors.below, self.konjur)
            :Offset(54 * to_edge.x, -80 * to_edge.y)

        self.list_stats:Layout()
    end

    self:stats_list_Rebuild()
    self.owner:ListenForEvent("new_statdata", function() self:stats_list_Rebuild() end, GLOBAL.TheGlobalInstance)
end
AddClassPostConstruct("widgets/ftf/playerstatuswidget", PlayerStatus)

local function TownHud(self)
    function self:stats_list_Rebuild()
        for player,infowidget in pairs(self.player_infos) do
            local list_stats = infowidget.list_stats
            if not list_stats then
                -- the info widget should not have a nil list_stats because
                -- they are added before rebuild is called, but if this ever
                -- happens...
                return
            end

            -- TODO gibberish: make list_stats a widget class of its own so we
            -- can quickly add it to anywhere we want, and dont have to write
            -- repetitive code like below
            list_stats:RemoveAllChildren()
            for _, data in pairs(stats_data) do
                local item = list_stats:AddChild(Widget("Item"))
                item.icon = item:AddChild(Image("images/".. data.image ..".tex"))
                    :SetToolTip(data.tooltip)
                    :SetMultColor(1, 1, 1, icon_opacity)
                    :SetScale(icon_scale)
                item.info = item:AddChild(Text(GLOBAL.FONTFACE.CODE, 65, GetStatsData(data.ispercent, data.val, player), GLOBAL.UICOLORS.SUBTITLE))
                    :EnableShadow()
                    :SetShadowColor(GLOBAL.UICOLORS.BLACK)
                    :SetShadowOffset(1, -1)
                    :EnableOutline()
                    :SetOutlineColor(GLOBAL.UICOLORS.BLACK)
                    :SetBlocksMouse(false)
                    :SetMultColor(1, 1, 1, text_opacity)
                    :SetScale(text_scale)
                    :LayoutBounds("center", "center", item.icon)
    
                list_stats
                    :SetAnchors("left", "center")
                    :LayoutChildrenInRow(list_spacing)
                    :LayoutBounds("left", "below", infowidget.bg)
                    :Offset(60, -20)
    
                local function Listen()
                    player:DoTaskInTime(.1, function()
                        item.info:SetText(GetStatsData(data.ispercent, data.val, player))
                    end)
                end
                for _, event in pairs(data.events) do
                    player:RemoveEventCallback(event, Listen)
                    player:ListenForEvent(event, Listen)
                end
            end
        end
    end

    local original_AttachPlayerToHud = self.AttachPlayerToHud
    function self:AttachPlayerToHud(player)
        original_AttachPlayerToHud(self, player)
        local infowidget = self.player_infos[player]
        infowidget.list_stats = infowidget:AddChild(Widget("Gear Stats List"))

        function infowidget:LayoutWeaponTips()
            self.weapontips:LayoutBounds("left", "below", self.bg)
		        :Offset(50, -160)
	        return self
        end

        self:stats_list_Rebuild()
        player:ListenForEvent("new_statdata", function() self:stats_list_Rebuild() end, GLOBAL.TheGlobalInstance) 
    end
end
AddClassPostConstruct("widgets/ftf/townhudwidget", TownHud)

--GLOBAL.EnableDebugFacilities()
