local UDKP_Elapsed = 0;
local UDKP_Classes = { "Death Knight", "Druid", "Hunter", "Mage", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior" };
local UDKP_SnapshotColorMap = {
    ["grey"] = 0,
    ["white"] = 1,
    ["green"] = 2,
    ["blue"] = 3,
    ["purple"] = 4,
    ["orange"] = 5,
    ["red"] = 6
};
local UDKP_LootColorMap = {
    ["ff9d9d9d"] = 0, -- grey
    ["ffffffff"] = 1, -- white
    ["ff1eff00"] = 2, -- green
    ["ff0070dd"] = 3, -- blue
    ["ffa335ee"] = 4, -- purple
    ["ffff8000"] = 5, -- orange
    ["ffff0000"] = 6  -- red
}

local UDKP_LastQueuePrintTime = 0;

local UDKP_QueueWhispers = {};

local UDKP_DKPWhispers = {};

local UDKP_DefaultLanguage = GetDefaultLanguage(player);

local UDKP_ConvertToRaidOnJoin = false;

local frm
local editBox

columnHeads = {
	{
			["name"] = "Snp",
			["width"] = 30,
			["align"] = "CENTER",
			["bgcolor"] = { ["r"] = 0.2, ["g"] = 0.2, ["b"] = 0.2, ["a"] = 0.5 },
			["tooltipText"] = "Number of snapshot\rDouble click to remove snapshot",
			["dblclick"] = function(button, dataz, colsz, rowz, realrowz, columnz )
				
				if (dataz[realrowz].cols[1].value) then
			        local snum = tonumber(dataz[realrowz].cols[1].value); -- snapshot number
			        if (snum and UDKP_Snapshots) then
					for k, v in pairs(UDKP_Snapshots) do
						if (k == snum) then
							tremove(UDKP_Snapshots, snum);
							GmaticDKP_Print("Removed snapshot entry " .. snum .. ".");
							GmaticDKP_UpdateData();
							return;
						end
					end
					GmaticDKP_Print("Snapshot entry " .. snum .. " not found.");
				end
				else
					GmaticDKP_Print("Usage: /snapshot remove <snapshot #>");
				end
			end,
		}, -- [1]
		{
			["name"] = "lp",
			["width"] = 30,
			["align"] = "CENTER",
			["bgcolor"] = { ["r"] = 0.2, ["g"] = 0.2, ["b"] = 0.2, ["a"] = 0.5 },
			["tooltipText"] = "Number of Number of item in snapshot",
			["dblclick"] = function(button, dataz, colsz, rowz, realrowz, columnz )
				local snum = tonumber(dataz[realrowz].cols[1].value); -- snapshot number
				local inum = tonumber(dataz[realrowz].cols[2].value); -- item number in snapshot
				if (snum and inum) then
					local snapshot = UDKP_Snapshots[snum];
					if (not snapshot) then
					    GmaticDKP_PrintError("Snapshot " .. snum .. " not found.");
					    return;
					end
					local loot = snapshot["loot"];
					local item = loot[inum];
					if (not item) then
						GmaticDKP_PrintError("Item " .. inum .. " not found in snapshot " .. snum .. ".");
						return;
					end
					GmaticDKP_Print("Removed " .. item["item"] .. " from " .. item["player"] .. ".");
					tremove(loot, inum);
					
					GmaticDKP_UpdateData();
					return;
				end
				end,
		}, -- [1]
		{
			["name"] = "Event",
			["width"] = 100,
			["align"] = "CENTER",
			["color"] = { ["r"] = 0.0, ["g"] = 1.0, ["b"] = 1.0, ["a"] = 1.0 },
			["bgcolor"] = { ["r"] = 0.2, ["g"] = 0.2, ["b"] = 0.2, ["a"] = 0.5 },
			["sortnext"]= 4,
			["tooltipText"] = "Name of event",
		}, -- [2]
		{
			["name"] = "Link",
			["width"] = 200,
			["align"] = "CENTER",
			["bgcolor"] = { ["r"] = 0.2, ["g"] = 0.2, ["b"] = 0.2, ["a"] = 0.5 },
			["tooltipText"] = "Acquired item",
			["onhover"] =	function(button, link)
				SetItemRef(link)
				end,
		}, -- [3]
		{
			["name"] = "Player",
			["width"] = 150,
			["align"] = "CENTER",
			["color"] = { ["r"] = 1.0, ["g"] = 1.0, ["b"] = 0.0, ["a"] = 1.0 },
			["bgcolor"] = { ["r"] = 0.2, ["g"] = 0.2, ["b"] = 0.2, ["a"] = 0.5 },
			["tooltipText"] = "Player name",
		}, -- [4]
		{
			["name"] = "DKP",
			["width"] = 30,
			["align"] = "CENTER",
			["color"] = { ["r"] = 1.0, ["g"] = 0.0, ["b"] = 1.0, ["a"] = 1.0 },
			["bgcolor"] = { ["r"] = 0.2, ["g"] = 0.2, ["b"] = 0.2, ["a"] = 0.5 },
			["tooltipText"] = "double click item to edit",
			["dblclick"] = function(button, data, cols, row, realrow, column )
				if not frm then
					frm = CreateResizableWindow("GDKP_AddDKP", "Add DKP", 180, 80, nil)
					frm:SetPoint("CENTER", UDKP_Frame, "CENTER", 0, 0)
					frm:SetBackdrop({bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
						edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
						tile = true, tileSize = 16, edgeSize = 16,
						insets = { left = 5, right = 5, top = 5, bottom = 5 }})
					frm:SetBackdropColor(.75, .75, .75)
					editBox = CreateFrame("EditBox", "myEdit", frm, "InputBoxTemplate")
					editBox:SetWidth(80)
					editBox:SetHeight(20)
					editBox:SetPoint("TOPLEFT", frm, "TOPLEFT", 35, -30)
					editBox:SetAutoFocus(true)

					local editBoxLabel = editBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
					editBoxLabel:SetPoint("RIGHT", 25, 0)
					editBoxLabel:SetText("DKP")
				end
				editBox:SetScript("OnEnterPressed", function()
						local noted = editBox:GetText()
						frm:Hide();
						if(noted == "") then
							return;
						end
						local snum = tonumber(data[realrow].cols[1].value);
						local inum = tonumber(data[realrow].cols[2].value);
						if (snum and inum) then
							local snapshot = UDKP_Snapshots[snum];
							if (not snapshot) then
							    GmaticDKP_PrintError("Snapshot " .. snum .. " not found.");
							    return;
							end

							local loot = snapshot["loot"];
							local item = loot[inum];
							if (not item) then
							    GmaticDKP_PrintError("Item " .. inum .. " not found in snapshot " .. snum .. ".");
							    return;
							end

							item["note"] = noted;
							GmaticDKP_Print("Recorded " .. noted .. " for " .. item["item"] .. " to " .. data[realrow].cols[5].value);
							GmaticDKP_UpdateData();
							return;
						end
						end)
				frm:Show();
				end,
		} -- [5]
	};

function GmaticDKP_UDKPHelp (args)
    local _, _, cmd, params = string.find(args, "([^%s]+) ?(.*)")

    if (cmd) then
        if (cmd == "cal") then
            GmaticDKP_Calendar(params);
        end
    else
        GmaticDKP_Print("Guildomatic DKP Module Help");
        GmaticDKP_Print(HIGHLIGHT_FONT_COLOR_CODE .. "/dkp" .. NORMAL_FONT_COLOR_CODE .. " <name/class/all/raid> [check dkp]");
        GmaticDKP_Print(HIGHLIGHT_FONT_COLOR_CODE .. "/dkp" .. NORMAL_FONT_COLOR_CODE .. " <on/off> [enable/disable dkp lookups]");
        GmaticDKP_Print(HIGHLIGHT_FONT_COLOR_CODE .. "/snapshot" .. NORMAL_FONT_COLOR_CODE .. " [help menu for snapshot]");
        GmaticDKP_Print(HIGHLIGHT_FONT_COLOR_CODE .. "/queue" .. NORMAL_FONT_COLOR_CODE .. " [help menu for queue]");
        GmaticDKP_Print(HIGHLIGHT_FONT_COLOR_CODE .. "/auction" .. NORMAL_FONT_COLOR_CODE .. " [help menu for auction]");
        GmaticDKP_Print(HIGHLIGHT_FONT_COLOR_CODE .. "/roster" .. NORMAL_FONT_COLOR_CODE .. " [record the guild roster]");
        GmaticDKP_Print(HIGHLIGHT_FONT_COLOR_CODE .. "/gmatic cal" .. NORMAL_FONT_COLOR_CODE .. " [help menu for raid calendar events]")
    end
end

function GmaticDKP_Calendar (args)
    local _, _, cmd, params = string.find(args, "([^%s]+) ?(.*)")

    if (cmd) then
        if (not UDKP_Calendar_Events or table.getn(UDKP_Calendar_Events) == 0) then
            GmaticDKP_PrintError("No raid calendar events. Did you download the latest in-game module static file?");
        elseif (cmd == "list") then
            GmaticDKP_CalendarList();
        elseif (cmd == "info") then
            GmaticDKP_CalendarInfo(tonumber(params));
        elseif (cmd == "sync") then
            GmaticDKP_CalendarSync(tonumber(params));
        elseif (cmd == "invite") then
            GmaticDKP_CalendarInvite(params);
        end
    else
        GmaticDKP_Print(HIGHLIGHT_FONT_COLOR_CODE .. "/gmatic cal" .. NORMAL_FONT_COLOR_CODE .. " [help menu for raid calendar events]")
        GmaticDKP_Print(HIGHLIGHT_FONT_COLOR_CODE .. "/gmatic cal list" .. NORMAL_FONT_COLOR_CODE .. " [list raid calendar events]")
        GmaticDKP_Print(HIGHLIGHT_FONT_COLOR_CODE .. "/gmatic cal info <event #>" .. NORMAL_FONT_COLOR_CODE .. " [display event info]")
        GmaticDKP_Print(HIGHLIGHT_FONT_COLOR_CODE .. "/gmatic cal sync <event #>" .. NORMAL_FONT_COLOR_CODE .. " [sync event info to in-game calendar]")
        GmaticDKP_Print(HIGHLIGHT_FONT_COLOR_CODE .. "/gmatic cal invite <all|accepted|queued> <event #>" .. NORMAL_FONT_COLOR_CODE .. " [invite selected signups into raid]")
    end
end

function GmaticDKP_CalendarList ()
    for k, v in pairs(UDKP_Calendar_Events) do
        num_accepted = table.getn(v["accepted"]);
        num_queued = table.getn(v["queued"]);
        
        GmaticDKP_Print(HIGHLIGHT_FONT_COLOR_CODE .. k .. ". " .. NORMAL_FONT_COLOR_CODE .. v["date"] .. " " .. v["title"] .. " [" .. num_accepted + num_queued .. " signups].");
    end
end

function GmaticDKP_CalendarInfo (index)
    if (index) then
        event = UDKP_Calendar_Events[index];
        if (event) then
            GmaticDKP_Print(HIGHLIGHT_FONT_COLOR_CODE .. "Raid event info for event #" .. index)
            GmaticDKP_Print(" - " .. event["title"]);
            GmaticDKP_Print(" - " .. event["date"]);
            
            num_accepted = table.getn(event["accepted"]);
            GmaticDKP_Print(" - Accepted Signups [" .. num_accepted .. "]");
            if (num_accepted > 0) then
                GmaticDKP_Print(table.concat(event["accepted"], ", "));
            end
            
            num_queued = table.getn(event["queued"]);
            GmaticDKP_Print(" - Queued Signups [" .. num_queued .. "]");
            if (num_queued > 0) then
                GmaticDKP_Print("    " .. table.concat(event["queued"], ", "));
            end
        else
            GmaticDKP_PrintError("No such event.");
        end
    else
        GmaticDKP_PrintError("Event # is required for this command.");
    end
end

function GmaticDKP_CalendarSync (index)
    if (index) then
        event = UDKP_Calendar_Events[index];
        if (event) then
            GmaticDKP_Print(HIGHLIGHT_FONT_COLOR_CODE .. "Syncing raid event #" .. index)
            GmaticDKP_Print(" - " .. event["title"]);
            GmaticDKP_Print(" - " .. event["date"]);

            -- parse out the time
            local _, _, mm, dd, yyyy, hh, min = string.find(event["date"], "(%d+)/(%d+)/(%d+) (%d+):(%d+)");
            
            if (not mm) then
                GmaticDKP_PrintError("Couldn't parse the date. Please re-download the static file.");
                return;
            end
            
            -- sync this info into the in-game WoW calendar by creating a new event
            -- if the user syncs twice, they'll have two events, maybe we should
            -- delete the old one in the future?
            CalendarNewGuildWideEvent();
            -- only default to raids for now
            CalendarEventSetType(CALENDAR_EVENTTYPE_RAID);
            CalendarEventSetTitle(event["title"]);
            CalendarEventSetDescription("Synced from Guildomatic module data [" .. UDKP_DKP_LastUpdate .. "].")
            CalendarEventSetDate(mm, dd, yyyy);
            CalendarEventSetTime(hh, min);
            -- save this event before we issue out invites
            CalendarAddEvent();
            
            -- we'd actually sync invites if blizzard didn't require a hardware event for
            -- the CalendarEventInvite() API call
            -- GmaticDKP_CalendarSyncInvites(index);
                        
            GmaticDKP_Print(HIGHLIGHT_FONT_COLOR_CODE .. "Raid event successfully synced.")
        else
            GmaticDKP_PrintError("No such event.");
        end
    else
        GmaticDKP_PrintError("Event # is required for this command.");
    end
end

-- this doesn't work right now due to Blizzard/taint/API issues preventing mass
-- invites
function GmaticDKP_CalendarSyncInvites (index)
    if (index) then
        event = UDKP_Calendar_Events[index];
        if (event) then
            local signups = GmaticDKP_CalendarFilterSignups(event["accepted"]);
            signups = GmaticDKP_CalendarFilterSignups(event["queued"]);
            for k, player in pairs(signups) do
                CalendarEventInvite(player);
            end
        end
    end
end

function GmaticDKP_CalendarInvite (args)
    local _, _, param, event_no = string.find(args, "([^%s]+) ([^%s]+)");
    if (param and event_no) then        
        -- look up the event
        event = UDKP_Calendar_Events[tonumber(event_no)];
        if (not event) then
            GmaticDKP_PrintError("No such event.");
            return;
        end
        
        if (GetNumRaidMembers() == 0) then
            if (GetNumPartyMembers() > 0) then
                ConvertToRaid();
            else
                -- set the flag to convert to a raid as soon as we're in a party
                UDKP_ConvertToRaidOnJoin = true;
            end
        end
            
        GmaticDKP_Print("Inviting " .. param .. " signups for " .. HIGHLIGHT_FONT_COLOR_CODE .. event["title"] .. " " .. event["date"] .. NORMAL_FONT_COLOR_CODE .. ".");
        if (param == "accepted" or param == "queued") then
            local signups = GmaticDKP_CalendarFilterSignups(event[param]);
            GmaticDKP_CalendarInviteSignups(signups);
        elseif (param == "all") then
            local signups = GmaticDKP_CalendarFilterSignups(event["accepted"]);
            signups = GmaticDKP_CalendarFilterSignups(event["queued"]);
            GmaticDKP_CalendarInviteSignups(signups);
        end

        return;
    end
    
    -- if we fell through to here, something bad happened
    GmaticDKP_PrintError("Usage: " .. HIGHLIGHT_FONT_COLOR_CODE .. "/gmatic cal invite <all|accepted|queued> <event #> " .. RED_FONT_COLOR_CODE .. ".")
end

function GmaticDKP_CalendarFilterSignups (signups)
    local new_signups = {};
    local filter_members = {};

    -- if we're in a party or a raid, remove the members from the signups to invite
    if (signups and table.getn(signups) > 0) then
        -- we'll never invite ourself
        filter_members[UnitName("player")] = "1";
        if (GetNumRaidMembers() > 0) then
            for i = 1, GetNumRaidMembers(), 1 do
                filter_members[UnitName("raid" .. i)] = "1";
            end
        elseif (GetNumPartyMembers() > 0) then
            for i = 1, GetNumPartyMembers(), 1 do
                filter_members[UnitName("party" .. i)] = "1";
            end
        end

        for k, v in pairs(signups) do
            if (not filter_members[v]) then
                table.insert(new_signups, v)
            end
        end
    end
    
    return new_signups;
end

function GmaticDKP_CalendarInviteSignups (signups)
    if (table.getn(signups) == 0) then
        GmaticDKP_PrintError("No valid signups to invite.");
    else
        for k, v in pairs(signups) do
            InviteUnit(v);
        end
    end
end

function GmaticDKP_Roster (arg)
    if (not IsInGuild()) then
        GmaticDKP_PrintError("Can't update roster since you're not in a guild.");
        return;
    end

    UDKP_GuildRoster = {};

    local guildName = GetGuildInfo("player");

    local num = 0;
    -- get count of all online/offline guild members
    for i = 1, GetNumGuildMembers(true), 1 do
        local gName, gRank, gRankIndex, gLevel, gClass, gNote, gOfficerNote = GetGuildRosterInfo(i);
        tinsert(UDKP_GuildRoster, 1, { ["name"] = gName, ["rank"] = gRank, ["rank_index"] = gRankIndex, ["level"] = gLevel, ["class"] = gClass, ["note"] = gOfficerNote });
        num = num + 1;
    end

    GmaticDKP_Print("Recorded " .. num .. " guild members.");
end

function GmaticDKP_Snapshot(args)
    local commands = {};

    string.gsub(args, "%S+",
        function(word) table.insert(commands, word) end);

    local cmd = commands[1];

    if (not cmd) then
        GmaticDKP_Print("Guildomatic DKP Snapshot Help");
        GmaticDKP_Print("/snapshot list [list all snapshots]");
        GmaticDKP_Print("/snapshot clear [deletes all snapshots]");
        GmaticDKP_Print("/snapshot remove <snapshot #> [remove snapshot entry]");
        GmaticDKP_Print("/snapshot boss <dkp> [snapshot raid members]");
        GmaticDKP_Print("/snapshot note <snapshot #> <item #> <note> [record dkp value for item]");
        GmaticDKP_Print("/snapshot loot <color> [minimum loot color to record: grey, white, green, blue, purple, orange, red]");
        GmaticDKP_Print("/snapshot ignore <item name> [do not record any loot with this name]");
	GmaticDKP_Print("/snapshot record player <item link> <dkp>");
        
        for k, v in pairs(UDKP_SnapshotColorMap) do
            if (v == UDKP_Config["LootMinColor"]) then
                GmaticDKP_Print("Currently capturing any " .. k .. " color loot and above.");
                break;
            end
        end
    elseif (cmd == "loot") then
        if (commands[2]) then
            local color = string.lower(commands[2]);
            if (UDKP_SnapshotColorMap[color]) then
                UDKP_Config["LootMinColor"] = UDKP_SnapshotColorMap[color];
                GmaticDKP_Print("Now capturing " .. color .. " loot and up.");
            else
                GmaticDKP_PrintError(color .. " is not valid. Please select from: [grey, white, green, blue, purple, orange, red].");
            end
        end
    elseif (cmd == "record") then
    	if (commands[2] and commands[3]) then
    		local iStart, iEnd, iName, iDKP, iLoot = string.find(args, "^record ([^%s]+)%s([%w]+)%s(.+)")
            if(iStart) then 
    	       	GmaticDKP_AddLoot(iLoot, iName, iDKP);
		GmaticDKP_Print(iLoot.." recorded to "..iName.." for "..iDKP.." DKP!")
    	       	return;
    	    end
    	    local iStart, iEnd, iName, iLoot = string.find(args, "^record ([^%s]+)%s(.+)")
    	    if(iStart) then
    	       	GmaticDKP_AddLoot(iLoot, iName, nil);
    	       	return;
    	    end
    	end
    	GmaticDKP_Print("Usage: /snapshot record player [dkp(optional)] <item link>");
    elseif (cmd == "note") then
        if (commands[2] and commands[3] and commands[4]) then
            local snum = tonumber(commands[2]);
            local inum = tonumber(commands[3]);
            if (snum and inum) then
                local snapshot = UDKP_Snapshots[snum];
                if (not snapshot) then
                    GmaticDKP_PrintError("Snapshot " .. snum .. " not found.");
                    return;
                end

                local loot = snapshot["loot"];
                local item = loot[inum];
                if (not item) then
                    GmaticDKP_PrintError("Item " .. inum .. " not found in snapshot " .. snum .. ".");
                    return;
                end

                item["note"] = commands[4];
                GmaticDKP_Print("Recorded " .. commands[4] .. " for " .. item["item"] .. ".");
		GmaticDKP_UpdateData();
                return;
            end
        end
        GmaticDKP_Print("Usage: /snapshot note <snapshot #> <item #> <note>");
    elseif (cmd == "gui") then 
	GmaticDKP_DisplayWindow()
    elseif (cmd == "list") then
	GmaticDKP_DisplayWindow()
    elseif (cmd == "remove") then
        if (commands[2]) then
            local snum = tonumber(commands[2]);
            if (snum and UDKP_Snapshots) then
                for k, v in pairs(UDKP_Snapshots) do
                    if (k == snum) then
                        tremove(UDKP_Snapshots, snum);
                        GmaticDKP_Print("Removed snapshot entry " .. snum .. ".");
			GmaticDKP_UpdateData();
                        return;
                    end
                end
                GmaticDKP_Print("Snapshot entry " .. snum .. " not found.");
            end
        else
            GmaticDKP_Print("Usage: /snapshot remove <snapshot #>");
        end
    elseif (cmd == "clear") then
        UDKP_Snapshots = { };
        GmaticDKP_Print("Snapshots cleared.");
	GmaticDKP_UpdateData();
    elseif (cmd == "ignore") then
        if (commands[2] and commands[2] == "remove") then
            if (commands[3]) then
                local _, _, item = string.find(args, "^ignore remove (.+)$");
                local found = 0;
                if (UDKP_IgnoredLoot) then
                    for k, v in pairs(UDKP_IgnoredLoot) do
                        if (strlower(v["item"]) == strlower(item)) then
                            tremove(UDKP_IgnoredLoot, k);
                            GmaticDKP_Print(item .. " removed from loot ignore list.")
                            found = 1;
                        end
                    end
                end
                if (found == 0) then
                    GmaticDKP_PrintError(item .. " not found in loot ignore list.")
                end
            else
                GmaticDKP_Print("Usage: /snapshot ignore remove <item>");
            end
        elseif (commands[2] and commands[2] == "list") then
            local num = 0;
            if (UDKP_IgnoredLoot) then
                GmaticDKP_Print("Ignored Items During Snapshots:");
                for k, v in pairs(UDKP_IgnoredLoot) do
                    GmaticDKP_Print(k .. ". " .. v["item"]);
                    num = num + 1;
                end
            end
            if (num == 0) then
                GmaticDKP_PrintError("No items in loot ignore list.");
            end
        elseif (commands[2] and commands[2] == "clear") then
            UDKP_IgnoredLoot = {};
            GmaticDKP_Print("The loot ignore list has been cleared.");
        elseif (commands[2]) then
            local _, _, item = string.find(args, "^ignore (.+)$");
            GmaticDKP_Print("Now ignoring " .. item .. " for loot capture.");
            tinsert(UDKP_IgnoredLoot, 1, { ["item"] = item });
        else
            GmaticDKP_Print("Usage: /snapshot ignore <item>");
            GmaticDKP_Print("Usage: /snapshot ignore remove <item>");
            GmaticDKP_Print("Usage: /snapshot ignore list");
            GmaticDKP_Print("Usage: /snapshot ignore clear");
        end
    else
        local _, _, name, dkp = string.find(args, "^(.+) (.+)$");
        if (not name or not dkp) then
            GmaticDKP_Print("Usage: /snapshot boss <dkp>");
        else
            GmaticDKP_TakeSnapshot(name, dkp);
        end
    end
end

function GmaticDKP_TakeSnapshot(name, dkp)
    if (GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0) then
        GmaticDKP_PrintError("Can't take snapshot. Not currently in a raid or a group.");
        return;
    end

    -- look up event by string matching first few characters
    local event = GmaticDKP_Capitalize(name);
    for k, v in pairs(UDKP_Events) do
        local iStart, iEnd = string.find(v["name"], "^" .. event);
        if (iStart) then
            event = v["name"];
            break;
        end
    end

    local players = { };

    if (GetNumRaidMembers() > 0) then
        numplayers = GetNumRaidMembers();
        for i = 1, numplayers, 1 do
            GmaticDKP_SnapshotRecordPlayer("raid" .. i, players);
        end
    else
        for i = 1, GetNumPartyMembers(), 1 do
            GmaticDKP_SnapshotRecordPlayer("party" .. i, players);
        end
        GmaticDKP_SnapshotRecordPlayer("player", players);
        numplayers = GetNumPartyMembers() + 1;
    end

    local zone = GetRealZoneText();
    local date = GmaticDKP_GetDateTime();
    local utc_time = time();

    if (not UDKP_Snapshots) then
        UDKP_Snapshots = { };
    end

    tinsert(UDKP_Snapshots, 1, { ["event"]=event, ["zone"]=zone, ["time"]=date, ["utc_time"]=utc_time, ["dkp"]=dkp, ["players"]=players, ["loot"] = {} });
    GmaticDKP_Print("Awarded " .. dkp .. " DKP for " .. event .. " to " .. numplayers .. " players.");
end

function GmaticDKP_SnapshotRecordPlayer (unitid, players)
    local player, online, class = UnitName(unitid), UnitIsConnected(unitid), UnitClass(unitid);

    -- record dkp adjustments for all players in raid that are online, if you're disconnected, you're SOL
    if (not online) then
        online = 0;
    end

    -- XXX dkp and event name and people online
    tinsert(players, { ["name"] = player });

    -- XXX not yet
    --GmaticDKP_RecordDKP(player, tonumber(dkp));
end

function GmaticDKP_CheckDKP(args)
    local commands = {};
    string.gsub(args, "%S+",
        function(word) table.insert(commands, word) end);

    if (commands[1] and commands[1] == "on") then
        GmaticDKP_Print("DKP lookups enabled.");
        UDKP_Config["DKP_Enabled"] = 1;
    elseif (commands[1] and commands[1] == "off") then
        GmaticDKP_Print("DKP lookups disabled.");
        UDKP_Config["DKP_Enabled"] = 0;
    else
        GmaticDKP_LookupDKP(select(1, args));
    end 
end

function GmaticDKP_LookupDKP(name, requestor)
    if (UDKP_Config["DKP_Enabled"] == 0 and requestor) then
        GmaticDKP_SendChatMessage(requestor, "Sorry, DKP lookups are currently disabled.");
        return;
    end

    name = string.lower(name);

    -- DKP time snapshot
    local msg = "DKP info last updated " .. UDKP_DKP_LastUpdate .. ".";
    if (requestor) then
        GmaticDKP_SendChatMessage(requestor, msg);
    else
        GmaticDKP_Print(msg);
    end

    local raid_players_cache = { };
    
    if (not name) then
        local msg = "Usage: dkp <player/class/all/boss/raid>";
        if (requestor) then
            GmaticDKP_SendChatMessage(requestor, msg);
        else
            GmaticDKP_Print(msg);
        end
        return;
    elseif (string.find(name, "^raid")) then
        if (GetNumRaidMembers() == 0) then
            GmaticDKP_PrintError("You're not currently in a raid.");
            return;
        else
            for i = 1, GetNumRaidMembers(), 1 do
                raid_players_cache[UnitName("raid"..i)] = 1;
            end
        end
    elseif (string.find(name, "^boss")) then
        local zone = GetRealZoneText();

        if (zone == "Onyxia's Lair" or zone == "Blackwing Lair" or zone == "Molten Core" or zone == "Naxxramas") then
            local msg = "DKP for " .. zone;
            if (requestor) then
                GmaticDKP_SendChatMessage(requestor, msg);
            else
                GmaticDKP_Print(msg);
            end

            for k, v in pairs(UDKP_Events) do
                if (v["zone"] == zone) then
                    msg = v["name"] .. " : " .. v["dkp"];
                    if (requestor) then
                        GmaticDKP_SendChatMessage(requestor, msg);
                    else
                        GmaticDKP_Print(msg);
                    end
                end
            end
        else
            for k, v in pairs(UDKP_Events) do
                if (strlen(v["zone"]) == 0) then
                    msg = v["name"] .. " : " .. v["dkp"];
                    if (requestor) then
                        GmaticDKP_SendChatMessage(requestor, msg);
                    else
                        GmaticDKP_Print(msg);
                    end
                end
            end
        end
        return;
    end

    table.sort(UDKP_Players, function(a, b) return tonumber(a["dkp"]) > tonumber(b["dkp"]) end);

    local found = 0;
    for k, player in pairs(UDKP_Players) do
        if (string.lower(player["class"]) == name or string.lower(player["name"]) == name or name == "all" or (name == "raid" and raid_players_cache[player["name"]] == 1)) then
            local msg = GmaticDKP_Capitalize(player["name"]) .. " : " .. player["dkp"];

            if (requestor) then
                GmaticDKP_SendChatMessage(requestor, msg);
            else
                GmaticDKP_Print(msg);
            end

            found = found + 1;

            -- only return top 10
            if (found == 10) then
                return;
            end
        end
    end

    -- nobody found
    if (found == 0) then
        local msg = "No such user or class: " .. name .. ".";
        if (requestor) then
            GmaticDKP_SendChatMessage(requestor, msg);
        else
            GmaticDKP_Print(msg);
        end
    end
end

function GmaticDKP_PrintAuctionMessage(msg)
    if (GetNumRaidMembers() > 0)  then
        SendChatMessage(msg, "RAID");
    elseif (GetNumPartyMembers() > 0) then
        SendChatMessage(msg, "PARTY");
    else
        SendChatMessage(msg, "SAY");
    end
end

function GmaticDKP_Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg, 1, 1, 0);
end

