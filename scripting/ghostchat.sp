#include <sourcemod>
#include <morecolors>
#include <basecomm>
#include <sdktools>

public Plugin:myinfo = 
{
    name = "Ghost Chat",
    author = "Riotline",
    description = "Adds a new chat option for players who are currently dead to speak to those who are alive. This disables alive players from seeing the normal dead chat. Useful for gamemodes like TF2Jail where giving things away may occur.",
    version = "3.0",
    url = ""
}

new Handle:adminColour_cvar = INVALID_HANDLE;
new Handle:mvpColour_cvar = INVALID_HANDLE;
new Handle:vipColour_cvar = INVALID_HANDLE;
new Handle:defaultColour_cvar = INVALID_HANDLE;
new Handle:adminFlag_cvar = INVALID_HANDLE;
new Handle:mvpFlag_cvar = INVALID_HANDLE;
new Handle:vipFlag_cvar = INVALID_HANDLE;
new Handle:tfgravetalk = INVALID_HANDLE;


public OnPluginStart()
{
    RegConsoleCmd("sm_ghost", Ghost);
    RegConsoleCmd("sm_g", Ghost);
    tfgravetalk = FindConVar("tf_gravetalk");
    SetConVarFloat(tfgravetalk, 0.0, true, false); // Disables ConVar 'tfgravetalk'. TFGraveTalk allows/disallows those alive to see the *dead* chat.
    adminColour_cvar = CreateConVar("gc_admincolour", "lightgreen", "Change the *GHOST* Colour for admins with the ADMIN_SLAY Flag. See https://www.doctormckay.com/morecolors.php for Colours");
    adminFlag_cvar = CreateConVar("gc_adminflag", "", "Change which flags can access Admin *GHOST* Colour. See https://wiki.alliedmods.net/Adding_Admins_(SourceMod)#Levels for FLAGS");
    mvpColour_cvar = CreateConVar("gc_vip2colour", "hotpink", "Change the *GHOST* Colour for anyone with the gc_vip2flag Flag. See https://www.doctormckay.com/morecolors.php for Colours");
    mvpFlag_cvar = CreateConVar("gc_vip2flag", "", "Change which flags can access the VIP 2 *GHOST* Colour. See https://wiki.alliedmods.net/Adding_Admins_(SourceMod)#Levels for FLAGS");
    vipColour_cvar = CreateConVar("gc_vipcolour", "lightgreen", "Change the *GHOST* Colour for anyone with the gc_vipflag Flag. See https://www.doctormckay.com/morecolors.php for Colours");
    vipFlag_cvar = CreateConVar("gc_vipflag", "", "Change which flags can access the VIP *GHOST* Colour. See https://wiki.alliedmods.net/Adding_Admins_(SourceMod)#Levels for FLAGS");
    defaultColour_cvar = CreateConVar("gc_defaultcolour", "default", "Change the *GHOST* Colour for anyone without a flag. See https://www.doctormckay.com/morecolors.php for Colours");
    AutoExecConfig(true, "ghostchat");
    LoadTranslations("ghostc.phrases.txt")
}

public Action Ghost(int client, int args)
{
	char nameColour[8];
	char ghostColour[12];
	char ghostMessage[256];
	GetCmdArgString(ghostMessage, sizeof(ghostMessage));

	char adminFlag[32];
	char mvpFlag[32];
	char vipFlag[32];

	GetConVarString(adminFlag_cvar, adminFlag, sizeof(adminFlag));
	GetConVarString(mvpFlag_cvar, mvpFlag, sizeof(mvpFlag));
	GetConVarString(vipFlag_cvar, vipFlag, sizeof(vipFlag));

	char clientName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, sizeof(clientName));
	
	if ( args < 1 ) {
		CPrintToChat(client, "%t Usage: sm_ghost <message>", "prefix");
		return Plugin_Handled;
	}
	
	if ( BaseComm_IsClientGagged(client) ) {
        CPrintToChat(client, "%t You are gagged!", "prefix");
        return Plugin_Handled;
    }

	if ( IsPlayerAlive(client) ) {
		CPrintToChat(client, "%t You can't use Ghost Chat when you are alive!", "prefix");
		return Plugin_Handled;
	}
	

	if ( CheckAdminFlagsByString(client, adminFlag)) {
		GetConVarString(adminColour_cvar, ghostColour, sizeof(ghostColour));
	} else if ( CheckAdminFlagsByString(client, mvpFlag)) {
		GetConVarString(mvpColour_cvar, ghostColour, sizeof(ghostColour));
	} else if ( CheckAdminFlagsByString(client, vipFlag)) {
		GetConVarString(vipColour_cvar, ghostColour, sizeof(ghostColour));
	} else {
		GetConVarString(defaultColour_cvar, ghostColour, sizeof(ghostColour));
	}
	
	if ( GetClientTeam(client) == 2 )
	{
		nameColour = "red";
	} else if ( GetClientTeam(client) == 3 ) {
		nameColour = "blue";
	}
	else
	{
		CPrintToChat(client, "%t Error: must be on a team before using sm_ghost", "prefix");
		return Plugin_Handled;
	}

	CPrintToChatAll("{%s}*GHOST* {%s}%s {default}: %s", ghostColour, nameColour, clientName, ghostMessage);
	return Plugin_Handled;
}

stock bool:CheckAdminFlagsByString(client, const String:flagString[])
{
    new AdminId:admin = GetUserAdmin(client);
    if (admin != INVALID_ADMIN_ID) {
        new count, found, flags = ReadFlagString(flagString);
        for (new i = 0; i <= 20; i++) {
            if (flags & (1<<i)) {
                count++;

                if (GetAdminFlag(admin, AdminFlag:i)) {
                    found++;
                }
            }
        }

        if (count == found) {
            return true;
        }
    }

    return false;
}  