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

local digtime = 42

local caps = {
    times = {
        digtime,
        digtime,
        digtime
    },
    uses = 0,
    maxlevel = 256
}

minetest.register_item(
    "edutest_chatcommands:creative_hand",
    {
        type = "none",
        wield_image = "wieldhand.png",
        wield_scale = {
            x = 1,
            y = 1,
            z = 2.5
        },
        range = 10,
        tool_capabilities = {
            full_punch_interval = 0.5,
            max_drop_level = 3,
            groupcaps = {
                crumbly = caps,
                cracky  = caps,
                snappy  = caps,
                choppy  = caps,
                oddly_breakable_by_hand = caps,
            },
            damage_groups = {
                fleshy = 10
            },
        }
    }
)

minetest.register_item(
    "edutest_chatcommands:basic_hand",
    {
        type = "none",
        wield_image = "wieldhand.png",
        wield_scale = {
            x = 1,
            y = 1,
            z = 2.5
        },
        tool_capabilities = {
            full_punch_interval = 0.9,
            max_drop_level = 0,
            groupcaps = {
                crumbly = {
                    times={
                        [2] = 3.00,
                        [3] = 0.70
                    },
                    uses = 0,
                    maxlevel = 1
                },
                snappy = {
                    times={
                        [3] = 0.40
                    },
                    uses = 0,
                    maxlevel = 1
                },
                oddly_breakable_by_hand = {
                    times = {
                        [1] = 3.50,
                        [2] = 2.00,
                        [3] = 0.70
                    },
                    uses = 0
                }
            },
            damage_groups = {
                fleshy = 1
            },
        }
    }
)

local player_block_position = function(
    name
)
    local pos = minetest.get_player_by_name(
        name
    ):getpos(
    )
    return {
        x = math.floor(
            pos.x + 0.5
        ),
        y = math.floor(
            pos.y + 0.5
        ),
        z = math.floor(
            pos.z + 0.5
        ),
    }
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

local active_marker = nil

local highlight_marker_click_handler = function(
    self,
    clicker
)
end

local set_highlight_marker_click_handler = function(
    handler
)
    highlight_marker_click_handler = handler
end

local entity_selection_box = "selectionbox"

(
    function(
    )
        local version = minetest.get_version(
        )
        local components = {
        }
        for w in (
            version.string .. "."
        ):gmatch(
            "([0-9]*)[.]"
        ) do
            table.insert(
                components,
                "0" .. w
            )
        end
        local numeric = 0
        local significance = 1000000
        for n, w in ipairs(
            components
        ) do
            numeric = numeric + significance * w
            significance = math.floor(
                (
                    significance / 100
                ) + 0.5
            )
        end
        if 50000 > numeric then
            entity_selection_box = "collisionbox"
        end
    end
)(
)

local player_highlighted = {
}

local player_markers = {
}

local player_groups = {
}

local marker_properties = {
    initial_properties = {
        visual = "upright_sprite",
        textures = {
            "area_highlight_hex.png"
        },
        physical = false,
    },
    on_activate = function(
        self,
        staticdata
    )
        local data = minetest.deserialize(
            staticdata
        )
        if not data then
            print(
                "EDUtest no marker data given, removing"
            )
            self.object:remove(
            )
            return
        end
        if data[
            "object_propertios"
        ] then
            self.object:set_properties(
                data[
                    "object_propertios"
                ]
            )
            data[
                "object_propertios"
            ] = nil
        end
        if data[
            "player_name"
        ] then
            if not player_markers[
                data[
                    "player_name"
                ]
            ] then
                player_markers[
                    data[
                        "player_name"
                    ]
                ] = {
                }
            end
             player_markers[
                data[
                    "player_name"
                ]
            ][
                data[
                    "marker_id"
                ]
            ] = self.object
            data[
                "marker_id"
            ] = nil
            data[
                "player_name"
            ] = nil
        end
        for k, v in pairs(
            data
        ) do
            self[
                k
            ] = v
        end
    end,
    on_step = function(
        self,
        dtime
    )
        if not active_marker then
            self.object:remove(
            )
        end
    end,
    on_rightclick = function(
        self,
        clicker
    )
        return highlight_marker_click_handler(
            self,
            clicker
        )
    end,
    get_staticdata = function(
        self
    )
        local serializable = {
        }
        for k,v in pairs(
            self
        ) do
            local value_type = type(
                v
            )
            if (
                'userdata' ~= value_type
                 and 'function' ~= value_type
            ) then
                serializable[
                    k
                ] = v
            end
        end
        serializable[
            "object_propertios"
        ] = self.object:get_properties(
        )
        return minetest.serialize(
            serializable
        )
    end,
    range = nil,
}

