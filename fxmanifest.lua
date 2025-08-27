nui_emulate_game_ui 'yes'
fx_version 'cerulean'
game 'gta5'
author 'AP'
description 'QB-SPAWN REDESIGN'
version '1.0.0'
lua54 'yes'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua',
    'config.lua',
    '@qb-apartments/config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

client_script 'client.lua'
dependencies 'ap_multicharacter'
ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/script.js'
}