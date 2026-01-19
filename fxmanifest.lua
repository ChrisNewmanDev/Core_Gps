fx_version 'cerulean'
game 'gta5'

description 'core_gps - Location Marker Management System'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/cl_gps.lua'
}

server_scripts {
    'server/sv_gps.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

lua54 'yes'
