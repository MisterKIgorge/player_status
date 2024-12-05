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

local function MakeText(value, data)
    if value then
        return value / (data.accuracy and 10 ^ data.accuracy or 100) .. (data.ispercent and "%" or "")
    end

    return ""
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
                local stats = self.owner.components.playerstatdisplay and self.owner.components.playerstatdisplay:GetStats(data.id) or nil
                local text = textfn(stats, data)
                item:SetText(text)
            end

            self.owner:RemoveEventCallback("statusupdated_" .. data.id, UpdateText)
            self.owner:ListenForEvent("statusupdated_" .. data.id, UpdateText)
            UpdateText()
        end
        self:_Layout()
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
    self.owner:ListenForEvent("new_statdata", function() self:player_stats_widgets_Rebuild() end, GLOBAL.TheGlobalInstance)
end
AddClassPostConstruct("widgets/ftf/playerstatuswidget", PlayerStatus)