function GmaticDKP_PrintError(msg)
    DEFAULT_CHAT_FRAME:AddMessage(RED_FONT_COLOR_CODE .. "[ERROR] " .. msg .. NORMAL_FONT_COLOR_CODE, 1, 1, 0);
end

function GmaticDKP_SendChatMessage(to, msg)
    SendChatMessage("Guildomatic: " .. msg, "WHISPER", nil, to);
end

function GmaticDKP_DoAuction(args)
    local commands = {};
    string.gsub(args, "%S+",
        function(word) table.insert(commands, word) end);

    local cmd = commands[1];

    if (not cmd) then
        GmaticDKP_Print("Usage: /auction <item> [start an auction for the item].");
        GmaticDKP_Print("Usage: /auction stop [stop an auction].");
        GmaticDKP_Print("Usage: /auction list [list auctions].");
        GmaticDKP_Print("Usage: /auction clear [deletes all auctions].");
        GmaticDKP_Print("Usage: /auction remove <auction #> [remove an auction].");
        GmaticDKP_Print("Usage: /auction config <# of rounds> <round length in seconds> [configure auctions].");
        GmaticDKP_Print("Auctions are currently configured for ".. UDKP_Config["AuctionRounds"] .. " rounds of " .. UDKP_Config["AuctionRoundTime"] .. " seconds.")
    elseif (cmd == "config") then
        if (commands[2] and commands[3]) then
            local numRounds = tonumber(commands[2]);
            local roundLength = tonumber(commands[3]);
            if (numRounds and roundLength) then
                UDKP_Config["AuctionRounds"] = numRounds;
                UDKP_Config["AuctionRoundTime"] = roundLength;
                GmaticDKP_Print("Auctions are now configured for " .. UDKP_Config["AuctionRounds"] .. " rounds of " .. UDKP_Config["AuctionRoundTime"] .. " seconds.")
                return;
            end
        end
        GmaticDKP_Print("Usage: /auction config <# of rounds> <round length in seconds> [configure auctions].");
    elseif (cmd == "stop") then
        if (UDKP_Config["AuctionRunning"] == 1) then
            UDKP_Config["AuctionRunning"] = 0;
            auction = UDKP_Auctions[1];
            if (auction and auction["start"] >= 0) then
                auction["round"] = UDKP_Config["AuctionRounds"];
                auction["start"] = -1;
                GmaticDKP_PrintAuctionMessage("Auction cancelled.");
            end
            GmaticDKP_Print("Auction stopped.");
        else
            GmaticDKP_PrintError("No auction running.");
        end
    elseif (cmd == "remove") then
        if (commands[2]) then
            local snum = tonumber(commands[2]);
            if (snum) then
                for k, v in pairs(UDKP_Auctions) do
                    if (k == snum) then
                        tremove(UDKP_Auctions, snum);
                        GmaticDKP_Print("Removed auction entry " .. snum .. ".");
                        return;
                    end
                end
                GmaticDKP_Print("Auction entry " .. snum .. " not found.");
            end
        else
            GmaticDKP_Print("Usage: /auction remove <auction #>");
        end
    elseif (cmd == "list") then
        local num = 0;
        if (UDKP_Auctions) then
            for k, v in pairs(UDKP_Auctions) do
                local auction_time;
                if (v["utc_time"]) then
                    auction_time = date("%x %X", v["utc_time"]);
                else
                    auction_time = v["end"];
                end
                GmaticDKP_Print(k .. ". " .. auction_time .. " - " .. v["item"] .. " <" .. v["winner"] .. "/" .. v["highbid"] .. ">.");
                num = num + 1;
            end
        end
        if (num == 0) then
            GmaticDKP_PrintError("No auctions.");
        end
    elseif (cmd == "clear") then
        UDKP_Auctions = { };
        GmaticDKP_Print("All auctions deleted.");
    elseif (UDKP_Config["AuctionRunning"] == 1) then
        GmaticDKP_PrintError("There is an auction already running.");
    else
        local _, _, sItem = string.find(args, "^(.+)");

        GmaticDKP_PrintAuctionMessage("Auctioning " .. sItem .. ". " .. UDKP_Config["AuctionRounds"] .. " rounds of bidding. " .. UDKP_Config["AuctionRoundTime"] .. " seconds in each round.");
        GmaticDKP_PrintAuctionMessage("Whisper " .. UnitName("player") .. " to bid. Example: '/w " .. UnitName("player") .. " 100'.");
        GmaticDKP_PrintAuctionMessage("Now taking bids.");

        if (not UDKP_Auctions) then
            UDKP_Auctions = { };
        end

        -- create auction and provide extra 5 seconds for people to get started
        tinsert(UDKP_Auctions, 1, {
                        ["item"] = sItem,
                        ["start"] = GetTime() + 3,
                        ["end"] = "",
                        ["round"] = 0,
                        ["timer"] = 0,
                        ["highbid"] = 0,
                        ["numhighbids"] = 0,
                        ["winner"] = "none",
                        ["winners"] = "none",
                        ["bids"] = { }
        });

        UDKP_Config["AuctionRunning"] = 1;
    end
