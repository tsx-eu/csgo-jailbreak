#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

#pragma newdecls required

#include <jb_lastrequest>

int g_iState = 0;
Handle g_hMain = INVALID_HANDLE;

public void JB_OnPluginReady() {
	JB_CreateLastRequest("Combat de flashbang", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON, DV_CAN, DV_Start, DV_Stop);
}
stock bool DV_CAN(int client) {
	Handle cvar = FindConVar("sm_noblock");
	if( cvar != INVALID_HANDLE )
		if( GetConVarInt(cvar) == 1 )
			return false;
	return true;
}
public void DV_Start(int client, int target) {
	
	g_iState = 1;
	SetEntityHealth(client, 1);
	SetEntityHealth(target, 1);
	
	Client_SetArmor(client, 0);
	Client_SetArmor(target, 0);
	
	DV_StripWeapon(client);
	DV_StripWeapon(target);
	
	GivePlayerItem(client, "weapon_flashbang");
	GivePlayerItem(target, "weapon_flashbang");	
	
	Handle dp;
	g_hMain = CreateDataTimer(1.0, EventSecondElapsed, dp, TIMER_REPEAT);
	WritePackCell(dp, client);
	WritePackCell(dp, target);
}
public void OnEntityCreated(int entity, const char[] classname) {
	if( g_iState == 1 && StrEqual(classname, "flashbang_projectile") ) {
		DispatchKeyValue(entity, "OnUser1", "!self,KillHierarchy,,1.5,-1");
		AcceptEntityInput(entity, "FireUser1");
	}
}

public Action EventSecondElapsed(Handle timer, Handle dp) {
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int target = ReadPackCell(dp);
	
	if( Client_GetWeapon(client, "weapon_flashbang") == -1 )
		GivePlayerItem(client, "weapon_flashbang");
	if( Client_GetWeapon(target, "weapon_flashbang") == -1 )
		GivePlayerItem(target, "weapon_flashbang");
}

public void DV_Stop(int client, int target) {
	g_iState = 0;
	KillTimer(g_hMain);
	g_hMain = null;
}
