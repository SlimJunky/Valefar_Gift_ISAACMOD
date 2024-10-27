local Valefar = RegisterMod("Valefar's Gift", 1) 
-- initialize global variables --
local VALEFAR_ID = Isaac.GetItemIdByName("Valefar's Gift")
local curTimePickup

--EID DESCRIPTOR--
if EID then
    EID:addCollectible(VALEFAR_ID,table.concat(
        {
            "{{DevilRoom}} All devil deals become free including the ones presented in RED {{TreasureRoom}} rooms or {{BossRoom}} rooms.",
            "{{Collectible}} The player gains {{Trinket}}{{4}} smelted trinkets, Devil's Crown, Number Magnet, Daemon's Tail & Black Feather.",
            "{{Warning}}{{Timer}} The player will gain {{BrokenHeart}}{{2}} Every 6 minutes unless the item is dropped or removed.",
        },
        "#"
    )
    )
end
--"{{ArrowUp}}{{Speed}} Every 6 minutes.",
function Valefar:ValefarStart()
    curTimePickup = 0 --doesnt bug out later
end

Valefar:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, Valefar.ValefarStart)


-- What the valefar gift does whilst held --
function Valefar:ValefarPassive()
    local player = Isaac.GetPlayer()
    local copyCount = player:GetCollectibleNum(VALEFAR_ID)
    if copyCount >= 1 then --if player has valefar gift then consider these for balancing
        --if player:HasCollectible(CollectibleType.COLLECTIBLE_GOAT_HEAD, true) then
            --return
        --else
            --player:AddCollectible(CollectibleType.COLLECTIBLE_GOAT_HEAD,0,true,ActiveSlot.SLOT_PRIMARY,0)
        --end
        if player:HasTrinket(TrinketType.TRINKET_DEVILS_CROWN, false) then
            return
        else
            player:AddTrinket(TrinketType.TRINKET_DEVILS_CROWN, true)
            player:UseActiveItem(CollectibleType.COLLECTIBLE_SMELTER, false, true, true, false, ActiveSlot.SLOT_PRIMARY)
        end
        if player:HasTrinket(TrinketType.TRINKET_NUMBER_MAGNET, false) then
            return
        else
            player:AddTrinket(TrinketType.TRINKET_NUMBER_MAGNET, true)
            player:UseActiveItem(CollectibleType.COLLECTIBLE_SMELTER, false, true, true, false, ActiveSlot.SLOT_PRIMARY)
        end
        if player:HasTrinket(TrinketType.TRINKET_DAEMONS_TAIL, false) then
            return
        else
            player:AddTrinket(TrinketType.TRINKET_DAEMONS_TAIL, true)
            player:UseActiveItem(CollectibleType.COLLECTIBLE_SMELTER, false, true, true, false, ActiveSlot.SLOT_PRIMARY)
     
        end
        if player:HasTrinket(TrinketType.TRINKET_BLACK_FEATHER) then
            return
        else
            player:AddTrinket(TrinketType.TRINKET_BLACK_FEATHER, true)
            player:UseActiveItem(CollectibleType.COLLECTIBLE_SMELTER, false, true, true, false, ActiveSlot.SLOT_PRIMARY)
     
        end
    end
    if copyCount == 0 then
        player:RemoveStatusEffects() --remove the effects
        player:TryRemoveTrinket(TrinketType.TRINKET_DEVILS_CROWN) --remove smelted trinkets
        player:TryRemoveTrinket(TrinketType.TRINKET_NUMBER_MAGNET)
        player:TryRemoveTrinket(TrinketType.TRINKET_DAEMONS_TAIL)
        player:TryRemoveTrinket(TrinketType.TRINKET_BLACK_FEATHER)
    end
end
--player:UseActiveItem(CollectibleType.COLLECTIBLE_SMELTER, false, false , false , false , nil)
--player:UseActiveItem(CollectibleType.COLLECTIBLE_SMELTER)

Valefar:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, Valefar.ValefarPassive)