end

function GmaticDKP_Capitalize(name)
    if (not name) then
        return nil;
    end

    if (strlen(name) == 1) then
        return string.upper(name);
    end

    return string.upper(string.sub(name, 1, 1)) .. string.lower(string.sub(name, 2));
end

function GmaticDKP_UpdateAuctionWinner(auction, round)
    local highbid, numhighbids, name, winners = 0, 0, "", "";

    for k, bid in pairs(auction["bids"]) do
        if (bid["bid"] > highbid and bid["round"] <= round) then
            highbid = bid["bid"];
            name = bid["name"];
            numhighbids = 1;
            winners = name;
        elseif (bid["bid"] == highbid) then
            numhighbids = numhighbids + 1;
            winners = winners .. ", " .. bid["name"];
        end
    end

    auction["highbid"] = highbid;
    auction["numhighbids"] = numhighbids;
    auction["winner"] = name;
    auction["winners"] = winners;
end

function GmaticDKP_GetNumBidders(auction, round)
    local numBidders = 0;

    for k, bid in pairs(auction["bids"]) do
        if (bid["round"] == round) then
            numBidders = numBidders + 1;
        end
    end

    return numBidders;
end

function GmaticDKP_RecordDKP(name, dkp)
    for k, v in pairs(UDKP_Players) do
        if (v["name"] == name) then
            v["dkp"] = v["dkp"] + dkp;
        end
    end
