local S

if minetest.get_modpath(
    "intllib"
) then
    S = intllib.Getter(
    )
else
    S = function(
        translated
    )
        return translated
    end
end

minetest.register_privilege(
    'student',
    {
        description = S(
            "player is affected by bulk commands targeted at students"
        ),
        give_to_singleplayer = false,
    }
)

minetest.register_privilege(
    'teacher',
    {
        description = S(
            "player can apply bulk commands targeted at students"
        ),
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
    "student_join_keep_priv",
    {
        description = S(
            "keep privilege on student join"
        ),
        privs = {
            teacher = true,
        },
        func = function(
            own_name,
            param
        )
            on_join_handlers[
                "privilege_" .. param
            ] = nil
        end,
    }
)

minetest.register_chatcommand(
    "student_join_revoke",
    {
        description = S(
            "revoke privilege on student join"
        ),
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
                        "revoke"
                    ].func(
                        own_name,
                        name .. " " .. param
                    )
                end,
            }
        end,
    }
)

minetest.register_chatcommand(
    "student_join_grant",
    {
        description = S(
            "grant privilege on student join"
        ),
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
                end,
            }
        end,
    }
)

minetest.register_chatcommand(
    "list_students",
    {
        description = S(
            "list student player names"
        ),
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
                        "EDUtest: " .. string.format(
                            S(
                                "found player %s"
                            ),
                            name
                        )
                    )
                end
            )
        end,
    }
)

minetest.register_chatcommand(
    "every_student",
    {
        description = S(
            "apply command to all student players"
        ),
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

minetest.register_chatcommand(
    "visitation",
    {
        description = S(
            "reversibly teleport self or other players"
        ),
        privs = {
        },
        func = function(
            own_name,
            param
        )
            local teleportee_name = nil
            local target = nil
            teleportee_name, target = string.match(
                param,
                "^([^ ]+) +(.+)$"
            )
            if not teleportee_name then
                teleportee_name = own_name
            end
            local teleportee = minetest.get_player_by_name(
                teleportee_name
            )
            if not teleportee then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. string.format(
                        S(
                            "cannot find a player named %s"
                        ),
                        teleportee_name
                    )
                )
                return
            end
            local return_positions = teleportee:get_attribute(
                "return_positions"
            )
            if return_positions then
                return_positions = minetest.deserialize(
                    return_positions
                )
            end
            local old_pos = teleportee:get_pos(
            )
            teleportee:set_attribute(
                "return_positions",
                minetest.serialize(
                    {
                        head = old_pos,
                        tail = return_positions,
                    }
                )
            )
            minetest.chatcommands[
                "teleport"
            ].func(
                own_name,
                param
            )
        end,
    }
)

minetest.register_chatcommand(
    "return",
    {
        description = S(
            "teleport to location before the last visitation command"
        ),
        privs = {
        },
        func = function(
            own_name,
            param
        )
            local teleportee_name = nil
            if "" == param then
                teleportee_name = own_name
            else
                teleportee_name = param
            end
            local teleportee = minetest.get_player_by_name(
                teleportee_name
            )
            if not teleportee then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. string.format(
                        S(
                            "cannot find a player named %s"
                        ),
                        teleportee_name
                    )
                )
                return
            end
            local return_positions = teleportee:get_attribute(
                "return_positions"
            )
            if return_positions then
                return_positions = minetest.deserialize(
                    return_positions
                )
            end
            if not return_positions then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "no previous position stored"
                    )
                )
                return
            end
            local old_pos = return_positions.head
            teleportee:set_attribute(
                "return_positions",
                minetest.serialize(
                    return_positions.tail
                )
            )
            minetest.chatcommands[
                "teleport"
            ].func(
                own_name,
                teleportee_name .. " " .. old_pos.x .. "," .. old_pos.y .. "," .. old_pos.z
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

edutest = {
    for_all_students = for_all_students,
}
