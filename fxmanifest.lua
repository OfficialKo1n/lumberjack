fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

author 'Snaily'
description 'Lumberjack Activity made for fun'
discord 'imsnaily'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

server_scripts {
    'src/server/index.lua',
}

client_scripts {
    'src/client/functions.lua',

    'src/client/index.lua',
    'src/client/conveyor.lua'
}

dependencies {
    '/onesync',

    'ox_lib',
    'ox_target'
}

--- Would be awesome if you don't rename the resource so I can have the count of servers using it. Thanks!