end

-- this is only used for updating the auction
function GmaticDKP_OnUpdate(elapsed)
    UDKP_Elapsed = UDKP_Elapsed + elapsed;

    if (UDKP_Elapsed > 0.1) then
        if (UDKP_Config["AuctionRunning"] == 1) then
            auction = UDKP_Auctions[1];
            local item, start, round, highbid = auction["item"], auction["start"], auction["round"], auction["highbid"];
            if (auction["start"] >= 0 and round < UDKP_Config["AuctionRounds"]) then
                -- auction is now over, determine winner

                if (GetTime() > (start + (UDKP_Config["AuctionRounds"]*UDKP_Config["AuctionRoundTime"]))) then
                    -- if we only have 1 bidder in the last round, use the previous round's high bid
                    local lastWinner = auction["winner"];
                    GmaticDKP_UpdateAuctionWinner(auction, round);
                    if ((GmaticDKP_GetNumBidders(auction, round) == 1) and lastWinner == auction["winner"]) then
                        GmaticDKP_UpdateAuctionWinner(auction, round - 1);
                    end

                    -- end the auction
                    auction["round"] = UDKP_Config["AuctionRounds"];
                    auction["start"] = -1;

                    if (auction["highbid"] > 0) then
                        -- check if there was a tie
                        if (auction["numhighbids"] > 1) then
                            GmaticDKP_PrintAuctionMessage("Auction tied. " .. auction["numhighbids"] .. " bids for " .. auction["highbid"] .. " DKP from " .. auction["winners"] .. ".")
                        else
                            GmaticDKP_PrintAuctionMessage("Auction over for " .. item .. ". " .. auction["winner"] .. " wins for " .. auction["highbid"] .. " DKP.");
                        end
                    else
                        GmaticDKP_PrintAuctionMessage("Auction over for " .. item .. ". No bidders.");
                    end
                    auction["end"] = GmaticDKP_GetDateTime();
                    auction["utc_time"] = time();
                    UDKP_Config["AuctionRunning"] = 0;
                elseif (GetTime() > (start + (round+1)*UDKP_Config["AuctionRoundTime"])) then
                    local numBidders = GmaticDKP_GetNumBidders(auction, round);
                    if (numBidders > 1) then
                        GmaticDKP_UpdateAuctionWinner(auction, round);
                        GmaticDKP_PrintAuctionMessage("Auction round " .. round + 1 .. " over for " .. item .. ". " .. auction["numhighbids"] .. " high bid(s) of " .. auction["highbid"] .. ".");
                        auction["round"] = round + 1;
                        if (auction["round"] == (UDKP_Config["AuctionRounds"] - 1)) then
                            GmaticDKP_PrintAuctionMessage("Last round of bidding begins.");
                        else
                            GmaticDKP_PrintAuctionMessage("Next round of bidding begins.");
                        end
                    else
                        auction["start"] = 0;
                    end
                elseif (GetTime() > (start + UDKP_Config["AuctionRoundTime"]*(round+1) - 10)) then
                    local _, _, timer = string.find(start + UDKP_Config["AuctionRoundTime"]*(round+1) - GetTime() + 1, "^(%d+)");
                    if (auction["timer"] ~= timer) then
                        auction["timer"] = timer;
                        GmaticDKP_PrintAuctionMessage(timer .. " seconds left.");
                    end
                end
            end
        end
        
        -- check to see if we need to output our queue status to the channel
        if (UDKP_Queue and UDKP_Config["QueueFrequency"] and
              UDKP_Config["Queue_Enabled"] == 1 and
                GetTime() > (UDKP_LastQueuePrintTime + UDKP_Config["QueueFrequency"]*60))
        then

            -- make sure we have folks in the queue before we go to auto-print
            for k, v in pairs(UDKP_Queue) do
                GmaticDKP_QueuePrint("channel");
                break;
            end

            UDKP_LastQueuePrintTime = GetTime();
        end

        UDKP_Elapsed = UDKP_Elapsed - 0.1;
    end