function Valefar:ValefarPickupTimeCount(pickupEnt, collision, low)
    local game = Game()
    if pickupEnt.SubType == VALEFAR_ID and collision.Type == EntityType.ENTITY_PLAYER and low == false and collision:ToPlayer() ~= nil then
         local player = collision:ToPlayer()
         local copyCount = player:GetCollectibleNum(VALEFAR_ID) + 1 -- it is to prevent pickup problems (it will think 0 copies)
        if copyCount >= 1 then
            curTimePickup = game:GetFrameCount()
            SFXManager():Play(SoundEffect.SOUND_SATAN_GROW, 2, 2, false, 1, 0) --play sound effect
            player:AddBrokenHearts(2)
        end
        if copyCount == 0 then
            player:RemoveStatusEffects()
       end
    end
end
  

Valefar:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, Valefar.ValefarPickupTimeCount, PickupVariant.PICKUP_COLLECTIBLE)

function Valefar:ValefarTimeCount()
    local game = Game()
    local player = Isaac.GetPlayer(0)
    local copyCount = player:GetCollectibleNum(VALEFAR_ID)
    local sixMins = 10800 -- six minutes in frames
    --local tenSeconds = 300 --for testing purposes
    --local thirtySeconds = 900
    local curTime = game:GetFrameCount()

    
    if copyCount >= 1 then
        if curTime == curTimePickup + sixMins then
            player:AddBrokenHearts(2)
            SFXManager():Play(SoundEffect.SOUND_DEVILROOM_DEAL, 6, 2, false, 1, 0)
            curTimePickup = curTimePickup + sixMins
            player:AddCacheFlags(CacheFlag.CACHE_SPEED)
            player:EvaluateItems() --MC_EVALUATE_CACHE SHOULD FIRE
        end
        if curTime == curTimePickup + (sixMins - 150) then
            SFXManager():Play(SoundEffect.SOUND_SATAN_GROW, 2, 2 , false, 1, 0)
        end
    end
    if copyCount == 0 then
        player:RemoveStatusEffects()
    end
end


Valefar:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, Valefar.ValefarTimeCount)

--ADD SPEED PER 6 MINS WHEN BROKEN HEART GETS ADDED--
function Valefar:ValefarCacheFlags(player, cacheFlags)
    local copyCount = player:GetCollectibleNum(VALEFAR_ID)
    local speedToAdd = 1
    --game:GetFrameCount()
    if copyCount >= 1 and cacheFlags and CacheFlag.CACHE_SPEED == CacheFlag.CACHE_SPEED then
        player.Speed = player.Speed + speedToAdd
    end

end

Valefar:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, Valefar.ValefarCacheFlags)

----------------------------------------------------------

function Valefar:ValefarDevilDealsCost()
    local game = Game()
    local room = game:GetRoom()
    local roomType = room:GetType()
    local player = Isaac.GetPlayer(0)
    local copyCount = player:GetCollectibleNum(VALEFAR_ID)

    if roomType == RoomType.ROOM_DEVIL and copyCount >= 1 then --checks if room is devil
        local entities = Isaac.FindByType(5,100) --5.100 is item pedestals
        for _, entity in ipairs(entities) do --check room entities
                local entityPickup = entity:ToPickup() -- cast entity as pickupable
                entityPickup.AutoUpdatePrice = false --cant change price
                entityPickup.Price = 0 --sets item pedestal price to 0
        end
    end   
    if roomType == RoomType.ROOM_TREASURE and copyCount >= 1 then --check if room is devil specifically for "red treasure rooms"
        local entities = Isaac.FindByType(5,100) --5.100 is item pedestals
        for _, entity in ipairs(entities) do
            local entityPickup = entity:ToPickup()
            entityPickup.AutoUpdatePrice = false
            entityPickup.Price = 0
        end
    end
    if roomType == RoomType.ROOM_BOSS and copyCount >= 1 then --check if room is devil specifically for "boss rooms with devil deals"
        local entities = Isaac.FindByType(5,100) --5.100 is item pedestals
        for _, entity in ipairs(entities) do
            local entityPickup = entity:ToPickup()
            entityPickup.AutoUpdatePrice = false
            entityPickup.Price = 0
        end
    end
end


Valefar:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, Valefar.ValefarDevilDealsCost)