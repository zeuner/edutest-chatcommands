local die

local fatal = function(
    message
)
    minetest.log(
        "warning",
        "FATAL: " .. message
    )
    die(
    )
end

local MP = minetest.get_modpath(
    minetest.get_current_modname(
    )
)

local S = minetest.get_translator(
    "edutest-chatcommands"
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

local original_chatcommands = {
}

local chatcommand_state = {
}

local apply_chatcommand = function(
    player_name,
    command,
    arguments
)
    local result
    local explanation
    local done = false
    local entry = minetest.chatcommands[
        command
    ]
    if not entry then
        done, result, explanation = true, false, S(
            "unknown command @1",
            command
        )
    else
        local needed_privs = entry.privs
        if needed_privs then
            local allowed, missing = minetest.check_player_privs(
                player_name,
                needed_privs
            )
            if not allowed then
                done, result, explanation = true, false, S(
                    "missing privilege @1",
                    missing[1]
                )
            end
        end
    end
    if not done then
        result, explanation = entry.func(
            player_name,
            arguments
        )
    end
    local color
    if result then
        color = "green"
    else
        color = "red"
    end
    if explanation then
        minetest.chat_send_player(
            player_name,
            minetest.colorize(
                color,
                "EDUtest: " .. explanation
            )
        )
    end
    return result, explanation
end

local track_on_off_commands = function(
    on,
    off
)
    chatcommand_state[
        on
    ] = {
    }
    original_chatcommands[
        on
    ] = {
    }
    for k, v in pairs(
        minetest.chatcommands[
            on
        ]
    ) do
        original_chatcommands[
            on
        ][
            k
        ] = v
    end
    original_chatcommands[
        off
    ] = {
    }
    for k, v in pairs(
        minetest.chatcommands[
            off
        ]
    ) do
        original_chatcommands[
            off
        ][
            k
        ] = v
    end
    minetest.chatcommands[
        on
    ].func = function(
        own_name,
        param
    )
        original_chatcommands[
            on
        ].func(
            own_name,
            param
        )
        local name = param
        local player = minetest.get_player_by_name(
            name
        )
        if not player then
            minetest.chat_send_player(
                own_name,
                "EDUtest: " .. S(
                    "cannot find a player named @1",
                    name
                )
            )
            return
        end
        minetest.chat_send_player(
            own_name,
            "EDUtest: " .. S(
                "@1 registered",
                on
            )
        )
        chatcommand_state[
            on
        ][
            name
        ] = true
    end
    minetest.chatcommands[
        off
    ].func = function(
        own_name,
        param
    )
        original_chatcommands[
            off
        ].func(
            own_name,
            param
        )
        local name = param
        local player = minetest.get_player_by_name(
            name
        )
        if not player then
            minetest.chat_send_player(
                own_name,
                "EDUtest: " .. S(
                    "cannot find a player named @1",
                    name
                )
            )
            return
        end
        chatcommand_state[
            on
        ][
            name
        ] = nil
    end
end

local tracked_command_enabled = function(
    command
)
    return function(
        name
    )
        return chatcommand_state[
            command
        ][
            name
        ]
    end
end

if nil ~= minetest.chatcommands[
    "freeze"
] then
    minetest.log(
        "warning",
        "using external freeze mods is no longer recommended"
    )
end

local storage = minetest.get_mod_storage(
)

local pre_freeze = {
}

local pre_freeze_stored = storage:get(
    "pre_freeze"
)

if pre_freeze_stored then
    pre_freeze = minetest.deserialize(
        pre_freeze_stored
    )
end

minetest.register_chatcommand(
    "freeze",
    {
        params = "<name>",
        description = S(
            "Freeze a player"
        ),
        privs = {
            privs = true
        },
        func = function (
            name,
            param
        )
            local player = minetest.get_player_by_name(
                param
            )
            if not player then
                minetest.chat_send_player(
                    name,
                    "EDUtest: " .. S(
                        "cannot find a player named @1",
                        param
                    )
                )
                return
            end
            local pre_freeze_player = pre_freeze[
                param
            ]
            if pre_freeze_player
            and 0 == pre_freeze_player.speed
            and 0 == pre_freeze_player.jump then
                minetest.chat_send_player(
                    name,
                    "EDUtest: " .. S(
                        "player @1 is already frozen",
                        param
                    )
                )
                return
            end
            local settings_before = {
            }
            local physics = player:get_physics_override(
            )
            settings_before.speed = physics.speed
            settings_before.jump = physics.jump
            physics.speed = 0
            physics.jump = 0
            player:set_physics_override(
                physics
            )
            local privileges = minetest.get_player_privs(
                param
            )
            settings_before.interact = privileges.interact
            privileges.interact = nil
            minetest.set_player_privs(
                param,
                privileges
            )
            pre_freeze[
                param
            ] = settings_before
            storage:set_string(
                "pre_freeze",
                minetest.serialize(
                    pre_freeze
                )
            )
            minetest.chat_send_all(
                S(
                    "@1 was frozen by @2.",
                    param,
                    name
                )
            )
            minetest.log(
                "action",
                S(
                    "@1 was frozen at @2",
                    param,
                    minetest.pos_to_string(
                        vector.round(
                            player:get_pos(
                            )
                        )
                    )
                )
            )
        end
    }
)

minetest.register_chatcommand(
    "unfreeze",
    {
        params = "<name>",
        description = S(
            "Unfreeze a player"
        ),
        privs = {
            privs = true
        },
        func = function (
            name,
            param
        )
            local player = minetest.get_player_by_name(
                param
            )
            if not player then
                minetest.chat_send_player(
                    name,
                    "EDUtest: " .. S(
                        "cannot find a player named @1",
                        param
                    )
                )
                return
            end
            local settings_before = pre_freeze[
                param
            ]
            if not settings_before then
                settings_before = {
                    speed = 1,
                    jump = 1,
                    interact = true
                }
            end
            local physics = player:get_physics_override(
            )
            physics.speed = settings_before.speed
            physics.jump = settings_before.jump
            player:set_physics_override(
                physics
            )
            local privileges = minetest.get_player_privs(
                param
            )
            privileges.interact = settings_before.interact
            minetest.set_player_privs(
                param,
                privileges
            )
            pre_freeze[
                param
            ] = nil
            storage:set_string(
                "pre_freeze",
                minetest.serialize(
                    pre_freeze
                )
            )
            minetest.chat_send_player(
                param,
                S(
                    "You aren't frozen anymore."
                )
            )
            minetest.log(
                "action",
                S(
                    "@1 was molten at @2",
                    param,
                    minetest.pos_to_string(
                        vector.round(
                            player:get_pos(
                            )
                        )
                    )
                )
            )
        end
    }
)

if nil ~= minetest.chatcommands[
    "freeze"
] then
    track_on_off_commands(
        "freeze",
        "unfreeze"
    )
end

local is_student = function(
    name
)
    local privs = minetest.get_player_privs(
        name
    )
    return not privs[
        "teacher"
    ]
end

local is_teacher = function(
    name
)
    local privs = minetest.get_player_privs(
        name
    )
    return privs[
        "teacher"
    ]
end

edutest = {
}

local privileges_before_teacher = {
}

local privileges_before_teacher_stored = storage:get(
    "privileges_before_teacher"
)

if privileges_before_teacher_stored then
    privileges_before_teacher = minetest.deserialize(
        privileges_before_teacher_stored
    )
end

local potential_additional_teacher_privileges = {
    "ban",
    "bring",
    "fast",
    "freeze",
    "give",
    "home",
    "interact",
    "invisible",
    "kick",
    "noclip",
    "protection_bypass",
    "settime",
    "shout",
    "teleport",
    "worldedit",
}

local additional_teacher_privileges = {
}

for _, privilege in pairs(
    potential_additional_teacher_privileges
) do
    if minetest.registered_privileges[
        privilege
    ] then
        additional_teacher_privileges[
            privilege
        ] = true
    end
end

local give_additional_teacher_privileges = function(
    self,
    subject_name
)
    local self_name = self:get_player_name(
    )
    local old_privileges = {
    }
    local privs = minetest.get_player_privs(
        subject_name
    )
    for privilege, _ in pairs(
        additional_teacher_privileges
    ) do
        old_privileges[
            privilege
        ] = privs[
            privilege
        ]
        apply_chatcommand(
            self_name,
            "grant",
            subject_name .. " " .. privilege
        )
    end
    privileges_before_teacher[
        subject_name
    ] = old_privileges
    storage:set_string(
        "privileges_before_teacher",
        minetest.serialize(
            privileges_before_teacher
        )
    )
end

local revoke_additional_teacher_privileges = function(
    self,
    subject_name
)
    local self_name = self:get_player_name(
    )
    local before = privileges_before_teacher[
        subject_name
    ]
    if not before then
        before = {
        }
    end
    for privilege, _ in pairs(
        additional_teacher_privileges
    ) do
        if not before[
            privilege
        ] then
            apply_chatcommand(
                self_name,
                "revoke",
                subject_name .. " " .. privilege
            )
        end
    end
end

edutest.is_student = is_student

edutest.give_additional_teacher_privileges = give_additional_teacher_privileges

edutest.revoke_additional_teacher_privileges = revoke_additional_teacher_privileges

local teacher_to_student = function(
    self,
    subject_name
)
    edutest.revoke_additional_teacher_privileges(
        self,
        subject_name
    )
    apply_chatcommand(
        self:get_player_name(
        ),
        "revoke",
        subject_name .. " teacher"
    )
end

local student_to_teacher = function(
    self,
    subject_name
)
    apply_chatcommand(
        self:get_player_name(
        ),
        "grant",
        subject_name .. " teacher"
    )
    edutest.give_additional_teacher_privileges(
        self,
        subject_name
    )
end

edutest.is_student = is_student

edutest.is_teacher = is_teacher

edutest.student_to_teacher = student_to_teacher

edutest.teacher_to_student = teacher_to_student

local last_one_shot = 0

local register_one_shot = function(
    name,
    action
)
    last_one_shot = last_one_shot + 1
    local this_one_shot = last_one_shot
    local handler_id = "one_shot_" .. this_one_shot
    on_join_handlers[
        handler_id
    ] = {
        func = function(
            joining_player,
            joining_name
        )
            if name == joining_name then
                action(
                    joining_player,
                    joining_name
                )
                on_join_handlers[
                    handler_id
                ] = nil
            end
        end,
    }
end

local for_all_affected = function(
    command,
    action
)
    local found = 0
    for _, player in pairs(
        minetest.get_connected_players(
        )
    ) do
        local name = player:get_player_name(
        )
        if chatcommand_state[
            command
        ][
            name
        ] then
            found = found + 1
            action(
                player,
                name
            )
        end
    end
    if 0 == found then
        return false
    else
        return found
    end
end

local for_all_students = function(
    action
)
    local found = 0
    for _, player in pairs(
        minetest.get_connected_players(
        )
    ) do
        local name = player:get_player_name(
        )
        if name ~= minetest.settings:get(
            "name"
        )
        and edutest.is_student(
            name
        ) then
            found = found + 1
            action(
                player,
                name
            )
        end
    end
    if 0 == found then
        return false
    else
        return found
    end
end

local for_all_offline_students = function(
    action
)
    local found = 0
    for name, _ in minetest.get_auth_handler(
    ).iterate(
    ) do
        local player = minetest.get_player_by_name(
            name
        )
        if not player
        and name ~= minetest.settings:get(
            "name"
        )
        and edutest.is_student(
            name
        ) then
            found = found + 1
            action(
                player,
                name
            )
        end
    end
    if 0 == found then
        return false
    else
        return found
    end
end

local for_all_teachers = function(
    action
)
    local found = 0
    for _, player in pairs(
        minetest.get_connected_players(
        )
    ) do
        local name = player:get_player_name(
        )
        if edutest.is_teacher(
            name
        ) then
            found = found + 1
            action(
                player,
                name
            )
        end
    end
    if 0 == found then
        return false
    else
        return found
    end
end

local for_all_students_within_area = function(
    boundaries,
    action
)
    local found = 0
    for _, player in pairs(
        minetest.get_connected_players(
        )
    ) do
        local name = player:get_player_name(
        )
        if edutest.is_student(
            name
        ) then
            local within_area = true
            local pos = player:get_pos(
            )
            for axis, value in pairs(
                pos
            ) do
                if value < boundaries.min[
                    axis
                ] then
                    within_area = false
                end
                if boundaries.max[
                    axis
                ] < value then
                    within_area = false
                end
            end
            if within_area then
                found = found + 1
                action(
                    player,
                    name
                )
            end
        end
    end
    if 0 == found then
        return false
    else
        return found
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

if not minetest.features.object_independent_selectionbox then
    entity_selection_box = "collisionbox"
end

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
            minetest.log(
                "warning",
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
            if not data[
                "marker_id"
            ] then
                minetest.log(
                    "warning",
                    "EDUtest marker id missing, removing"
                )
                self.object:remove(
                )
                return
            end
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
    player_name = nil,
    marker_id = nil,
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

local group_storage_protocol = storage:get(
    "group_storage_protocol"
)

if not group_storage_protocol then
    if storage:get(
        "player_groups"
    ) then
        group_storage_protocol = "mod_storage"
    elseif minetest.chatcommands[
        "factions"
    ] then
        group_storage_protocol = "playerfactions_" .. factions.version
    else
        group_storage_protocol = "mod_storage"
    end
end

storage:set_string(
    "group_storage_protocol",
    group_storage_protocol
)

local possible_group_storage_protocol

if minetest.chatcommands[
    "factions"
] then
    possible_group_storage_protocol = "playerfactions_" .. factions.version
else
    possible_group_storage_protocol = "mod_storage"
end

local group_storage_upgraders = {
}

local load_mod_storage_player_groups = function(
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
end

local deep_copy

deep_copy = function(
    original
)
    if "table" == type(
        original
    ) then
        local copy = {
        }
        for k, v in pairs(
            original
        ) do
            copy[
                k
            ] = deep_copy(
                v
            )
        end
        return copy
    end
    return original
end

local deep_equal

deep_equal = function(
    one,
    other
)
    if type(
        one
    ) ~= type(
        other
    ) then
        return false
    end
    if "table" == type(
        one
    ) then
        for k, v in pairs(
            one
        ) do
            if not deep_equal(
                v,
                other[
                    k
                ]
            ) then
                return false
            end
        end
        for k, v in pairs(
            other
        ) do
            if not deep_equal(
                v,
                one[
                    k
                ]
            ) then
                return false
            end
        end
        return true
    end
    return one == other
end

group_storage_upgraders[
    minetest.serialize(
        {
            "mod_storage",
            "playerfactions_2"
        }
    )
] = function(
)
    load_mod_storage_player_groups(
    )
    local groups_found = 0
    local original_player_exists = minetest.player_exists
    local has_areas = false
    if minetest.chatcommands[
        "area_pos"
    ] then
        has_areas = true
    end
    local nontrivial_groups = {
    }
    local small_member_count = 2
    minetest.player_exists = function(
        player_name
    )
        return true
    end
    for name, content in pairs(
        player_groups
    ) do
        groups_found = groups_found + 1
        if not factions.register_faction(
            name,
            minetest.settings:get(
                "name"
            ),
            false
        ) then
            fatal(
                "could not register playerfactions group " .. name
            )
        end
        if not factions.leave_faction(
            name,
            minetest.settings:get(
                "name"
            )
        ) then
            fatal(
                "could not empty playerfactions group " .. name
            )
        end
        local members_found = 0
        for player_name, _ in pairs(
            content
        ) do
            members_found = members_found + 1
            if not factions.join_faction(
                name,
                player_name
            ) then
                fatal(
                    "could not add player " .. player_name .. " to playerfactions group " .. name
                )
            end
            if small_member_count < members_found
            and has_areas then
                nontrivial_groups[
                    name
                ] = {
                    members = members_found,
                    data = content
                }
            end
        end
        minetest.log(
            "info",
            "group " .. name .. ": converted " .. members_found .. " members"
        )
    end
    minetest.player_exists = original_player_exists
    minetest.log(
        "info",
        "converted " .. groups_found .. " groups"
    )
    if has_areas then
        local area_names = {
        }
        for id, area in pairs(
            areas.areas
        ) do
            if not area_names[
                area.name
            ] then
                area_names[
                    area.name
                ] = {
                }
            end
            table.insert(
                area_names[
                    area.name
                ],
                id
            )
        end
        for name, ids in pairs(
            area_names
        ) do
            local found = 0
            for k, v in pairs(
                ids
            ) do
                found = found + 1
            end
            if small_member_count >= found then
                area_names[
                    name
                ] = nil
            end
        end
        for name, ids in pairs(
            area_names
        ) do
            local is_first = true
            local first
            local mismatch = false
            for _, id in pairs(
                ids
            ) do
                if is_first then
                    first = deep_copy(
                        areas.areas[
                            id
                        ]
                    )
                    first.owner = nil
                    is_first = false
                else
                    local current = deep_copy(
                        areas.areas[
                            id
                        ]
                    )
                    current.owner = nil
                    if not deep_equal(
                        first,
                        current
                    ) then
                        mismatch = true
                    end
                end
            end
            if mismatch then
                area_names[
                    name
                ] = nil
            end
        end
        for name, ids in pairs(
            area_names
        ) do
            local owners = {
            }
            for _, id in pairs(
                ids
            ) do
                owners[
                    areas.areas[
                        id
                    ].owner
                ] = id
            end
            local match_size = 0
            local match
            local matched_areas
            for group_name, group_data in pairs(
                nontrivial_groups
            ) do
                local covered_areas = {
                }
                if group_data.members > match_size then
                    local mismatch = false
                    for member_name, _ in pairs(
                        group_data.data
                    ) do
                        local found = owners[
                            member_name
                        ]
                        if found then
                            covered_areas[
                                found
                            ] = true
                        else
                            mismatch = true
                            break
                        end
                    end
                    if not mismatch then
                        match_size = group_data.members
                        match = group_name
                        matched_areas = covered_areas
                    end
                end
            end
            if match then
                local area_data = deep_copy(
                    areas.areas[
                        ids[
                            1
                        ]
                    ]
                )
                local new_area = areas:add(
                    minetest.settings:get(
                        "name"
                    ),
                    area_data.name,
                    area_data.pos1,
                    area_data.pos2,
                    area_data.parent
                )
                areas.areas[
                    new_area
                ].faction_open = {
                    match
                }
                for superseded, _ in pairs(
                    matched_areas
                ) do
                    areas:remove(
                        superseded,
                        false
                    )
                end
                minetest.log(
                    "info",
                    "converted area " .. name .. " to playerfactions group " .. match
                )
            end
        end
    end
    return true
end

if possible_group_storage_protocol ~= group_storage_protocol then
    local upgrader = group_storage_upgraders[
        minetest.serialize(
            {
                group_storage_protocol,
                possible_group_storage_protocol
            }
        )
    ]
    if not upgrader then
        fatal(
            "don't know how to upgrade group storage protocol from " .. group_storage_protocol .. " to " .. possible_group_storage_protocol
        )
    end
    if not upgrader(
    ) then
        fatal(
            "failed upgrading group storage protocol from " .. group_storage_protocol .. " to " .. possible_group_storage_protocol
        )
    end
    group_storage_protocol = possible_group_storage_protocol
    storage:set_string(
        "group_storage_protocol",
        group_storage_protocol
    )
end

if "mod_storage" == group_storage_protocol then
    load_mod_storage_player_groups(
    )
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

local for_all_groups

local for_all_groups_mod_storage = function(
    action
)
    local found = 0
    for name, content in pairs(
        player_groups
    ) do
        found = found + 1
        action(
            name,
            content
        )
    end
    if 0 == found then
        return false
    else
        return found
    end
end

local for_all_groups_playerfactions_2 = function(
    action
)
    local found = 0
    local facts = factions.get_facts(
    )
    for name, content in pairs(
        facts
    ) do
        found = found + 1
        action(
            name,
            content.members
        )
    end
    if 0 == found then
        return false
    else
        return found
    end
end

local for_all_members

local for_all_members_mod_storage = function(
    group,
    action
)
    local found = 0
    for name, v in pairs(
        player_groups[
            group
        ]
    ) do
        found = found + 1
        local player = minetest.get_player_by_name(
            name
        )
        action(
            player,
            name
        )
    end
    if 0 == found then
        return false
    else
        return found
    end
end

local for_all_members_playerfactions_2 = function(
    group,
    action
)
    local found = 0
    local facts = factions.get_facts(
    )
    for name, _ in pairs(
        facts[
            group
        ].members
    ) do
        found = found + 1
        local player = minetest.get_player_by_name(
            name
        )
        action(
            player,
            name
        )
    end
    if 0 == found then
        return false
    else
        return found
    end
end

local for_all_nonmembers

local for_all_nonmembers_mod_storage = function(
    group,
    action
)
    local found = 0
    for _, player in pairs(
        minetest.get_connected_players(
        )
    ) do
        local name = player:get_player_name(
        )
        if not player_groups[
            group
        ][
            name
        ] then
            found = found + 1
            action(
                player,
                name
            )
        end
    end
    if 0 == found then
        return false
    else
        return found
    end
end

local for_all_nonmembers_playerfactions_2 = function(
    group,
    action
)
    local found = 0
    local facts = factions.get_facts(
    )
    for _, player in pairs(
        minetest.get_connected_players(
        )
    ) do
        local name = player:get_player_name(
        )
        if not facts[
            group
        ].members[
            name
        ] then
            found = found + 1
            action(
                player,
                name
            )
        end
    end
    if 0 == found then
        return false
    else
        return found
    end
end

local edge_boundaries = function(
    pos1,
    pos2
)
    local boundaries = {
    }
    for _, extreme in ipairs(
        {
            "min",
            "max",
        }
    ) do
        boundaries[
            extreme
        ] = {
        }
        for axis, value in pairs(
            pos1
        ) do
            boundaries[
                extreme
            ][
                axis
            ] = math[
                extreme
            ](
                value,
                pos2[
                    axis
                ]
            )
        end
    end
    return boundaries
end

local highlight_positions = function(
    name
)
    active_marker = 1
    local pos = edge_boundaries(
        player_highlighted[
            name
        ].pos1,
        player_highlighted[
            name
        ].pos2
    )
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
    "highlight_pos1",
    {
        params = "",
        description = S(
            "set position @1 of the highlighted area",
            1
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
        params = "",
        description = S(
            "set position @1 of the highlighted area",
            2
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
        params = "<" .. S(
            "command"
        ) .. "> [" .. S(
            "parameters"
        ) .. "...]",
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
            apply_chatcommand(
                own_name,
                "area_pos1",
                player_highlighted[
                    own_name
                ].pos1.x .. " " .. player_highlighted[
                    own_name
                ].pos1.y .. " " .. player_highlighted[
                    own_name
                ].pos1.z
            )
            apply_chatcommand(
                own_name,
                "area_pos2",
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
            apply_chatcommand(
                own_name,
                command,
                params
            )
        end
    }
)

local handle_create_group

local handle_create_group_mod_storage = function(
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
        "EDUtest: " .. S(
            "group named @1 created",
            name
        )
    )
end

local handle_create_group_playerfactions_2 = function(
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
    local facts = factions.get_facts(
    )
    if facts[
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
    factions.register_faction(
        name,
        own_name,
        false
    )
    minetest.chat_send_player(
        own_name,
        "EDUtest: " .. S(
            "group named @1 created",
            name
        )
    )
end

local handle_delete_group

local handle_delete_group_mod_storage = function(
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
        "EDUtest: " .. S(
            "group named @1 deleted",
            name
        )
    )
end

local handle_delete_group_playerfactions_2 = function(
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
    local facts = factions.get_facts(
    )
    if not facts[
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
    factions.disband_faction(
        name
    )
    minetest.chat_send_player(
        own_name,
        "EDUtest: " .. S(
            "group named @1 deleted",
            name
        )
    )
end

local handle_enter_group

local handle_enter_group_mod_storage = function(
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
        "EDUtest: " .. S(
            "player @1 added to group named @2",
            player,
            group
        )
    )
end

local handle_enter_group_playerfactions_2 = function(
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
    local facts = factions.get_facts(
    )
    if not facts[
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
    if facts[
        group
    ].members[
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
    factions.join_faction(
        group,
        player
    )
    minetest.chat_send_player(
        own_name,
        "EDUtest: " .. S(
            "player @1 added to group named @2",
            player,
            group
        )
    )
end

local handle_leave_group

local handle_leave_group_mod_storage = function(
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
        "EDUtest: " .. S(
            "player @1 removed from group named @2",
            player,
            group
        )
    )
end

local handle_leave_group_playerfactions_2 = function(
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
    local facts = factions.get_facts(
    )
    if not facts[
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
    if not facts[
        group
    ].members[
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
    factions.leave_faction(
        group,
        player
    )
    minetest.chat_send_player(
        own_name,
        "EDUtest: " .. S(
            "player @1 removed from group named @2",
            player,
            group
        )
    )
end

local handle_highlight_set_owner_group

local handle_highlight_set_owner_group_mod_storage = function(
    own_name,
    param
)
    local group, area = param:match(
        '^(%S+)%s(.+)$'
    )
    if not group then
        minetest.chat_send_player(
            own_name,
            "EDUtest: " .. S(
                "group and area name must be specified"
            )
        )
        return
    end
    if not player_highlighted[
        own_name
    ] then
        minetest.chat_send_player(
            own_name,
            "EDUtest: " .. S(
                "no area highlighted yet"
            )
        )
        return
    end
    apply_chatcommand(
        own_name,
        "area_pos1",
        player_highlighted[
            own_name
        ].pos1.x .. " " .. player_highlighted[
            own_name
        ].pos1.y .. " " .. player_highlighted[
            own_name
        ].pos1.z
    )
    apply_chatcommand(
        own_name,
        "area_pos2",
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
    apply_chatcommand(
        own_name,
        "set_owner",
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
    if not for_all_members(
        group,
        function(
            player,
            name
        )
            apply_chatcommand(
                own_name,
                "add_owner",
                new_area_id .. " " .. name .. " " .. area
            )
        end
    ) then
        minetest.chat_send_player(
            own_name,
            "EDUtest: " .. S(
                "no group members found"
            )
        )
    end
    apply_chatcommand(
        own_name,
        "remove_area",
        new_area_id
    )
end

local handle_highlight_set_owner_group_playerfactions_2 = function(
    own_name,
    param
)
    local group, area = param:match(
        '^(%S+)%s(.+)$'
    )
    if not group then
        minetest.chat_send_player(
            own_name,
            "EDUtest: " .. S(
                "group and area name must be specified"
            )
        )
        return
    end
    if not player_highlighted[
        own_name
    ] then
        minetest.chat_send_player(
            own_name,
            "EDUtest: " .. S(
                "no area highlighted yet"
            )
        )
        return
    end
    apply_chatcommand(
        own_name,
        "area_pos1",
        player_highlighted[
            own_name
        ].pos1.x .. " " .. player_highlighted[
            own_name
        ].pos1.y .. " " .. player_highlighted[
            own_name
        ].pos1.z
    )
    apply_chatcommand(
        own_name,
        "area_pos2",
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
    apply_chatcommand(
        own_name,
        "set_owner",
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
    apply_chatcommand(
        own_name,
        "area_faction_open",
        new_area_id .. " " .. group
    )
end

local handle_list_members

local handle_list_members_mod_storage = function(
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
    if not for_all_members(
        group,
        function(
            player,
            name
        )
            minetest.chat_send_player(
                own_name,
                "EDUtest: " .. S(
                    "found player @1",
                    name
                )
            )
        end
    ) then
        minetest.chat_send_player(
            own_name,
            "EDUtest: " .. S(
                "no group members found"
            )
        )
    end
end

local handle_list_members_playerfactions_2 = function(
    own_name,
    param
)
    local group = param
    local facts = factions.get_facts(
    )
    if not facts[
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
    if not for_all_members(
        group,
        function(
            player,
            name
        )
            minetest.chat_send_player(
                own_name,
                "EDUtest: " .. S(
                    "found player @1",
                    name
                )
            )
        end
    ) then
        minetest.chat_send_player(
            own_name,
            "EDUtest: " .. S(
                "no group members found"
            )
        )
    end
end

local handle_every_member

local handle_every_member_mod_storage = function(
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
    if not for_all_members(
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
            apply_chatcommand(
                own_name,
                command,
                params
            )
        end
    ) then
        minetest.chat_send_player(
            own_name,
            "EDUtest: " .. S(
                "no group members found"
            )
        )
    end
end

local handle_every_member_playerfactions_2 = function(
    own_name,
    param
)
    local group, param = split_command(
        param
    )
    local facts = factions.get_facts(
    )
    if not facts[
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
    if not for_all_members(
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
            apply_chatcommand(
                own_name,
                command,
                params
            )
        end
    ) then
        minetest.chat_send_player(
            own_name,
            "EDUtest: " .. S(
                "no group members found"
            )
        )
    end
end

if "playerfactions_2" == group_storage_protocol then
    for_all_groups = for_all_groups_playerfactions_2
    for_all_members = for_all_members_playerfactions_2
    for_all_nonmembers = for_all_nonmembers_playerfactions_2
    handle_create_group = handle_create_group_playerfactions_2
    handle_delete_group = handle_delete_group_playerfactions_2
    handle_enter_group = handle_enter_group_playerfactions_2
    handle_leave_group = handle_leave_group_playerfactions_2
    handle_highlight_set_owner_group = handle_highlight_set_owner_group_playerfactions_2
    handle_list_members = handle_list_members_playerfactions_2
    handle_every_member = handle_every_member_playerfactions_2
elseif "mod_storage" == group_storage_protocol then
    for_all_groups = for_all_groups_mod_storage
    for_all_members = for_all_members_mod_storage
    for_all_nonmembers = for_all_nonmembers_mod_storage
    handle_create_group = handle_create_group_mod_storage
    handle_delete_group = handle_delete_group_mod_storage
    handle_enter_group = handle_enter_group_mod_storage
    handle_leave_group = handle_leave_group_mod_storage
    handle_highlight_set_owner_group = handle_highlight_set_owner_group_mod_storage
    handle_list_members = handle_list_members_mod_storage
    handle_every_member = handle_every_member_mod_storage
else
    fatal(
        "unsupported group storage protocol " .. group_storage_protocol
    )
end

minetest.register_chatcommand(
    "create_group",
    {
        params = "<" .. S(
            "group name"
        ) .. ">",
        description = S(
            "create a group of players"
        ),
        privs = {
            teacher = true,
        },
        func = handle_create_group
    }
)

minetest.register_chatcommand(
    "delete_group",
    {
        params = "<" .. S(
            "group name"
        ) .. ">",
        description = S(
            "delete a group of players"
        ),
        privs = {
            teacher = true,
        },
        func = handle_delete_group
    }
)

minetest.register_chatcommand(
    "enter_group",
    {
        params = "<" .. S(
            "group name"
        ) .. "> <" .. S(
            "player name"
        ) .. ">",
        description = S(
            "add a player to a group"
        ),
        privs = {
            teacher = true,
        },
        func = handle_enter_group
    }
)

minetest.register_chatcommand(
    "leave_group",
    {
        params = "<" .. S(
            "group name"
        ) .. "> <" .. S(
            "player name"
        ) .. ">",
        description = S(
            "remove a player from a group"
        ),
        privs = {
            teacher = true,
        },
        func = handle_leave_group
    }
)

minetest.register_chatcommand(
    "highlight_set_owner_group",
    {
        params = "<" .. S(
            "group name"
        ) .. "> <" .. S(
            "area name"
        ) .. ">",
        description = S(
            "make the highlighted area owned by a group"
        ),
        privs = {
        },
        func = handle_highlight_set_owner_group
    }
)

minetest.register_chatcommand(
    "creative_hand",
    {
        params = "[" .. S(
            "player name"
        ) .. "]",
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
                    "EDUtest: " .. S(
                        "cannot find a player named @1",
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
        params = "[" .. S(
            "player name"
        ) .. "]",
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
                    "EDUtest: " .. S(
                        "cannot find a player named @1",
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

track_on_off_commands(
    "creative_hand",
    "basic_hand"
)

minetest.register_chatcommand(
    "student_join_keep_priv",
    {
        params = "<" .. S(
            "privilege"
        ) .. ">",
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
        params = "<" .. S(
            "privilege"
        ) .. ">",
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
                    apply_chatcommand(
                        own_name,
                        "revoke",
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
        params = "<" .. S(
            "privilege"
        ) .. ">",
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
                    apply_chatcommand(
                        own_name,
                        "grant",
                        name .. " " .. param
                    )
                end,
            }
        end,
    }
)

minetest.register_chatcommand(
    "on_join_msg",
    {
        params = "[" .. S(
            "message"
        ) .. "]",
        description = S(
            "notify students on join"
        ),
        privs = {
            teacher = true,
        },
        func = function(
            own_name,
            param
        )
            on_join_handlers[
                "msg_" .. param
            ] = {
                func = function(
                    player,
                    name
                )
                    minetest.chat_send_player(
                        name,
                        param
                    )
                end,
            }
        end,
    }
)

local item_packs = {
}

local item_packs_stored = storage:get(
    "item_packs"
)

if item_packs_stored then
    item_packs = minetest.deserialize(
        item_packs_stored
    )
end

minetest.register_chatcommand(
    "item_pack_add",
    {
        params = "<" .. S(
            "item pack name"
        ) .. "> <" .. S(
            "itemstring"
        ) .. "> [" .. S(
            "count"
        ) .. "]",
        description = S(
            "add items to an item pack"
        ),
        privs = {
            teacher = true,
        },
        func = function(
            own_name,
            param
        )
            if "" == param then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "need to specify item pack"
                    )
                )
                return
            end
            local pack, param = split_command(
                param
            )
            if "" == param then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "need to specify item"
                    )
                )
                return
            end
            local item, count_raw = split_command(
                param
            )
            if not minetest.registered_items[
                item
            ] then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "item @1 does not exist",
                        item
                    )
                )
                return
            end
            local count = 1
            if "" ~= count_raw then
                local count_matched = count_raw:match "^%d+$"
                if not count_matched then
                    minetest.chat_send_player(
                        name,
                        "EDUtest: " .. S(
                            "Invalid item count"
                        )
                    )
                    return false
                end
                count = count_matched
            end
            if not item_packs[
                pack
            ] then
                item_packs[
                    pack
                ] = {
                }
            end
            if not item_packs[
                pack
            ][
                item
            ] then
                item_packs[
                    pack
                ][
                    item
                ] = 0
            end
            item_packs[
                pack
            ][
                item
            ] = item_packs[
                pack
            ][
                item
            ] + count
            storage:set_string(
                "item_packs",
                minetest.serialize(
                    item_packs
                )
            )
            minetest.chat_send_player(
                own_name,
                "EDUtest: " .. S(
                    "added @1 of item @2 to item pack @3",
                    count,
                    item,
                    pack
                )
            )
        end,
    }
)

minetest.register_chatcommand(
    "item_pack_remove",
    {
        params = "<" .. S(
            "item pack name"
        ) .. "> <" .. S(
            "itemstring"
        ) .. "> [" .. S(
            "count"
        ) .. "]",
        description = S(
            "remove items from an item pack"
        ),
        privs = {
            teacher = true,
        },
        func = function(
            own_name,
            param
        )
            if "" == param then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "need to specify item pack"
                    )
                )
                return
            end
            local pack, param = split_command(
                param
            )
            if "" == param then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "need to specify item"
                    )
                )
                return
            end
            local item, count_raw = split_command(
                param
            )
            if not minetest.registered_items[
                item
            ] then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "item @1 does not exist",
                        item
                    )
                )
                return
            end
            local count = "all"
            if "" ~= count_raw then
                local count_matched = count_raw:match "^%d+$"
                if not count_matched then
                    minetest.chat_send_player(
                        name,
                        "EDUtest: " .. S(
                            "Invalid item count"
                        )
                    )
                    return false
                end
                count = count_matched
            end
            if not item_packs[
                pack
            ] then
                item_packs[
                    pack
                ] = {
                }
            end
            if not item_packs[
                pack
            ][
                item
            ] then
                item_packs[
                    pack
                ][
                    item
                ] = 0
            end
            local new_count
            if "all" == count then
                new_count = 0
            else
                new_count = item_packs[
                    pack
                ][
                    item
                ] - count
            end
            if 0 > new_count then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "item @1 is not included @2 times",
                        item,
                        count
                    )
                )
                return
            end
            if 0 == new_count then
                new_count = nil
            end
            item_packs[
                pack
            ][
                item
            ] = new_count
            storage:set_string(
                "item_packs",
                minetest.serialize(
                    item_packs
                )
            )
            minetest.chat_send_player(
                own_name,
                "EDUtest: " .. S(
                    "removed @1 of item @2 from item pack @3",
                    count,
                    item,
                    pack
                )
            )
        end,
    }
)

local for_all_item_packs = function(
    action
)
    local found = 0
    for pack_name, _ in pairs(
        item_packs
    ) do
        found = found + 1
        action(
            pack_name
        )
    end
    if 0 == found then
        return false
    else
        return found
    end
end

local for_all_pack_items = function(
    pack,
    action
)
    local found = 0
    if not item_packs[
        pack
    ] then
        return false
    end
    for item, count in pairs(
        item_packs[
            pack
        ]
    ) do
        found = found + 1
        action(
            item,
            count
        )
    end
    if 0 == found then
        return false
    else
        return found
    end
end

minetest.register_chatcommand(
    "item_pack_give",
    {
        params = "<" .. S(
            "player name"
        ) .. "> <" .. S(
            "item pack name"
        ) .. ">",
        description = S(
            "add items to an item pack"
        ),
        privs = {
            teacher = true,
        },
        func = function(
            own_name,
            param
        )
            if "" == param then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "need to specify player name"
                    )
                )
                return
            end
            local player_name, pack = split_command(
                param
            )
            if "" == pack then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "need to specify item pack"
                    )
                )
                return
            end
            if not item_packs[
                pack
            ] then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "item pack @1 does not exist",
                        pack
                    )
                )
                return
            end
            for_all_pack_items(
                pack,
                function(
                    item_name,
                    count
                )
                    apply_chatcommand(
                        own_name,
                        "give",
                        player_name .. " " .. item_name .. " " .. count
                    )
                end
            )
        end,
    }
)

minetest.register_chatcommand(
    "list_students",
    {
        params = "",
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
            if not for_all_students(
                function(
                    player,
                    name
                )
                    minetest.chat_send_player(
                        own_name,
                        "EDUtest: " .. S(
                            "found player @1",
                            name
                        )
                    )
                end
            ) then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "no student players found"
                    )
                )
            end
        end,
    }
)

minetest.register_chatcommand(
    "list_teachers",
    {
        params = "",
        description = S(
            "list teacher player names"
        ),
        privs = {
            teacher = true,
        },
        func = function(
            own_name,
            param
        )
            if not for_all_teachers(
                function(
                    player,
                    name
                )
                    minetest.chat_send_player(
                        own_name,
                        "EDUtest: " .. S(
                            "found player @1",
                            name
                        )
                    )
                end
            ) then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "no teacher players found"
                    )
                )
            end
        end,
    }
)

minetest.register_chatcommand(
    "list_groups",
    {
        params = "",
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
            if not for_all_groups(
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
                        "EDUtest: " .. S(
                            "found group @1 (player count @2)",
                            name,
                            count
                        )
                    )
               end
            ) then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "no groups configured"
                    )
                )
            end
        end,
    }
)

