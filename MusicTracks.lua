local _, ns = ...

ns.MusicTracks = {
    -- Add your own files here. WoW cannot enumerate addon folders at runtime,
    -- so each track must be declared manually.
    -- length is in seconds and is used for loop/sequential/random timing.
    list = {
        {
            name = "Example Track 1",
            path = "Interface\\AddOns\\PokeWoW\\assets\\music\\example1.mp3",
            length = 120,
        },
        {
            name = "Example Track 2",
            path = "Interface\\AddOns\\PokeWoW\\assets\\music\\example2.ogg",
            length = 95,
        },
    },
}
