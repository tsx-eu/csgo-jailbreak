#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <smart-menu>

#pragma newdecls required

#include <jb_lastrequest>

int g_iEnabledBunny, g_iAutoBunny;

public void JB_OnPluginReady() {
	JB_CreateLastRequest("Combat de cut-bunny", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON, DV_CAN_Always, DV_Start, DV_Stop);
}
public void DV_Start(int client, int target) {
	g_iEnabledBunny = GetConVarInt(FindConVar("sv_enablebunnyhopping"));
	g_iAutoBunny = GetConVarInt(FindConVar("sv_autobunnyhopping"));
	ServerCommand("sv_enablebunnyhopping 1;sv_autobunnyhopping 1");	
	
	SmartMenu menu = new SmartMenu(selectWeapon);
	menu.SetTitle("Combien de HP?\n");
	menu.SetCell("target", target);

	menu.AddItem("1", 	"1");
	menu.AddItem("35", 	"35");
	menu.AddItem("50", 	"50");
	menu.AddItem("75", 	"75");
	menu.AddItem("100", "100");
	menu.AddItem("200", "200");
	
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}
public int selectWeapon(SmartMenu menu, MenuAction action, int client, int params) {
	static char options[64];
	if( action == MenuAction_Select ) {
		menu.GetItem(params, options, sizeof(options));
		int target = menu.GetCell("target");
		int hp = StringToInt(options);
		
		SetEntityHealth(client, hp);
		SetEntityHealth(target, hp);
		
		DV_StripWeapon(client);
		DV_StripWeapon(target);
		
		GivePlayerItem(client, "weapon_knife");
		GivePlayerItem(target, "weapon_knife");
		
		Entity_SetCollisionGroup(client, COLLISION_GROUP_DEBRIS_TRIGGER);
		Entity_SetCollisionGroup(target, COLLISION_GROUP_DEBRIS_TRIGGER);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return;
}
public void DV_Stop(int client, int target) {
	ServerCommand("sv_enablebunnyhopping %d;sv_autobunnyhopping %d", g_iEnabledBunny, g_iAutoBunny);
	
	if( client )
		Entity_SetCollisionGroup(client, COLLISION_GROUP_PLAYER);
	if( target )
		Entity_SetCollisionGroup(target, COLLISION_GROUP_PLAYER);
	
}
