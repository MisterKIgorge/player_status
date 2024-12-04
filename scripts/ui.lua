local StatusDefs = require ("statusdata")
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"

local PlayerStatItemWidget = require "player_status.widgets.playerstatitemwidget"

local list_spacing = 40
local icon_scale = 0.85
local text_scale = 1
local icon_opacity = 1
local text_opacity = 1

local function MakeText(stats, data)
    return stats .. (data.ispercent and "%" or "")
end

local function PlayerStatus(self)
    self.player_stats_widgets = self.root:AddChild(Widget("Player Status Widgets Container"))

    function self:player_stats_widgets_Rebuild()
        self.player_stats_widgets:RemoveAllChildren()
        for _, data in pairs(StatusDefs.GetStatusData()) do
            local textfn = data.textfn or MakeText

            local item = self.player_stats_widgets:AddChild(PlayerStatItemWidget(data.image, data.tooltip))
                :SetIconScale(icon_scale)
                :SetTextScale(text_scale)
                :SetIconOpacity(icon_opacity)
                :SetTextOpacity(text_opacity)

            local function UpdateText()
                local playerstatdisplay = self.owner and self.owner.components.playerstatdisplay
                if playerstatdisplay and playerstatdisplay.stats and playerstatdisplay.stats[data.id] then
                    item:SetText(textfn(playerstatdisplay.stats[data.id], data))
                end
            end

            for _, event in pairs(data.events) do
                self.owner:RemoveEventCallback(event, UpdateText)
                self.owner:ListenForEvent(event, UpdateText)
                UpdateText()
            end
        end
    end

    -- change the loot stack position (loot picked up popups)
    local original_Layout = self._Layout
    function self:_Layout(...)
        original_Layout(self, ...)

        if self.layout_mode == self.LAYOUT_MODES.s.TOP_LEFT then
            self.player_stats_widgets:SetAnchors("left", "center")
                :LayoutChildrenInRow(list_spacing)
                :LayoutBounds("left", "bottom", self.bg_container)
                :Offset(200, 0)
        elseif self.layout_mode == self.LAYOUT_MODES.s.TOP_RIGHT then
            self.player_stats_widgets:SetAnchors("right", "center")
                :LayoutChildrenInRow(list_spacing)
                :LayoutBounds("right", "bottom", self.bg_container)
                :Offset(-200, 0)
        elseif self.layout_mode == self.LAYOUT_MODES.s.BOTTOM_LEFT then
            self.player_stats_widgets:SetAnchors("left", "center")
                :LayoutChildrenInRow(list_spacing)
                :LayoutBounds("left", "top", self.bg_container)
                :Offset(200, 0)
        elseif self.layout_mode == self.LAYOUT_MODES.s.BOTTOM_RIGHT then
            self.player_stats_widgets:SetAnchors("right", "center")
                :LayoutChildrenInRow(list_spacing)
                :LayoutBounds("right", "top", self.bg_container)
                :Offset(-200, 0)
        end
    end

    self:player_stats_widgets_Rebuild()
    self.owner:ListenForEvent("new_statdata", function() self:stats_list_Rebuild() end, GLOBAL.TheGlobalInstance)
end
AddClassPostConstruct("widgets/ftf/playerstatuswidget", PlayerStatus)