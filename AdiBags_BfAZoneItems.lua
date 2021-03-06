--[[
AdiBags_PriorExpansions - Seperates items from current expansion from those from prior ones, an addition to Adirelle's fantastic bag addon AdiBags.
Copyright 2019 Ggreg Taylor
All rights reserved.
--]]

local addon = LibStub('AceAddon-3.0'):GetAddon('AdiBags')
local L = setmetatable({}, {__index = addon.L})

local kCategory = 'Zone Item'
local kPfx = '|cff00ffff' 
local kSfx = '|r'
local Ggbug = false

local addonName2, addon2 = ...
local ZONE_ITEMS = addon2.ZONE_ITEMS 

local setFilter = addon:RegisterFilter("ZoneItems", 47, 'ABEvent-1.0')
setFilter.uiName = L['Zone Specific Items']
setFilter.uiDesc = L['Group zone specific items together.']

function setFilter:OnInitialize(b)
  self.db = addon.db:RegisterNamespace('ZoneItems', {
    profile = { enable = true },
    char = {  },
  })
end

function setFilter:Update()
  self:SendMessage('AdiBags_FiltersChanged')
end
function setFilter:OnEnable()
  addon:UpdateFilters()
end
function setFilter:OnDisable()
  addon:UpdateFilters()
end

local setNames = {}

function setFilter:GetOptions()
  return {
    enableZoneItem = {
      name = L['Enable Zone Item groups'],
      desc = L['Check this if you want to automatically seperate Nazjatar and Mechagon items.'],
      type = 'toggle',
      order = 25,
    },
    groupSetZoneItemSubgroups = {
      name = L['Further Zone Item Sub-Grouping Options'],
      type = L['group'],
      inline = true,
      order = 26,
      args = {
        _desc = {
          name = L['Select optional additional sub-groupings.'],
          type = 'description',
          order = 10,
        }, 
        groupBenthic = {
          name = L['Benthic BoA Items'],
          desc = L['Group Benthic Bind on Account gear tokens seperately.'],
          type = 'toggle',
          order = 27,
        },
        groupBlack = {
          name = L['Black Empire BoA Items'],
          desc = L['Group Black Empire Bind on Account gear tokens seperately.'],
          type = 'toggle',
          order = 28,
        },
        groupRepItems = {
          name = L['Reputation Items'],
          desc = L['Group Reputation on-use and repeatable turn-in items seperately.'],
          type = 'toggle',
          order = 29,
        },
        groupEssences = {
          name = L['Heart Essences'],
          desc = L['Group Heart of Azeroth essences seperately.'],
          type = 'toggle',
          order = 30,
        },
        groupPatch8_3 = {
          name = L['Patch 8.3 Items'],
          desc = L['Group items added in Patch 8.3 for Uldum, Horrific Visions, and Vale of Eternal Blossoms. They really should leave that poor Vale alone.'],
          type = 'toggle',
          order = 31,
        },
        groupVisions = {
          name = L['Visions'],
          desc = L['Group items for Visions.'],
          type = 'toggle',
          order = 32,
        },
        zonePriority = {
          name = L['Current Zone First'],
          desc = L['Group current zone\'s items first in bags.'],
          type = 'toggle',
          order = 33,
        },
      }
    },
  }, addon:GetOptionHandler(self, false, function() return self:Update() end)
end

-----------------------
function setFilter:Filter(slotData)
  local currZoneName = GetRealZoneText()
  if self.db.profile.groupEssences then
    addon:SetCategoryOrder('Essence',29)
  end
  if self.db.profile.groupRepItems then
    addon:SetCategoryOrder('Current Rep Item',30)
  end
  if self.db.profile.groupPatch8_3 then
    addon:SetCategoryOrder('Patch 8.3',31)
  end
  if self.db.profile.groupVisions then
    addon:SetCategoryOrder('Visions',32)
  end
  if self.db.profile.zonePriority then
    addon:SetCategoryOrder('Current Zone Item',33)
  end
    -- Exit if profile not enabled
  if (self.db.profile.enableZoneItem == false) or (slotData.itemId == false) then 
    return
  end
  local ziID, ziZone, ziSubcat, ziName, currSubCategory, bagItemID
  bagItemID = tonumber(slotData.itemId)
  -- Check if Heart of Azeroth Essence, and grouping for them selected
  local item = Item:CreateFromBagAndSlot(slotData.bag, slotData.slot)
  local _,_, itemRarity, _,_, itemType, itemSubType, _,_,_,_,_,_,_,_ = GetItemInfo(slotData.itemId)
  if (self.db.profile.groupEssences) and (itemType == 'Consumable' and itemSubType == 'Other' and itemRarity == 6) then
    return kPfx .. 'Heart Essence'.. kSfx, 'Essence'
  else
  -- load array category/subcat values
    for x = 1, #ZONE_ITEMS do
      local currSubset = {}
      local currZoneItem = ZONE_ITEMS[x]
      local index = 1
      for w in currZoneItem:gmatch('([^^]+)') do 
        currSubset[index]  = w 
        index = index +1
      end
      --169478^BfA^Benthic^Benthic Bracers (Exampleb)
      --167027^Patch8_3^^Portable Clarity Beam
      ziID = tonumber(currSubset[1])
      ziZone = currSubset[2]
      ziSubcat = currSubset[3]
      ziName = currSubset[4]
      if bagItemID == ziID then
        --check Benthic
        if ziZone == 'BfA' then
          if ziSubcat == 'Benthic' and  (self.db.profile.groupBenthic) then
            currSubCategory = 'Benthic'
            return kPfx .. currSubCategory.. kSfx, kCategory
          elseif ziSubcat == 'Essence' and (self.db.profile.groupEssences) then
            currSubCategory = 'Heart Essence'
            return kPfx .. currSubCategory .. kSfx, 'Essence'
          end
        elseif ziZone == 'Patch8_3' and (self.db.profile.groupPatch8_3) then
          if ziSubcat == 'Reputation' then
            currSubCategory = 'Reputation'
            return kPfx .. currSubCategory.. kSfx, 'Current Rep Item'
          elseif ziSubcat == 'Visions' and (self.db.profile.groupVisions) then
            currSubCategory = 'Visions'
            return kPfx .. currSubCategory.. kSfx, 'Visions'
          elseif ziSubcat == 'Black' and (self.db.profile.groupBlack) then
            currSubCategory = 'Black Empire'
            return kPfx .. currSubCategory .. kSfx, 'Black Empire'
          else
            currSubCategory = 'Patch 8.3 Item'
            return kPfx .. currSubCategory.. kSfx, 'Patch 8.3 Item'
          end
        elseif ziZone == 'Nazjatar'  or ziZone == 'Mechagon' then
          if (self.db.profile.groupRepItems) and ziSubcat=='Reputation' then
            currSubCategory = 'Reputation'
            return kPfx .. currSubCategory.. kSfx, 'Current Rep Item'
          end
          currSubCategory = ziZone
          if self.db.profile.zonePriority and ziZone == currZoneName then
            return kPfx .. currSubCategory.. kSfx, 'Current Zone Item'
          else
            return kPfx .. currSubCategory.. kSfx, kCategory
          end
        end
      end
    end
  end
end

