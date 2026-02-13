Config = {}

Config.Debug = false

-- Key mapping
Config.OpenKey = 'F1' -- Default key to open radio
Config.Command = 'radio' -- Command to open radio

-- Radio Settings
Config.MaxFrequency = 999
Config.RestrictedChannels = {
    [1] = {job = 'police'},
    [2] = {job = 'police'},
    [3] = {job = 'ambulance'},
    [4] = {job = 'ambulance'}
}

-- Animation Settings
Config.EnableAnimation = true
Config.Prop = 'prop_cs_hand_radio'

-- Item Settings
Config.RadioItem = 'radio' -- Item required to use radio (set to false to disable check)