minetest.register_chatcommand(
    "list_affected",
    {
        params = "<" .. S(
            "command name"
        ) .. ">",
        description = S(
            "list players affected by status switch command"
        ),
        privs = {
            teacher = true,
        },
        func = function(
            own_name,
            param
        )
            local command = param
            if not chatcommand_state[
                command
            ] then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "no list of affected players"
                    )
                )
                return
            end
            if not for_all_affected(
                command,
                function(
                    player,
                    name
                )
                    minetest.chat_send_player(
                        own_name,
                        "EDUtest: " .. S(
                            "found player @1",
                            name
                        )
                    )
                end
            ) then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "no affected players found"
                    )
                )
            end
        end,
    }
)

minetest.register_chatcommand(
    "list_members",
    {
        params = "<" .. S(
            "group name"
        ) .. ">",
        description = S(
            "list group member names"
        ),
        privs = {
            teacher = true,
        },
        func = handle_list_members
    }
)

minetest.register_chatcommand(
    "every_student",
    {
        params = "<" .. S(
            "command"
        ) .. "> [" .. S(
            "parameters"
        ) .. "...]",
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
            if not for_all_students(
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
                    apply_chatcommand(
                        own_name,
                        command,
                        params
                    )
                end
            ) then
                 minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "no student players found"
                    )
                )
            end
        end,
    }
)

