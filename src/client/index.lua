local target <const> = exports.ox_target

local config <const> = CONFIG_LUMBERJACK
local internalData <const> = {}

function GetAttachedEntity()
    return internalData.attached
end

function DeleteAttachedEntity()
    internalData.attached = nil
end

function RemoveEntityFromTable(entity)
    if not internalData.woodenLogs then
        return false
    end

    for key, prop in next, internalData.woodenLogs do
        if prop == entity then
            table.remove(internalData.woodenLogs, key)
            break
        end
    end

    return true
end

local getTreesLogs <const> = function(model)
    local logs = 1

    for _, tree in next, config.models do
        if joaat(tree.prop) == model then
            ---@diagnostic disable-next-line: cast-local-type
            logs = type(tree.logs) == 'table' and math.random(tree.logs[1], tree.logs[2]) or tree.logs
        end
    end

    return logs
end

local getRandomAnimation <const> = function()
    local animations <const> = { 'plyr_front_takedown_bat_l_facehit', 'plyr_front_takedown_bat_r_facehit' }
    return animations[math.random(1, #animations)]
end

local spawnTreesLogs <const> = function(model)
    if not IsModelInCdimage('prop_log_01') then
        return error(('invalid model "prop_log_01". You need "snaily_trees" assets'), 3)
    end

    local logs <const> = getTreesLogs(model)
    local coords <const> = GetEntityCoords(cache.ped)
    lib.requestModel('prop_log_01')

    if not internalData.woodenLogs then
        internalData.woodenLogs = {}
    end

    for i = 1, logs do
        local prop <const> = CreateObject('prop_log_01', coords.x + math.random(-1, 1), coords.y + math.random(-1, 1), coords.z + math.random(2, 3), true, true, true)
        internalData.woodenLogs[#internalData.woodenLogs+1] = prop

        while not DoesEntityExist(prop) do
            Wait(0)
        end

        ActivatePhysics(prop)
        SetEntityDynamic(prop, true)
        SetEntityAsMissionEntity(prop, true, true)

        while GetEntityHeightAboveGround(prop) > 0.2 do
            Wait(0)
        end

        FreezeEntityPosition(prop, true)
        target:addLocalEntity(prop, {
            {
                icon = 'fa-solid fa-tree', name = 'pickup_woodenlog', event = 'lumberjack:Pickup:Log', label = 'Pickup Wooden Log',
                canInteract = function(entity)
                    return not IsEntityAttached(entity)
                    and not IsPedFatallyInjured(cache.ped)
                    and not IsPedCuffed(cache.ped)
                    and not DoesEntityExist(internalData.attached)
                end
            },
        })
    end
end

AddEventHandler('lumberjack:Pickup:Log', function(params)
    local entity <const> = DoesEntityExist(params.entity) and params.entity or nil
    if not entity then return end

    local coords <const> = GetEntityCoords(entity)
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
    Wait(100)

    TaskGoStraightToCoord(cache.ped, coords.x, coords.y, coords.z, 1.0, -1, 0.0, 1.0)
    while #(coords - GetEntityCoords(cache.ped)) > 1.5 do Wait(100) end

    TaskTurnPedToFaceEntity(cache.ped, entity, 2.0)
    Wait(500)

    internalData.attached = entity
    lib.requestAnimDict('anim@heists@load_box')
    TaskPlayAnim(cache.ped, 'anim@heists@load_box', 'lift_box', 8.0, 8.0, 2500, 15, 0, false, false, false)
    Wait(2500)

    ClearPedTasks(cache.ped)
    AttachEntityToEntity(entity, cache.ped, GetPedBoneIndex(cache.ped, 28422), -0.08, -0.10, 0, 1.0, 0.0, 90.00, true, true, false, true, 0, true)

    lib.requestAnimDict('anim@heists@box_carry@')
    TaskPlayAnim(cache.ped, 'anim@heists@box_carry@', 'idle', 8.0, 8.0, -1, 50, 0, false, false, false)

    while DoesEntityExist(internalData.attached) do
        DisableControlAction(1, 24, true)
        DisableControlAction(1, 25, true)
        DisableControlAction(1, 45, true)

        if GetSelectedPedWeapon(cache.ped) ~= `WEAPON_UNARMED` then
            SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
        end

        if not IsEntityPlayingAnim(cache.ped, 'anim@heists@box_carry@', 'walk', 3) then
            TaskPlayAnim(cache.ped, 'anim@heists@box_carry@', 'walk', 8.0, 8.0, -1, 50, 0, false, false, false)
        end

        Wait(0)
    end
end)

AddEventHandler('lumberjack:Cutdown:Tree', function(params)
    if internalData.busy then return end

    if GetSelectedPedWeapon(cache.ped) ~= `WEAPON_HATCHET` then
        return SendNotification('You need a hatchet to do this', 'error')
    end

    local entity <const> = DoesEntityExist(params.entity) and params.entity or nil
    if not entity then return end

    local networkId <const> = NetworkGetNetworkIdFromEntity(entity)
    local canDestroy <const> = lib.callback.await('lumberjack:Can:Destroy', false, networkId)

    if not canDestroy then
        return SendNotification('This tree is busy!', 'error')
    end

    local coords <const> = GetEntityCoords(entity)
    internalData.busy = true

    TaskGoStraightToCoord(cache.ped, coords.x, coords.y, coords.z, 1.0, -1, 0.0, 1.0)
    while #(coords - GetEntityCoords(cache.ped)) > 1.75 do Wait(100) end

    TaskTurnPedToFaceEntity(cache.ped, entity, 2.0)
    Wait(500)

    ClearPedTasks(cache.ped)
    FreezeEntityPosition(cache.ped, true)

    lib.requestNamedPtfxAsset('core')
    lib.requestAnimDict('melee@large_wpn@streamed_variations')

    local oCoords <const> = GetEntityCoords(cache.ped)
    GiveWeaponToPed(cache.ped, `WEAPON_HATCHET`, 0, false, true)
    SetCurrentPedWeapon(cache.ped, `WEAPON_HATCHET`, true)
    local count = math.random(5, 8)

    repeat
        TaskPlayAnim(cache.ped, 'melee@large_wpn@streamed_variations', getRandomAnimation(), 8.0, 8.0, -1, 80, 0, false, false, false)
        Wait(750)

        UseParticleFxAsset('core')
        local effect = StartParticleFxLoopedAtCoord('ent_dst_wood_splinter', coords.x, coords.y, coords.z + 1.0, 0.0, 0.0, 0.0, 1.6, false, false, false, false)
        Wait(1000)
        StopParticleFxLooped(effect, false)
        Wait(500)
        SetEntityCoords(cache.ped, oCoords.x, oCoords.y, oCoords.z - 1.0, true, false, false, false)
        count -= 1
    until count == 0

    FreezeEntityPosition(cache.ped, false)
    ClearPedTasks(cache.ped)

    internalData.busy = false
    local model <const> = GetEntityModel(entity)

    if NetworkDoesEntityExistWithNetworkId(networkId) then
        target:removeEntity(networkId, 'cutdown_tree')

        local destroyed <const> = lib.callback.await('lumberjack:Destroy:Tree', false, networkId)
        if not destroyed then return end

        spawnTreesLogs(model)
    end
end)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler('addTarget', nil, function(bagName)
    local entity <const> = GetEntityFromStateBagName(bagName)
    if entity == 0 then return end

    while not HasCollisionLoadedAroundEntity(entity) do
        if not DoesEntityExist(entity) then
            break
        end

        Wait(250)
    end

    PlaceObjectOnGroundProperly(entity)
    SetEntityInvincible(entity, true)

    local netId <const> = NetworkGetNetworkIdFromEntity(entity)
    target:removeEntity(netId, 'cutdown_tree')
    target:addEntity(NetworkGetNetworkIdFromEntity(entity), {
        {
            icon = 'fa-solid fa-tree',
            name = 'cutdown_tree',
            event = 'lumberjack:Cutdown:Tree',
            label = 'Cut Down',
            canInteract = function()
                return not IsPedFatallyInjured(cache.ped)
                and not IsPedCuffed(cache.ped)
            end
        }
    })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then
        return
    end

    if internalData.woodenLogs then
        for _, entity in next, internalData.woodenLogs do
            if DoesEntityExist(entity) then
                DeleteEntity(entity)
            end
        end
    end
end)