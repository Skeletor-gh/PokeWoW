local _, ns = ...

ns.MusicTracks = {
    -- Add your own files here. WoW cannot enumerate addon folders at runtime,
    -- so each track must be declared manually.
    -- length is in seconds and is used for loop/sequential/random timing.
    list = {
        {
            name = "Pokemon",
            path = "Interface\\AddOns\\PokeWoW\\Tracks\\pokemon.mp3",
            length = 24,
        }        
    },
}