end

function GmaticDKP_DoQueue(args)
    local commands = {};

    string.gsub(args, "%S+",
        function(word) table.insert(commands, word) end);

    if (not commands[1] or strlen(commands[1]) == 0) then
        GmaticDKP_Print("Guildomatic Queue Management Help");
        GmaticDKP_Print("Usage: /queue <on/off> [enables/disables the queue]");
        GmaticDKP_Print("Usage: /queue print <raid/officer/say/party/guild/channel> [prints queue to channel, specifying 'channel' will print to the configured channel]");
        GmaticDKP_Print("Usage: /queue add <name> <class> [add a player to queue]");
        GmaticDKP_Print("Usage: /queue remove <name> [remove a player from queue]");
        GmaticDKP_Print("Usage: /queue clear [clears the queue]");
        GmaticDKP_Print("Usage: /queue config <channel> <# of mins> [set the channel to output queue messages and how often to print queue status]");
        GmaticDKP_Print("Usage: /queue status [view queue status]");
    elseif (string.lower(commands[1]) == "on") then
        UDKP_Config["Queue_Enabled"] = 1;
        GmaticDKP_Print("Queue is now enabled.");
    elseif (string.lower(commands[1]) == "off") then
        UDKP_Config["Queue_Enabled"] = 0;
        GmaticDKP_Print("Queue is now disabled.");
    elseif (string.lower(commands[1]) == "config") then
        if (commands[2] and commands[3]) then
            local freq = tonumber(commands[3]);
            if (freq) then
                UDKP_Config["QueueFrequency"] = freq;
                UDKP_Config["QueueChannel"] = commands[2];
                GmaticDKP_Print("Queue will now print to the '" .. UDKP_Config["QueueChannel"] .. "' channel every " .. UDKP_Config["QueueFrequency"] .. " minutes.");
                return;
            end
        end
        GmaticDKP_Print("Usage: /queue config <channel> <# of mins> [ex. /queue config MyQueueChannel 5, this would output queue status/information to 'MyQueueChannel' every 5 minutes].");
    elseif (string.lower(commands[1]) == "print") then
        GmaticDKP_QueuePrint(commands[2]);
    elseif (string.lower(commands[1]) == "help") then
        GmaticDKP_Print("Guildomatic Queue Management Help");
    elseif (string.lower(commands[1]) == "remove") then
        GmaticDKP_QueueRemove(commands[2]);
    elseif (string.lower(commands[1]) == "clear") then
        GmaticDKP_QueueRemove("all");
    elseif (string.lower(commands[1]) == "add") then
        local class = commands[3];
        local player = GmaticDKP_Capitalize(commands[2]);
        if (not player or strlen(player) ==0) then
            GmaticDKP_Print("Usage: /queue add <player> <class>[add a player to queue]");
            return;
        end

        for k, v in pairs(UDKP_Players) do
            if (v["name"] == player) then
                class = v["class"];
                break;
            end
        end

        if (not class) then
            GmaticDKP_PrintError("I have no idea who that is. You'll need to specify the class in your command: /queue add <name> <class>.");
        else 
            GmaticDKP_QueueAdd(player, class);
        end
    end