minetest.register_entity(
    ":edutest:highlight_marker",
    marker_properties
)

local set_highlight_marker_tooltip = function(
    tooltip
)
    minetest.registered_entities[
        "edutest:highlight_marker"
    ].initial_properties.infotext = tooltip
end

local storage = minetest.get_mod_storage(
)

for group in string.gmatch(
    storage:get_string(
        "player_groups"
    ),
    "[^ ]+"
) do
    if "" ~= group then
        player_groups[
            group
        ] = {
        }
    end
end

for group, v in pairs(
    player_groups
) do
    for player in string.gmatch(
        storage:get_string(
            "player_group_" .. group
        ),
        "[^ ]+"
    ) do
        if "" ~= player then
            player_groups[
                group
            ][
                player
            ] = 1
        end
    end
end

local collapse_keys = function(
    collapsed
)
    local delimiter = ""
    local list = ""
    for k, v in pairs(
        collapsed
    ) do
        list = list .. delimiter .. k
        delimiter = " "
    end
    return list
end

local for_all_groups = function(
    action
)
    for name, content in pairs(
        player_groups
    ) do
        action(
            name,
            content
        )
    end
end

local for_all_members = function(
    group,
    action
)
    for name, v in pairs(
        player_groups[
            group
        ]
    ) do
        local player = minetest.get_player_by_name(
            name
        )
        action(
            player,
            name
        )
    end
end

local highlight_positions = function(
    name
)
    active_marker = 1
    local pos1 = player_highlighted[
        name
    ].pos1
    local pos2 = player_highlighted[
        name
    ].pos2
    local pos = {
    }
    for _, extreme in ipairs(
        {
            "min",
            "max",
        }
    ) do
        pos[
            extreme
        ] = {
        }
        for k, v in pairs(
            pos1
        ) do
            pos[
                extreme
            ][
                k
            ] = math[
                extreme
            ](
                v,
                pos2[
                    k
                ]
            )
        end
    end
    local markers = {
    }
    for _, axis in ipairs(
        {
            {
                displacement = "z",
                range = "x",
                rotation = 0,
            },
            {
                displacement = "x",
                range = "z",
                rotation = math.pi / 2,
            },
        }
    ) do
        for _, displaced in ipairs(
            {
                pos.min[
                    axis.displacement
                ] - 0.5,
                pos.max[
                    axis.displacement
                ] + 0.5,
            }
        ) do
            local marker_pos = {
                x = (
                    pos.min.x + pos.max.x
                ) / 2,
                y = (
                    pos.min.y + pos.max.y
                ) / 2,
                z = (
                    pos.min.z + pos.max.z
                ) / 2,
            }
            marker_pos[
                axis.displacement
            ] = displaced
            local marker = minetest.add_entity(
                marker_pos,
                "edutest:highlight_marker",
                minetest.serialize(
                    {
                    }
                )
            )
            marker:set_yaw(
                axis.rotation
            )
            local selection_sizes = {
            }
            selection_sizes[
                axis.range
            ] = 0.5 * (
                pos.max[
                    axis.range
                ] - pos.min[
                    axis.range
                ] + 1
            )
            selection_sizes[
                axis.displacement
            ] = 0.1
            selection_sizes[
                "y"
            ] = 0.5 * (
                pos.max.y - pos.min.y + 1
            )
            local marker_properties = {
                visual_size = {
                    x = pos.max[
                        axis.range
                    ] - pos.min[
                        axis.range
                    ] + 1,
                    y = pos.max.y - pos.min.y + 1,
                },
            }
            marker_properties[
                entity_selection_box
            ] = {
                -1.0 * selection_sizes.x,
                -1.0 * selection_sizes.y,
                -1.0 * selection_sizes.z,
                selection_sizes.x,
                selection_sizes.y,
                selection_sizes.z,
            }
            marker:get_luaentity(
            ).range = axis.range
            local marker_id = axis.displacement .. displaced
            marker:get_luaentity(
            ).marker_id = marker_id
            marker:get_luaentity(
            ).player_name = name
            marker:set_properties(
                marker_properties
            )
            markers[
                marker_id
            ] = marker
        end
    end
    if player_markers[
        name
    ] then
        for k, v in pairs(
            player_markers[
                name
            ]
        ) do
            v:remove(
            )
        end
    end
    player_markers[
        name
    ] = markers
