#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <smart-menu>

#pragma newdecls required

#include <jb_lastrequest>

int g_iAirAccelerate, g_iGravity, g_iEnabledBunny, g_iAutoBunny;
float g_flStart[3];

public void JB_OnPluginReady() {
	JB_CreateLastRequest("Combat de cut", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON, DV_CAN_Always, DV_Start);
}
public void DV_Start(int client, int target) {
	SmartMenu menu = new SmartMenu(selectStyle);
	menu.SetTitle("Quel style de combat de cut?\n");
	menu.SetCell("target", target);

	menu.AddItem("normal", 	"Normal");
	menu.AddItem("bunny", 	"Bunny");
	menu.AddItem("lowgrav",	"Lowgrav");
	menu.AddItem("slide",	"Slide");
	
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}
public int selectStyle(SmartMenu menu, MenuAction action, int client, int params) {
	static char options[64];
	if( action == MenuAction_Select ) {
		menu.GetItem(params, options, sizeof(options));
		int target = menu.GetCell("target");
		
		g_iEnabledBunny = GetConVarInt(FindConVar("sv_enablebunnyhopping"));
		g_iAutoBunny = GetConVarInt(FindConVar("sv_autobunnyhopping"));
		g_iAirAccelerate = GetConVarInt(FindConVar("sv_airaccelerate"));
		g_iGravity = GetConVarInt(FindConVar("sv_gravity"));
		
		if( StrEqual(options, "bunny") )
			ServerCommand("sv_enablebunnyhopping 1;sv_autobunnyhopping 1");	
		if( StrEqual(options, "lowgrav") )
			ServerCommand("sv_airaccelerate 1000;sv_gravity 200");
		if( StrEqual(options, "slide") )
			ServerCommand("sv_airaccelerate 1000;sv_gravity 0");
		
		SmartMenu submenu = new SmartMenu(selectWeapon);
		submenu.SetTitle("Combien de HP?\n");
		submenu.SetCell("target", target);
		submenu.SetString("style", options);
	
		submenu.AddItem("1", 	"1");
		submenu.AddItem("35", 	"35");
		submenu.AddItem("50", 	"50");
		submenu.AddItem("75", 	"75");
		submenu.AddItem("100", "100");
		submenu.AddItem("200", "200");
		
		submenu.ExitButton = false;
		submenu.Display(client, MENU_TIME_FOREVER);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return;
}

public int selectWeapon(SmartMenu menu, MenuAction action, int client, int params) {
	static char options[64];
	if( action == MenuAction_Select ) {
		menu.GetItem(params, options, sizeof(options));
		int hp = StringToInt(options);
		int target = menu.GetCell("target");
		menu.GetString("style", options, sizeof(options));
		
		SetEntityHealth(client, hp);
		SetEntityHealth(target, hp);
		
		DV_StripWeapon(client);
		DV_StripWeapon(target);
		
		GivePlayerItem(client, "weapon_knife");
		GivePlayerItem(target, "weapon_knife");
		
		if( StrEqual(options, "slide") ) {
			Entity_SetCollisionGroup(client, COLLISION_GROUP_DEBRIS_TRIGGER);
			Entity_SetCollisionGroup(target, COLLISION_GROUP_DEBRIS_TRIGGER);
		
			if( GetEntityFlags(client) & FL_ONGROUND )
				SetEntityFlags(client, GetEntityFlags(client) & ~FL_ONGROUND);
			if( GetEntityFlags(target) & FL_ONGROUND )
				SetEntityFlags(target, GetEntityFlags(target) & ~FL_ONGROUND);
			
			float vel[3] =  { 0.0, 0.0, 800.0 };
		
			TeleportEntity(client, g_flStart, NULL_VECTOR, vel);
			TeleportEntity(target, g_flStart, NULL_VECTOR, vel);
		}
		
		SetEntProp(client, Prop_Data, "m_takedamage", 0);
		SetEntProp(target, Prop_Data, "m_takedamage", 0);
		
		CreateTimer(5.0, TIMER_DisableGodmod, client);
		CreateTimer(5.0, TIMER_DisableGodmod, target);
		
		PrintHintTextToAll("Début du combat dans 5 secondes");
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return;
}
public Action TIMER_DisableGodmod(Handle timer, any client) {
	SetEntProp(client, Prop_Data, "m_takedamage", 2);
	PrintHintTextToAll("FIGHT!");
}
public void DV_End(int client, int target) {	
	ServerCommand("sv_enablebunnyhopping %d;sv_autobunnyhopping %d", g_iEnabledBunny, g_iAutoBunny);
	ServerCommand("sv_airaccelerate %d;sv_gravity %d", g_iAirAccelerate, g_iGravity);
	
	if( client > 0 ) {
		Entity_SetCollisionGroup(client, COLLISION_GROUP_PLAYER);
		TeleportEntity(client, g_flStart, NULL_VECTOR, NULL_VECTOR);
	}
	if( target > 0 ) {
		Entity_SetCollisionGroup(target, COLLISION_GROUP_PLAYER);
		TeleportEntity(target, g_flStart, NULL_VECTOR, NULL_VECTOR);
	}
}
