fx_version 'cerulean'
game 'gta5'

description 'Smart Taser Script with ox_lib UI'
author 'idonttouchgrass Development'
version '1.0.0'

shared_script '@ox_lib/init.lua' -- required for ox_lib global

client_script 'client.lua'
server_script 'server.lua'
shared_script 'config.lua'

lua54 'yes'