minetest.register_privilege(
    'student',
    {
        description = "player is affected by bulk commands targeted at students",
        give_to_singleplayer = false,
    }
)

minetest.register_chatcommand(
    "list_students",
    {
        description = core.gettext(
            "list student player names"
        ),
        func = function(
            param
        )
            for _, player in pairs(
                minetest.get_connected_players(
                )
            ) do
                local name = player:get_player_name(
                )
                local privs = minetest.get_player_privs(
                    name
                )
                if true == privs[
                    "student"
                ] then
                    print(
                        name
                    )
                end
            end
        end,
    }
)
