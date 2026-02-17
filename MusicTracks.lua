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
        },
		{
            name = "Mortal Kombat Menu",
            path = "Interface\\AddOns\\PokeWoW\\Tracks\\MortalKombat_menu.mp3",
            length = 22,
        },
		{
            name = "Street Fighter Guile",
            path = "Interface\\AddOns\\PokeWoW\\Tracks\\StreetFighter_guile.mp3",
            length = 33,
        },
		{
            name = "Street Fighter Ken",
            path = "Interface\\AddOns\\PokeWoW\\Tracks\\StreetFighter_ken.mp3",
            length = 66,
        },
		{
            name = "Street Fighter II Theme",
            path = "Interface\\AddOns\\PokeWoW\\Tracks\\StreetFighter_main.mp3",
            length = 26,
        },
		{
            name = "Mortal Kombat Menu",
            path = "Interface\\AddOns\\PokeWoW\\Tracks\\MortalKombat_menu.mp3",
            length = 22,
        },
		{
            name = "Street Fighter Ryu",
            path = "Interface\\AddOns\\PokeWoW\\Tracks\\StreetFighter_ryu.mp3",
            length = 29,
        }
    },
}