end

function GmaticDKP_QueueRemove(player)
    if (not player or strlen(player) == 0) then
        GmaticDKP_Print("Usage: /queue remove <player> [removes a player from queue]");
        return -1;
    end

    player = GmaticDKP_Capitalize(player);

    if (player == "All") then
        UDKP_Queue = {};
        GmaticDKP_Print("Queue has been cleared.", 1, 0.2, 0.2);
        return 0;
    end

    for k, v in pairs(UDKP_Queue) do
        if (v["name"] == player) then
            table.remove(UDKP_Queue, k);
            GmaticDKP_Print(player .. " has been removed from the queue.");
            return 0;
        end
    end

    GmaticDKP_PrintError("No such player in queue: " .. player .. ".");
    return -1;
end

function GmaticDKP_QueueHelp(args)
end

function GmaticDKP_PrintToQueueChannel(channel, requestor, msg)
    if (not channel) then
        channel = "";
    else
        channel = string.upper(channel);
    end

    if (channel == "PARTY" or channel == "OFFICER" or channel == "SAY" or channel == "RAID" or channel == "GUILD") then
        SendChatMessage(msg, channel, UDKP_DefaultLanguage);
    elseif (channel == "CHANNEL" and UDKP_Config["QueueChannel"]) then
        SendChatMessage(msg, channel, UDKP_DefaultLanguage, GetChannelName(UDKP_Config["QueueChannel"]));
    elseif (channel == "WHISPER") then
        GmaticDKP_SendChatMessage(requestor, msg);
    else
        GmaticDKP_Print(msg);
    end
end

function GmaticDKP_QueuePrint(channel, requestor)   
    GmaticDKP_PrintToQueueChannel(channel, requestor, "Queue status");

    local numresults = 0;
    if (UDKP_Queue) then
        table.sort(UDKP_Queue, function(a, b) return a["time"] < b["time"] end);
        for k, class in pairs(UDKP_Classes) do
            local list = "";
            for k, player in pairs(UDKP_Queue) do
                local pclass = player["class"];
                if (player["class"] == class) then
                    if (not player["alt"]) then
                        list = list .. " " .. player["name"];
                    else
                        list = list .. " " .. player["name"] .. "(" .. player["alt"] .. ")";
                    end
                end
            end
            if (strlen(list) > 0) then
                GmaticDKP_PrintToQueueChannel(channel, requestor, class .. ":" .. list);
                numresults = numresults + 1;
            end
        end
    end

    if (numresults == 0) then
        GmaticDKP_PrintToQueueChannel(channel, requestor, "Empty queue.");
    end

    GmaticDKP_PrintToQueueChannel(channel, requestor, "Whisper " .. UnitName("player") .. " 'q join' to join the queue. 'q leave' to leave the queue. 'q status' for the current queue.");
end

function GmaticDKP_QueueAdd(player, class, alt)
    player = GmaticDKP_Capitalize(player);
    class = GmaticDKP_Capitalize(class);
    alt = GmaticDKP_Capitalize(alt);

    if (not UDKP_Queue) then
        UDKP_Queue = { };
    end

    for k, v in pairs(UDKP_Queue) do
        if (v["name"] == player) then
            return -1;
        end
    end

    for k, v in pairs(UDKP_Classes) do
        if (v == class) then
            local time = time();
            tinsert(UDKP_Queue, { ["name"]=player, ["class"]=v, ["time"]=time, ["alt"]=alt });
            GmaticDKP_Print(player .. " joins " .. v .. " queue.");
            return 0;
        end
    end
    return -2;
end

function GmaticDKP_AcceptBid(bidder, bid)
    if (not bid) then
        GmaticDKP_SendChatMessage(bidder, "Bid must be submitted as '<bid amount>', example: /w " .. UnitName("player") .. " 100");
        return;
    end

    local auction = UDKP_Auctions[1];

    --local requestor_dkp = 0;
    --for k, v in pairs(UDKP_Players) do
        --if (v["name"] == bidder) then
            --requestor_dkp = tonumber(v["dkp"]);
        --end
    --end

    -- reject their bid if they have no DKP
    --if (requestor_dkp == 0) then
        --GmaticDKP_SendChatMessage(bidder, "You have no DKP to bid.");
        --return;
    --end

    -- make sure we're having an auction
    if (not auction or (auction and auction["start"] == -1)) then
        GmaticDKP_SendChatMessage(bidder, "No auction currently.");
    -- make sure it's a valid bid
    --elseif (not bid or bid > requestor_dkp) then
        --GmaticDKP_SendChatMessage(bidder, "Illegal bid. Bid must be a number less than your current DKP amount");
    -- it's a valid bid, let's do further checks
    else
        -- check and make sure they were in previous rounds and bidding higher
        local acceptbid = 0;
        for k, bids in pairs(auction["bids"]) do
            -- make sure they were in previous round and bidding higher
            if (bids["name"] == bidder and bids["round"] == (auction["round"] - 1)) then
                if (bid <= auction["highbid"]) then
                    GmaticDKP_SendChatMessage(bidder, "You must bid higher than previous round's high bid of " .. auction["highbid"] .. ".");
                    return;
                end
                acceptbid = 1;
            -- maybe we're just updating their current round bid
            elseif (bids["name"] == bidder and bids["round"] == auction["round"]) then
                bids["bid"] = bid;
                GmaticDKP_Print('Bid updated to ' .. bid .. ' from ' .. bidder .. '.');
                GmaticDKP_SendChatMessage(bidder, "Bid of " .. bid .. " accepted.");
                return;
            end
        end

        if (acceptbid == 1 or auction["round"] == 0) then
            GmaticDKP_Print('Bid of ' .. bid .. ' from ' .. bidder .. '.');
            GmaticDKP_SendChatMessage(bidder, "Bid of " .. bid .. " accepted.");
            tinsert(auction["bids"], { ["name"] = bidder, ["bid"] = bid, ["round"] = auction["round"] });
        else
            GmaticDKP_SendChatMessage(bidder, "Bid not accepted. You were not a bidder in the previous round.");
        end
    end
