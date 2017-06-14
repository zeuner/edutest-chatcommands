minetest.register_privilege(
    'student',
    {
        description = "player is affected by bulk commands targeted at students",
        give_to_singleplayer = false,
    }
)

minetest.register_privilege(
    'teacher',
    {
        description = "player can apply bulk commands targeted at students",
        give_to_singleplayer = false,
    }
)

minetest.register_chatcommand(
    "list_students",
    {
        description = "list student player names",
        privs = {
            teacher = true,
        },
        func = function(
            own_name,
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
                    minetest.chat_send_player(
                        own_name,
                        "EDUtest: found player " .. name
                    )
                end
            end
        end,
    }
)
