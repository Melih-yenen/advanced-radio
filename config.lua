Config = {}

Config.Debug = false

-- Key mapping
Config.OpenKey = 'F1' -- Default key to open radio
Config.Command = 'radio' -- Command to open radio

-- Radio Settings
Config.MinFrequency = 1.0
Config.MaxFrequency = 999
Config.FrequencyDecimals = 1
Config.DefaultVolume = 50
Config.Presets = { 91.1, 100.5, 450.0 }
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