end

function GmaticDKP_OnEvent(event)
    if (event == "RAID_ROSTER_UPDATE") then
        -- if we're in raid and we have a queue going, make sure we remove
        -- players from queue that end up joining the raid
        if (GetNumRaidMembers() > 0 and UDKP_Queue) then
            for k, v in pairs(UDKP_Queue) do
                for i = 1, GetNumRaidMembers(), 1 do
                    local player = UnitName("raid" .. i);
                    if (player and v["name"] == player) then
                        GmaticDKP_QueueRemove(player);
                    end
                end
            end
        end
    elseif (event == "PARTY_MEMBERS_CHANGED" and UDKP_ConvertToRaidOnJoin == true) then
        if (GetNumRaidMembers() == 0 and GetNumPartyMembers() > 0) then
            ConvertToRaid();
            UDKP_ConvertToRaidOnJoin = false;
        end
    elseif (event == "ADDON_LOADED") then
        -- request a guild roster update
        if IsInGuild() and GetNumGuildMembers() == 0 then
            GuildRoster()
        end
    
        -- start up our config object
        if (not UDKP_Config) then
            UDKP_Config = {
                ["Queue_Enabled"] = 0,
                ["DKP_Enabled"] = 0,
                ["AuctionRunning"] = 0,
                ["LootMinColor"] = 4,
                ["AuctionRounds"] = 3,
                ["AuctionRoundTime"] = 25
            };
        end
    
        if (not UDKP_Config["AuctionRounds"]) then
            UDKP_Config["AuctionRounds"]  = 3;
            UDKP_Config["AuctionRoundTime"]  = 25;
            GmaticDKP_Print("Default number of auction rounds set to " .. UDKP_Config["AuctionRounds"] .. " rounds of " .. UDKP_Config["AuctionRoundTime"] .. " seconds. Use '/auction config' to change the settings.");
        end
    
        if (not UDKP_Config["LootMinColor"]) then
            tinsert(UDKP_Config, { ["LootMinColor"] = 4 });
            GmaticDKP_Print("Default minimum loot color for capture is purple. Use '/snapshot loot' to change the setting.");
        end

        if (not UDKP_IgnoredLoot) then
            GmaticDKP_Print("Creating initial ignore loot list.")
            UDKP_IgnoredLoot = {};
        end
    elseif (event == "COMBAT_LOG_EVENT_UNFILTERED") then
    	local event_type  = arg2;
    	
    	-- check for boss death
    	if (event_type == "UNIT_DIED") then
    	    local killed = arg7;
    	    for k, v in pairs(UDKP_Events) do
                if (killed == v["name"]) then
                    GmaticDKP_TakeSnapshot(v["name"], v["dkp"]);
                    break;
                end
            end
    	end
    elseif (event == "PLAYER_ENTERING_WORLD") then
        -- check to see if they're entering an instance
        local posX, posY = GetPlayerMapPosition("player");
        if (posX == 0 and posY == 0 and UDKP_Snapshots) then
            GmaticDKP_Print("REMINDER: If you're entering an instance, don't forget to clear your old snapshots.");
        end
    end
end

function GmaticDKP_OnWhisperInform (msg)
    local iStart, _ = string.find(msg, "^Guildomatic:");
    if (iStart) then
        return true;
    end
end

function GmaticDKP_OnWhisper (msg)
    local commands = {};

    string.gsub(msg, "%S+",
        function(word) table.insert(commands, word) end);

    local cmd, requestor = commands[1], arg2;

    if (not cmd or strlen(cmd) == 0) then
        cmd = arg1;
    end

    if (string.lower(cmd) == "dkp") then
        local _, _, params = string.find(msg, "[^%s]+ ?(.*)");
        GmaticDKP_LookupDKP(params, requestor);
        return true;
    elseif (string.lower(cmd) == "snapshot") then
        local num = 0;
        if (UDKP_Snapshots) then
            for k, v in pairs(UDKP_Snapshots) do
                local snapshot_time;
                if (v["utc_time"]) then
                    snapshot_time = date("%x %X", v["utc_time"]);
                else
                    snapshot_time = v["time"];
                end
                
                GmaticDKP_SendChatMessage(requestor, k .. ". " .. v["event"] .. " - " .. snapshot_time);
                if (v["loot"]) then
                    for l, w in pairs(v["loot"]) do
                        GmaticDKP_SendChatMessage(requestor, "  " .. l .. ". " .. w["player"] .. " - " .. w["item"] .. " - " .. w["note"] .. " DKP");
                    end
                end
                num = num + 1;
            end
        end
        if (num == 0) then
            GmaticDKP_SendChatMessage(requestor, "No snapshots.");
        end
    elseif (string.lower(cmd) == "q") then
        if (UDKP_Config["Queue_Enabled"] == 0) then
            GmaticDKP_SendChatMessage(requestor, "Queue is currently disabled. Maybe someone else is running the queue.");
        elseif (commands[2] == "join") then
            local class = commands[3];
            if (not class) then
                for k, v in pairs(UDKP_Players) do
                    if (v["name"] == requestor) then
                        class = v["class"];
                        break;
                    end
                end
            end

            if (not class) then
                GmaticDKP_SendChatMessage(requestor, "I don't know what class you are yet. Please specify your class when joining queue, ie. /w " .. UnitName("player") .. " q join <class>");
            else
                local result = GmaticDKP_QueueAdd(requestor, class);
                if (result == -1) then
                    GmaticDKP_SendChatMessage(requestor, "You're already in the queue.");
                elseif (result == -2) then
                    GmaticDKP_SendChatMessage(requestor, class .. " is not a recognized class, ie. Paladin, Warrior, etc.");
                elseif (result == 0) then
                    GmaticDKP_SendChatMessage(requestor, "You're now in the " .. class .. " queue.");
                end
            end
        elseif (commands[2] == "leave") then
            local result = GmaticDKP_QueueRemove(requestor);
            if (result == -1) then
                GmaticDKP_SendChatMessage(requestor, "You're not in the queue.");
            elseif (result == 0) then
                GmaticDKP_SendChatMessage(requestor, "You've been removed from the queue.");
            end
        elseif (commands[2] == "status") then
            GmaticDKP_QueuePrint("whisper", requestor);
        end
        return true;
    elseif (UDKP_Config["AuctionRunning"] == 1 and string.lower(cmd) == "bid") then
        GmaticDKP_AcceptBid(requestor, tonumber(commands[2]));
        return true;
    elseif (UDKP_Config["AuctionRunning"] == 1 and tonumber(cmd) and not commands[2]) then
        GmaticDKP_AcceptBid(requestor, tonumber(cmd));
        return true;
    end
end

function GmaticDKP_OnChannelJoin (msg)
    if (UDKP_Config["QueueChannel"] == nil) then
	UDKP_Config["QueueChannel"] = ""
    end
    if (arg9 and arg2 and UDKP_Config["Queue_Enabled"] == 1 and string.lower(arg9) == string.lower(UDKP_Config["QueueChannel"])) then
        local player = arg2;
        local channel = arg9;
        local found = 0;

        -- check the raid
        local raiders = GetNumRaidMembers();
        if (raiders > 0) then
            for i = 1, raiders, 1 do
                if (player == UnitName("raid" .. i)) then
                    found = 1;
                    break;
                end
            end
        end

        -- check the queue
        if (found == 0) then
            for k, v in pairs(UDKP_Queue) do
                if (v["name"] == player) then
                    found = 1;
                    break;
                end
            end
        end

        -- check and make sure we haven't whispered them in awhile
        if (found == 0) then
            for k, v in pairs(UDKP_QueueWhispers) do
                if (v["name"] == player) then
                    if (GetTime() < v["time"] + 60) then
                        found = 1;
                    else
                        tremove(UDKP_QueueWhispers, k);
                    end
                    break;
                end
            end
        end

        -- we're safe to send them a queue whisper
        if (found == 0) then
            GmaticDKP_Print("Sending queue whisper to " .. player);
            GmaticDKP_SendChatMessage(player, "Whisper me for queue, ie. q join, q status, q leave, q status.");
            tinsert(UDKP_QueueWhispers, {["name"] = player, ["time"] = GetTime()});
            return;
        end
    end
end