end

local adapt_highlighted_area = function(
    name,
    axis,
    extreme,
    adjustment
)
    local selected_value = math[
        extreme
    ](
        player_highlighted[
            name
        ].pos1[
            axis
        ],
        player_highlighted[
            name
        ].pos2[
            axis
        ]
    )
    local selected_edge = nil
    for edge, coordinates in pairs(
        player_highlighted[
            name
        ]
    ) do
        if selected_value == coordinates[
            axis
        ] then
            selected_edge = edge
        end
    end
    player_highlighted[
        name
    ][
        selected_edge
    ][
        axis
    ] = player_highlighted[
        name
    ][
        selected_edge
    ][
        axis
    ] + adjustment
    highlight_positions(
        name
    )
end

minetest.register_chatcommand(
    "create_group",
    {
        description = S(
            "create a group of players"
        ),
        privs = {
            teacher = true,
        },
        func = function(
            own_name,
            param
        )
            local name = nil
            if "" == param then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "group name must be specified"
                    )
                )
                return
            else
                name = param
            end
            if player_groups[
                name
            ] then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "group already exists"
                    )
                )
                return
            end
            player_groups[
                name
            ] = {
            }
            storage:set_string(
                "player_groups",
                collapse_keys(
                    player_groups
                )
            )
            minetest.chat_send_player(
                own_name,
                "EDUtest: " .. string.format(
                    S(
                        "group named %s created"
                    ),
                    name
                )
            )
        end
    }
)

minetest.register_chatcommand(
    "delete_group",
    {
        description = S(
            "delete a group of players"
        ),
        privs = {
            teacher = true,
        },
        func = function(
            own_name,
            param
        )
            local name = nil
            if "" == param then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "group name must be specified"
                    )
                )
                return
            else
                name = param
            end
            if not player_groups[
                name
            ] then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "group does not exists"
                    )
                )
                return
            end
            player_groups[
                name
            ] = nil
            storage:set_string(
                "player_groups",
                collapse_keys(
                    player_groups
                )
            )
            minetest.chat_send_player(
                own_name,
                "EDUtest: " .. string.format(
                    S(
                        "group named %s deleted"
                    ),
                    name
                )
            )
        end
    }
)

minetest.register_chatcommand(
    "enter_group",
    {
        description = S(
            "add a player to a group"
        ),
        privs = {
            teacher = true,
        },
        func = function(
            own_name,
            param
        )
            local player = nil
            local group = nil
            local first = true
            for argument in string.gmatch(
                param,
                "[^ ]+"
            ) do
                if player then
                    minetest.chat_send_player(
                        own_name,
                        "EDUtest: " .. S(
                            "too many parameters given"
                        )
                    )
                    return
                end
                if first then
                    group = argument
                    first = false
                else
                    player = argument
                    local name = nil
                end
            end
            if not group then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "group name must be specified"
                    )
                )
                return
            end
            if not player then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "player name must be specified"
                    )
                )
                return
            end
            if not player_groups[
                group
            ] then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "group does not exists"
                    )
                )
                return
            end
            if player_groups[
                group
            ][
                player
            ] then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "player already belongs to the group"
                    )
                )
                return
            end
            player_groups[
                group
            ][
                player
            ] = 1
            storage:set_string(
                "player_group_" .. group,
                collapse_keys(
                    player_groups[
                        group
                    ]
                )
            )
            minetest.chat_send_player(
                own_name,
                "EDUtest: " .. string.format(
                    S(
                        "player %s added to group named %s"
                    ),
                    player,
                    group
                )
            )
        end
    }
)

