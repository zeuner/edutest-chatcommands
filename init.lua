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

--~minetest.register_privilege(
    --~ 'student',
    --~ {
        --~ description = S(
            --~ "player is affected by bulk commands targeted at students"
        --~ ),
        --~ give_to_singleplayer = false,
    --~ }
--~)

minetest.register_privilege(
    'instructor',
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
        if not privs["instructor"] or false == privs["instructor"] then
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
            instructor = true,
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
            instructor = true,
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
            instructor = true,
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
            instructor = true,
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
            instructor = true,
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
	"heal",
	{
		params = "<name>",
		description = S("set player's health to 20 HP"),
		privs = {instructor = true},
		func = function(self, name)
			if minetest.setting_getbool("enable_damage") == true then
				local ppl = minetest.get_player_by_name(name)
				if not ppl then
					return
				end
				ppl:set_hp(20)
				minetest.chat_send_player(name, "You were healed.")
			end
		end,
	}
)

minetest.register_chatcommand(
	"announce",
	{
		params = "<name> <message>",
		description = S("send a message in a popup"),
		privs = {instructor = true},
		func = function(self, namessage)
			local annText, annLine, annTemp, annName, mesg
			local bgcolor = '#dd4444cc'
			local maxlinewidth = 50
			mesg = minetest.formspec_escape(namessage)
			for word in mesg:gmatch("%S+") do
				if annName then
					if annLine then
						annTemp = annLine .. " " .. word
					else
						annTemp = word
					end
					if #annTemp < maxlinewidth then
						annLine = annTemp
					else
						-- wrap text
						annText = (annText or "") .. annLine .. "\n"
						annLine = word
					end
				else
					annName = word
				end
			end
			if annLine then
				annText = (annText or "") .. annLine
				local annFormspec = "size[8,2]bgcolor[" .. bgcolor .. "]label[1,0;" .. annText .. "]button_exit[0,0;1,1;okb;OK]"
				if minetest.get_player_by_name(annName) then
					minetest.show_formspec(annName, "annForm", annFormspec)
					return true
				else
					return false, "Player does not exist"
				end
			else
				return false, "Announcement text is empty"
			end
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
        if not privs["instructor"] or false == privs["instructor"] then
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
