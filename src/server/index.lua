local inventory <const> = exports.ox_inventory

local config <const> = CONFIG_LUMBERJACK
local entities <const> = {}

local selectRandomModel <const> = function()
    local probability = 0

    for i = 1, #config.models do
        probability += config.models[i].chance
    end

    local random <const> = math.random(probability)
    local total = 0

    for i = 1, #config.models do
        total += config.models[i].chance

        if random <= total then
            return config.models[i].prop
        end
    end

    return config.models[1].prop
end

local createTreeEntity <const> = function(model, coords)
    local entity <const> = CreateObjectNoOffset(joaat(model), coords.x, coords.y, coords.z + 1.0, true, false, false)
    table.insert(entities, NetworkGetNetworkIdFromEntity(entity))

    if DoesEntityExist(entity) then
        FreezeEntityPosition(entity, true)
        SetEntityDistanceCullingRadius(entity, 75.0)
    end

    return entity
end

lib.callback.register('lumberjack:Destroy:Tree', function(_, networkId)
    local entity = NetworkGetEntityFromNetworkId(networkId)
    local coords <const> = GetEntityCoords(entity)
    DeleteEntity(entity)

    SetTimeout(config.respawn * 1000, function()
        local model <const> = selectRandomModel()
        entity = createTreeEntity(model, coords)

        Entity(entity).state:set('addTarget', true, true)
    end)

    return true
end)

lib.callback.register('lumberjack:Deliver:Log', function(source)
    local amount = type(config.reward) == 'table' and math.random(config.reward[1], config.reward[2]) or config.reward
    inventory:AddItem(source, 'money', amount)

    SetTimeout(math.random(100, 300), function()
        TriggerClientEvent('conveyor:Start:Transport', -1)
    end)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then
        return
    end

    for _, netId in next, entities do
        local entity <const> = NetworkGetEntityFromNetworkId(netId)

        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
end)

SetTimeout(2 * 1000, function()
    local treeConfig <const> = config

    if table.type(treeConfig.models) == 'empty' then
        return warn(('no models found in "config.models" config. Please set at least 1 model'))
    end

    if table.type(treeConfig.coords) == 'empty' then
        return warn(('no coords found in "config" config. Please set at least 1 coord'))
    end

    for _, coord in next, treeConfig.coords do
        local model = selectRandomModel()
        local entity = createTreeEntity(model, coord)
        Entity(entity).state:set('addTarget', true, true)
    end
end)