minetest.register_chatcommand(
    "leave_group",
    {
        description = S(
            "remove a player from a group"
        ),
        privs = {
            teacher = true,
        },
        func = function(
            own_name,
            param
        )
            local player = nil
            local group = nil
            local first = true
            for argument in string.gmatch(
                param,
                "[^ ]+"
            ) do
                if player then
                    minetest.chat_send_player(
                        own_name,
                        "EDUtest: " .. S(
                            "too many parameters given"
                        )
                    )
                    return
                end
                if first then
                    group = argument
                    first = false
                else
                    player = argument
                    local name = nil
                end
            end
            if not group then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "group name must be specified"
                    )
                )
                return
            end
            if not player then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "player name must be specified"
                    )
                )
                return
            end
            if not player_groups[
                group
            ] then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "group does not exists"
                    )
                )
                return
            end
            if not player_groups[
                group
            ][
                player
            ] then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "player does not belong to the group"
                    )
                )
                return
            end
            player_groups[
                group
            ][
                player
            ] = nil
            storage:set_string(
                "player_group_" .. group,
                collapse_keys(
                    player_groups[
                        group
                    ]
                )
            )
            minetest.chat_send_player(
                own_name,
                "EDUtest: " .. string.format(
                    S(
                        "player %s removed from group named %s"
                    ),
                    player,
                    group
                )
            )
        end
    }
)

minetest.register_chatcommand(
    "highlight_pos1",
    {
        description = S(
            "set position 1 of the highlighted area"
        ),
        privs = {
        },
        func = function(
            own_name,
            param
        )
            local pos = player_block_position(
                own_name
            )
            if not player_highlighted[
                own_name
            ] then
                player_highlighted[
                    own_name
                ] = {
                }
            end
            player_highlighted[
                own_name
            ].pos1 = pos
            if not player_highlighted[
                own_name
            ].pos2 then
                player_highlighted[
                    own_name
                ].pos2 = player_highlighted[
                    own_name
                ].pos1
            end
            highlight_positions(
                own_name
            )
        end
    }
)

minetest.register_chatcommand(
    "highlight_pos2",
    {
        description = S(
            "set position 2 of the highlighted area"
        ),
        privs = {
        },
        func = function(
            own_name,
            param
        )
            local pos = player_block_position(
                own_name
            )
            if not player_highlighted[
                own_name
            ] then
                player_highlighted[
                    own_name
                ] = {
                }
            end
            player_highlighted[
                own_name
            ].pos2 = pos
            if not player_highlighted[
                own_name
            ].pos1 then
                player_highlighted[
                    own_name
                ].pos1 = player_highlighted[
                    own_name
                ].pos2
            end
            highlight_positions(
                own_name
            )
        end
    }
)

local highlighted_areas = function(
    player_name
)
    if not player_highlighted[
        player_name
    ] then
        return nil
    end
    local center = {
        x = (
            player_highlighted[
                player_name
            ].pos1.x + player_highlighted[
                player_name
            ].pos2.x
        ) / 2.0,
        y = (
            player_highlighted[
                player_name
            ].pos1.y + player_highlighted[
                player_name
            ].pos2.y
        ) / 2.0,
        z = (
            player_highlighted[
                player_name
            ].pos1.z + player_highlighted[
                player_name
            ].pos2.z
        ) / 2.0,
    }
    return areas:getAreasAtPos(
        center
    )
end

minetest.register_chatcommand(
    "highlight_areas",
    {
        description = S(
            "apply areas command on highlighted area"
        ),
        privs = {
        },
        func = function(
            own_name,
            param
        )
            if not player_highlighted[
                own_name
            ] then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. string.format(
                        S(
                            "no area highlighted yet"
                        )
                    )
                )
                return
            end
            minetest.chatcommands[
                "area_pos1"
            ].func(
                own_name,
                player_highlighted[
                    own_name
                ].pos1.x .. " " .. player_highlighted[
                    own_name
                ].pos1.y .. " " .. player_highlighted[
                    own_name
                ].pos1.z
            )
            minetest.chatcommands[
                "area_pos2"
            ].func(
                own_name,
                player_highlighted[
                    own_name
                ].pos2.x .. " " .. player_highlighted[
                    own_name
                ].pos2.y .. " " .. player_highlighted[
                    own_name
                ].pos2.z
            )
            local command, params = split_command(
                param
            )
            minetest.chatcommands[
                command
            ].func(
                own_name,
                params
            )
        end
    }
)

