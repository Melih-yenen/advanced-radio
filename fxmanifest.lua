fx_version 'cerulean'
game 'gta5'

author 'Antigravity'
description 'Advanced 3D Radio Script with pma-voice integration'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/*.png', -- In case we add images later
    'html/fonts/*.ttf' -- For custom fonts
}

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'pma-voice',
    'qb-core'
}