local edge_boundaries = function(
    pos1,
    pos2
)
    local boundaries = {
    }
    for _, extreme in ipairs(
        {
            "min",
            "max",
        }
    ) do
        boundaries[
            extreme
        ] = {
        }
        for axis, value in pairs(
            pos1
        ) do
            boundaries[
                extreme
            ][
                axis
            ] = math[
                extreme
            ](
                value,
                pos2[
                    axis
                ]
            )
        end
    end
    return boundaries
end

minetest.register_chatcommand(
    "every_highlighted",
    {
        description = S(
            "apply command to all student players within the highlighted area"
        ),
        privs = {
            teacher = true,
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
                    "EDUtest: " .. S(
                        "no area highlighted yet"
                    )
                )
                return
            end
            local boundaries = edge_boundaries(
                player_highlighted[
                    own_name
                ].pos1,
                player_highlighted[
                    own_name
                ].pos2
            )
            if not for_all_students_within_area(
                boundaries,
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
                    apply_chatcommand(
                        own_name,
                        command,
                        params
                    )
                end
            ) then
                 minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "no student players found within the highlighted area"
                    )
                )
            end
        end,
    }
)

minetest.register_chatcommand(
    "every_member",
    {
        params = "<" .. S(
            "group name"
        ) .. "> <" .. S(
            "command"
        ) .. "> [" .. S(
            "parameters"
        ) .. "...]",
        description = S(
            "apply command to all group members"
        ),
        privs = {
            teacher = true,
        },
        func = handle_every_member
    }
)