minetest.register_chatcommand(
    "highlight_set_owner_group",
    {
        description = S(
            "make the highlighted area owned by a group"
        ),
        privs = {
        },
        func = function(
            own_name,
            param
        )
            local group, area = param:match(
                '^(%S+)%s(.+)$'
            )
            if not group then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. string.format(
                        S(
                            "group and area name must be specified"
                        )
                    )
                )
                return
            end
            if not player_highlighted[
                own_name
            ] then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. string.format(
                        S(
                            "no area highlighted yet"
                        )
                    )
                )
                return
            end
            minetest.chatcommands[
                "area_pos1"
            ].func(
                own_name,
                player_highlighted[
                    own_name
                ].pos1.x .. " " .. player_highlighted[
                    own_name
                ].pos1.y .. " " .. player_highlighted[
                    own_name
                ].pos1.z
            )
            minetest.chatcommands[
                "area_pos2"
            ].func(
                own_name,
                player_highlighted[
                    own_name
                ].pos2.x .. " " .. player_highlighted[
                    own_name
                ].pos2.y .. " " .. player_highlighted[
                    own_name
                ].pos2.z
            )
            local before = highlighted_areas(
                own_name
            )
            minetest.chatcommands[
                "set_owner"
            ].func(
                own_name,
                minetest.settings:get(
                    "name"
                ) .. " " .. area
            )
            local after = highlighted_areas(
                own_name
            )
            for id, v in pairs(
                before
            ) do
                after[
                    id
                ] = nil
            end
            local new_area_id
            for id, v in pairs(
                after
            ) do
                new_area_id = id
            end
            for_all_members(
                group,
                function(
                    player,
                    name
                )
                    minetest.chatcommands[
                        "add_owner"
                    ].func(
                        own_name,
                        new_area_id .. " " .. name .. " " .. area
                    )
                end
            )
            minetest.chatcommands[
                "remove_area"
            ].func(
                own_name,
                new_area_id
            )
        end
    }
)

minetest.register_chatcommand(
    "creative_hand",
    {
        description = S(
            "set the empty hand of a player to creative mode characteristics"
        ),
        privs = {
            privs = true,
        },
        func = function(
            own_name,
            param
        )
            local name = nil
            if "" == param then
                name = own_name
            else
                name = param
            end
            local player = minetest.get_player_by_name(
                name
            )
            if not player then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. string.format(
                        S(
                            "cannot find a player named %s"
                        ),
                        name
                    )
                )
                return
            end
            player:get_inventory(
            ):remove_item(
                "hand",
                "edutest_chatcommands:basic_hand"
            )
            player:get_inventory(
            ):add_item(
                "hand",
                "edutest_chatcommands:creative_hand"
            )
        end,
    }
)

minetest.register_chatcommand(
    "basic_hand",
    {
        description = S(
            "set the empty hand of a player to survival mode characteristics"
        ),
        privs = {
            privs = true,
        },
        func = function(
            own_name,
            param
        )
            local name = nil
            if "" == param then
                name = own_name
            else
                name = param
            end
            local player = minetest.get_player_by_name(
                name
            )
            if not player then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. string.format(
                        S(
                            "cannot find a player named %s"
                        ),
                        name
                    )
                )
                return
            end
            player:get_inventory(
            ):remove_item(
                "hand",
                "edutest_chatcommands:creative_hand"
            )
            player:get_inventory(
            ):add_item(
                "hand",
                "edutest_chatcommands:basic_hand"
            )
        end,
    }
)

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
    "list_groups",
    {
        description = S(
            "list group names"
        ),
        privs = {
            teacher = true,
        },
        func = function(
            own_name,
            param
        )
            for_all_groups(
                function(
                    name,
                    players
                )
                    local count = 0
                    for k, v in pairs(
                        players
                    ) do
                        count = count + 1
                    end
                    minetest.chat_send_player(
                        own_name,
                        "EDUtest: " .. string.format(
                            S(
                                "found group %s (player count %d)"
                            ),
                            name,
                            count
                        )
                    )
               end
            )
        end,
    }
)

minetest.register_chatcommand(
    "list_members",
    {
        description = S(
            "list group member names"
        ),
        privs = {
            teacher = true,
        },
        func = function(
            own_name,
            param
        )
            local group = param
            if not player_groups[
                group
            ] then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "group does not exists"
                    )
                )
                return
            end
            for_all_members(
                group,
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
    "every_member",
    {
        description = S(
            "apply command to all group members"
        ),
        privs = {
            teacher = true,
        },
        func = function(
            own_name,
            param
        )
            local group, param = split_command(
                param
            )
            if not player_groups[
                group
            ] then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "group does not exists"
                    )
                )
                return
            end
            for_all_members(
                group,
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
    adapt_highlighted_area = adapt_highlighted_area,
    set_highlight_marker_click_handler = set_highlight_marker_click_handler,
    set_highlight_marker_tooltip = set_highlight_marker_tooltip,
    for_all_students = for_all_students,
    for_all_members = for_all_members,
    for_all_groups = for_all_groups,
}
