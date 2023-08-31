local entities <const> = {}
local steps <const> = {
    { coords = vector3(-476.22, 5304.64, 85.33), rot = vector3(-15.0, 0.0, 70.0) },
    { coords = vector3(-487.19, 5308.81, 82.85), rot = vector3(-15.0, 0.0, 70.0) },
    { coords = vector3(-509.52, 5317.08, 82.83), rot = vector3(0.0, 0.0, 70.0) },
    { coords = vector3(-539.19, 5327.91, 76.74), rot = vector3(-10.0, 0.0, 70.0) },
    { coords = vector3(-548.62, 5331.25, 76.64), rot = vector3(0.0, 0.0, 70.0) },
    { coords = vector3(-548.62, 5331.25, 73.64), rot = vector3(0.0, 0.0, 70.0) }
}

local interpolateEntity <const> = function(entity, coords, dest)
    if not dest then
        return FreezeEntityPosition(entity, false)
    end

    local speed <const> = 8.0 --- speed of the conveyor belt
    local elapsed = 0.0

    while elapsed < speed do
        local percentage <const> = elapsed / speed
        local line <const> = vec3(Lerp(coords.x, dest.x, percentage), Lerp(coords.y, dest.y, percentage), Lerp(coords.z, dest.z, percentage))

        if line then
            SetEntityCoords(entity, line.x, line.y, line.z, false, false, false, false)
            elapsed += 0.01
        end

        Wait(0)
    end
end

RegisterNetEvent('conveyor:Start:Transport', function()
    local model = 'prop_log_01'
    lib.requestModel(model)

    local entity <const> = CreateObject(model, steps[1].coords.x, steps[1].coords.y, steps[1].coords.z, false, true, true)
    local entityId <const> = #entities+1
    while not DoesEntityExist(entity) do Wait(0) end

    entities[entityId] = entity
    SetEntityCollision(entity, true, true)
    ---@diagnostic disable-next-line: missing-parameter, param-type-mismatch
    SetEntityRotation(entity, steps[1].rot)
    PlaceObjectOnGroundProperly(entity)

    for i = 1, #steps do
        local step <const> = steps[i]
        local next <const> = steps[i+1]

        interpolateEntity(entity, step.coords, next?.coords)
    end

    entities[entityId] = nil
    DeleteEntity(entity)
end)

local deliverWoodenLog <const> = function()
    local entity <const> = GetAttachedEntity()

    if not DoesEntityExist(entity) then
        return SendNotification('You need a wooden log to use this!', 'error')
    end

    if RemoveEntityFromTable(entity) then
        DeleteEntity(entity)

        lib.callback('lumberjack:Deliver:Log', false, function()
            ClearPedTasksImmediately(cache.ped)
        end)
    else
        error(('something didnt work properly in "RemoveEntityFromTable" function'), 3)
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then
        return
    end

    for _, entity in next, entities do
        if entity and DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
end)

CreateThread(function()
    local coords <const> = vec3(-472.28, 5303.34, 85.99)
    local conveyor <const> = lib.points.new(coords, 10.0)
    local prompted = false

    function conveyor:onExit()
        if prompted then
            prompted = false
            lib.hideTextUI()
        end
    end

    function conveyor:nearby()
        if not prompted and self.currentDistance < 2.5 then
            prompted = true
            lib.showTextUI('[E] - Place wooden logs')
        elseif prompted and self.currentDistance > 2.5 then
            prompted = false
            lib.hideTextUI()
        end

        if prompted and IsControlJustPressed(0, 38) then
            deliverWoodenLog()
        end
    end
end)