function GmaticDKP_AddLoot(itemid, playern, UDKP_Note)
        local _, _, sColor = string.find(itemid, "|c(%x+)|Hitem:")
        if (sColor and (UDKP_LootColorMap[sColor] >= UDKP_Config["LootMinColor"])) then

            if (not UDKP_Snapshots or not UDKP_Snapshots[1]) then
                GmaticDKP_Print("You need to create a snapshot before any loot can be captured. Type '/snapshot' for more information.");
            else
                local ignore_loot = nil;
                -- check to make sure the loot shouldn't be ignored
                if (UDKP_IgnoredLoot) then
                    for k, v in pairs(UDKP_IgnoredLoot) do
                        local lStart, _, match = string.find(strlower(itemid), strlower(v["item"]));
                        if (lStart) then
                            ignore_loot = 1;
                            break;
                        end
                    end
                end
            
                -- record the loot as long as it's not to be ignored
                if (not ignore_loot) then
                    local snapshot = UDKP_Snapshots[1];
                    local loot = snapshot["loot"];
                    if (not loot) then
                        tinsert(snapshot, { ["loot"] = {} });
                        loot = snapshot["loot"];
                    end

                    local date = GmaticDKP_GetDateTime();
                    local utc_time = time();
                    local note;
                    if (UDKP_Note) then
                        note = UDKP_Note;
                    else
                        note = "-";
                    end
                    tinsert(loot, { ["player"] = playern, ["item"] = itemid, ["time"] = date, ["utc_time"] = utc_time, ["note"] = note });
                end
            end
        end
	GmaticDKP_UpdateData();
end

function GmaticDKP_RecordLoot(msg)
    local iStart, _, sPlayer, sItem = string.find(msg, "([^%s]+) receive[s]? loot: (.+)%.");
    if (iStart) then
        local _, _, sColor = string.find(sItem, "|c(%x+)|Hitem:")
        if (sColor and (UDKP_LootColorMap[sColor] >= UDKP_Config["LootMinColor"])) then
            if (sPlayer == "You") then
                sPlayer = UnitName("player");
            end

            if (not UDKP_Snapshots or not UDKP_Snapshots[1]) then
                GmaticDKP_PrintError("You need to create a snapshot before any loot can be captured. Type '/snapshot' for more information.");
            else
                local ignore_loot = nil;
                -- check to make sure the loot shouldn't be ignored
                if (UDKP_IgnoredLoot) then
                    for k, v in pairs(UDKP_IgnoredLoot) do
                        local lStart, _, match = string.find(strlower(sItem), strlower(v["item"]));
                        if (lStart) then
                            ignore_loot = 1;
                            break;
                        end
                    end
                end
            
                -- record the loot as long as it's not to be ignored
                if (not ignore_loot) then
                    local snapshot = UDKP_Snapshots[1];
                    local loot = snapshot["loot"];
                    if (not loot) then
                        tinsert(snapshot, { ["loot"] = {} });
                        loot = snapshot["loot"];
                    end

                    local date = GmaticDKP_GetDateTime();
                    local utc_time = time();
                    tinsert(loot, { ["player"] = sPlayer, ["item"] = sItem, ["time"] = date, ["utc_time"] = utc_time, ["note"] = "-" });
                end
            end
        end
    end
    GmaticDKP_UpdateData();
end

function GmaticDKP_GetDateTime()
    local t = date("*t");
    local hours, mins = GetGameTime();

    return GmaticDKP_FixZero(t.month) .. "/" .. GmaticDKP_FixZero(t.day) .. "/" .. strsub(t.year, 3) .. " " .. GmaticDKP_FixZero(hours) .. ":" .. GmaticDKP_FixZero(mins) .. ":" .. GmaticDKP_FixZero(t.sec);
end

function GmaticDKP_FixZero(num)
    if ( num < 10 ) then
        return "0" .. num;
    else
        return num;
    end
end

function GmaticDKP_OnLoad()
    SLASH_DKP1 = "/dkp";

    SLASH_SNAPSHOT1 = "/snapshot";
    SLASH_AUCTION1 = "/auction";
    SLASH_GAUCTION1 = "/gauction";

    SLASH_QUEUE1 = "/queue";

    SLASH_UDKPHELP1 = "/gmatic";

    SLASH_ROSTER1 = "/roster";

    ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", GmaticDKP_RecordLoot)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_JOIN", GmaticDKP_OnChannelJoin)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", GmaticDKP_OnWhisper)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", GmaticDKP_OnWhisperInform)
    
    SlashCmdList["DKP"] = GmaticDKP_CheckDKP;
    SlashCmdList["SNAPSHOT"] = GmaticDKP_Snapshot;
    SlashCmdList["AUCTION"] = GmaticDKP_DoAuction;
    SlashCmdList["QUEUE"] = GmaticDKP_DoQueue;
    SlashCmdList["UDKPHELP"] = GmaticDKP_UDKPHelp;
    SlashCmdList["GAUCTION"] = GmaticDKP_DoAuction;
    SlashCmdList["ROSTER"] = GmaticDKP_Roster;

    this:RegisterEvent("RAID_ROSTER_UPDATE");
    this:RegisterEvent("PARTY_MEMBERS_CHANGED");
    
    this:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    this:RegisterEvent("ADDON_LOADED");
    this:RegisterEvent("PLAYER_ENTERING_WORLD");
    
UDKP_frame = CreateResizableWindow("GmaticDKPGUI", "GuildomaticDKP GUI", 500, 200, OnResize)
UDKP_frame:SetMinResize(530,200)
UDKP_frame:SetUserPlaced(true)

if not UDKP_st then
	UDKP_st = ScrollingTable:CreateST(columnHeads,80,nil,nil,UDKP_frame);
	UDKP_st.b_frame:SetPoint("BOTTOMLEFT",8,8)
	UDKP_st.b_frame:SetPoint("TOP", UDKP_frame, 0, -60)
	UDKP_st.b_frame:SetPoint("RIGHT", UDKP_frame, -8,0)
	UDKP_st.LibraryRefresh = UDKP_st.Refresh
	UDKP_st:RegisterEvents({ -- register for table events
		-- when double clicked on, 'dblclick' funtion will be executed with forwarded parameters
		["OnDoubleClick"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, button, ...) -- what to do on double click
				local cellData = data[realrow].cols[column]
				if cellData.dblclick then
					cellData.dblclick(button, data, cols, row, realrow, column )
				else
					if cols[column].dblclick then
						cols[column].dblclick(button, data, cols, row, realrow, column )
					end
				end
			end, 
			-- when hover over the cell, execute 'onhover' funtion from table and on hover out execute it once more, used to display
			-- tooltips of an item when hovered over the tab
		["OnEnter"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, button, ...)
			local cellData = data[realrow].cols[column]
			if cellData.onhover then
				cellData.onhover(button, unpack(cellData.onhoverargs or {}))
			else
				if cols[column].onhover then
					cols[column].onhover(button, unpack(cellData.onhoverargs or cols[column].onhoverargs or {}))
				end
			end
		end,
		["OnLeave"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, button, ...)
			local cellData = data[realrow].cols[column]
			if cellData.onhover then
				cellData.onhover(button, unpack(cellData.onhoverargs or {}))
			else
				if cols[column].onhover then
					cols[column].onhover(button, unpack(cellData.onhoverargs or cols[column].onhoverargs or {}))
				end
			end
		end,
		});
	end
	--UDKP_frame:Show()

    GmaticDKP_Print("Loaded Guildomatic DKP Module... Type '/gmatic' for help");
end

function GmaticDKP_UpdateData ()
        local num = 0;
        local row = 1
	UDKP_data = { }
       if (UDKP_Snapshots) then

            for k, v in pairs(UDKP_Snapshots) do
                if (v["loot"]) then
                    for l, w in pairs(v["loot"]) do
                        if not UDKP_data[row] then
							UDKP_data[row] = {};
						end
                    	UDKP_data[row].cols = {
							{value=k},
							{value=l}, -- lp
							{value=v["event"]},
							{value=w["item"],onhoverargs={w["item"]}},
							{value=w["player"]},
							{value=w["note"]}
						}
                        row = row + 1
                    end
                end
                num = num + 1;
            end
	end
	UDKP_st:SetData(UDKP_data)
end

function GmaticDKP_DisplayWindow ()
	GmaticDKP_UpdateData();
	UDKP_frame:Show();
end