function Lerp(start, finish, percentage)
    return start + (finish - start) * percentage
end

function SendNotification(message, type)
    return lib.notify({
        description = message,
        type = type or 'success'
    })
end