minetest.register_chatcommand(
    "visitation",
    {
        params = "<X>,<Y>,<Z> | <" .. S(
            "destination player"
        ) .. "> | <" .. S(
            "teleported player"
        ) .. "> <X>,<Y>,<Z> | <" .. S(
            "teleported player"
        ) .. "> <" .. S(
            "destination player"
        ) .. ">",
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
                    "EDUtest: " .. S(
                        "cannot find a player named @1",
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
            apply_chatcommand(
                own_name,
                "teleport",
                param
            )
        end,
    }
)

minetest.register_chatcommand(
    "setnextpos",
    {
        params = "<" .. S(
            "player"
        ) .. ">",
        description = S(
            "have a player start at the current position on the next login"
        ),
        privs = {
            teacher = true,
        },
        func = function(
            own_name,
            param
        )
            local positioned = minetest.get_player_by_name(
                param
            )
            if not positioned then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "cannot find a player named @1",
                        param
                    )
                )
                return
            end
            local current_pos = positioned:get_pos(
            )
            teleportee:set_attribute(
                "next_login_position",
                minetest.serialize(
                    current_pos
                )
            )
            register_one_shot(
                param,
                function(
                    player,
                    name
                )
                    local login_position = player:get_attribute(
                        "next_login_position"
                    )
                    if login_position then
                        login_position = minetest.deserialize(
                            login_position
                        )
                    end
                    player:set_pos(
                        login_position
                    )
                end
            )
        end,
    }
)

