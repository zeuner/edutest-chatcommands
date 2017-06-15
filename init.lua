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

local on_join_handlers = {
}

local for_all_students = function(
    action
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
            action(
                player,
                name
            )
        end
    end
end

local split_command = function(
    command_string
)
    local delimiter = ""
    local params = ""
    local command
    local first = true
    for argument in string.gmatch(
        command_string,
        "[^ ]+"
    ) do
        if first then
            command = argument
            first = false
        else
            params = params .. delimiter .. argument
            delimiter = " "
        end
    end
    return command, params
end

minetest.register_chatcommand(
    "student_join_grant",
    {
        description = "grant privilege on student join",
        privs = {
            teacher = true,
        },
        func = function(
            own_name,
            param
        )
            on_join_handlers[
                "privilege_" .. param
            ] = {
                func = function(
                    player,
                    name
                )
                    minetest.chatcommands[
                        "grant"
                    ].func(
                        own_name,
                        name .. " " .. param
                    )
                    print(
                        "EDUtest: on join grant " .. param .. " to " .. name
                    )
                end,
            }
        end,
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
            for_all_students(
                function(
                    player,
                    name
                )
                    minetest.chat_send_player(
                        own_name,
                        "EDUtest: found player " .. name
                    )
                end
            )
        end,
    }
)

minetest.register_chatcommand(
    "every_student",
    {
        description = "apply command to all student players",
        privs = {
            teacher = true,
        },
        func = function(
            own_name,
            param
        )
            for_all_students(
                function(
                    player,
                    name
                )
                    local command, params = split_command(
                        string.gsub(
                            param,
                            "subject",
                            name
                        )
                    )
                    minetest.chatcommands[
                        command
                    ].func(
                        own_name,
                        params
                    )
                end
            )
        end,
    }
)

minetest.register_on_joinplayer(
    function (player)
        local name = player:get_player_name(
        )
        local privs = minetest.get_player_privs(
            name
        )
        if true == privs[
            "student"
        ] then
            print(
                "EDUtest: student joined: " .. name
            )
            for k, v in pairs(
                on_join_handlers
            ) do
                if nil ~= v.func then
                    v.func(
                        player,
                        name
                    )
                end
            end
        end
    end
)