minetest.register_chatcommand(
    "return",
    {
        params = "[" .. S(
            "player name"
        ) .. "]",
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
                    "EDUtest: " .. S(
                        "cannot find a player named @1",
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
            local pos_string = old_pos.x .. "," .. old_pos.y .. "," .. old_pos.z
            apply_chatcommand(
                own_name,
                "teleport",
                teleportee_name .. " " .. pos_string
            )
        end,
    }
)

minetest.register_on_joinplayer(
    function (player)
        local name = player:get_player_name(
        )
        if edutest.is_student(
            name
        ) then
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

edutest.adapt_highlighted_area = adapt_highlighted_area
edutest.set_highlight_marker_click_handler = set_highlight_marker_click_handler
edutest.set_highlight_marker_tooltip = set_highlight_marker_tooltip
edutest.for_all_offline_students = for_all_offline_students
edutest.for_all_students = for_all_students
edutest.for_all_teachers = for_all_teachers
edutest.for_all_members = for_all_members
edutest.for_all_nonmembers = for_all_nonmembers
edutest.for_all_groups = for_all_groups
edutest.for_all_pack_items = for_all_pack_items
edutest.for_all_item_packs = for_all_item_packs
edutest.tracked_command_enabled = tracked_command_enabled
edutest.apply_chatcommand = apply_chatcommand
