#include <cstrike>

#if defined _jb_last_request_included
 #endinput
#endif
#define _jb_last_request_included

#include <valist>

#define MOD_TAG					"{lightgreen}[ {default}LR {lightgreen}] "
#define MOD_TAG_START			"{default}"
#define MOD_TAG_END				"{lightgreen}"

#define MAX_LR					32
#define MAX_PLAYERS				65
#define MAX_DISTANCE			500.0

#define JB_SHOULD_SELECT_CT		(1<<0)
#define JB_SHOULD_SELECT_T		(1<<1)			// Not implemented, yet.
#define JB_RUN_UNTIL_DEAD		(1<<2)
#define JB_RUN_UNTIL_ROUND_END	(1<<3)
#define JB_BEACON				(1<<10)
#define JB_NODAMAGE				(1<<11)

#define JB_DEFAULT				JB_RUN_UNTIL_DEAD
#define JB_SELECT_CT_UNTIL_DEAD	JB_SHOULD_SELECT_CT|JB_RUN_UNTIL_DEAD

forward void JB_OnPluginReady();
forward void OnStartLR(int terro, int ct, int lr);
forward void OnStopLR(int terro, int ct, int lr);

native int JB_CreateLastRequest(const char name[128], int flags = JB_DEFAULT, JB_Condition condition = INVALID_FUNCTION, JB_Event start = INVALID_FUNCTION, JB_Event end = INVALID_FUNCTION);
native int JB_SetTeamCount(int id, int team, int count);
native int JB_AddClientInDV(int client);

native bool JB_IsDvActive(Handle plugin = INVALID_HANDLE);
native void JB_End();
native void DV_CleanTeam(int team = 0);

typeset JB_Condition {
	function bool(int client);
	function bool(int[] clients, int clientCount);
}
typeset JB_Event {
	function void(int client);
	function void(int client, int target);
	function void(int client, int[] targets, int targetCount);
	function void(int[] clients, int clientCount);
	function void(int[] clients, int clientCount, int target);
	function void(int[] clients, int clientCount, int[] targets, int targetCount);
}

stock bool DV_CAN_Always(int client) {
	return true;
}
stock bool DV_CAN_Min3CT(int client) {
	int cpt = 0;
	for (int i = 1; i <= MaxClients; i++)
		if( IsClientInGame(i) &&  IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT )
			cpt++;
	
	return (cpt>=3);
}
stock bool DV_CAN_VIP(int client) {
	return view_as<bool>(GetUserFlagBits(client) & ADMFLAG_CUSTOM1);
}
stock bool DV_CAN_Cupidon(int[] clients, int clientCount) {
	if( clientCount != 2 )
		return false;
	static char tmp[32];

	int i = 0;
	while ( (i = FindEntityByClassname(i, "info_particle_system")) != INVALID_ENT_REFERENCE ) {
		GetEntPropString(i, Prop_Data, "m_iTargetName", tmp, sizeof(tmp)); 
		PrintToChatAll("%d -> %s -> %d", i, tmp, Entity_GetParent(i));
	}

	for (i = 0; i < clientCount; i++) {
		Format(tmp, sizeof(tmp), "particlecupidon%d", clients[i]);
		if( Entity_FindByName(tmp, "info_particle_system") == INVALID_ENT_REFERENCE )
			return false;
	}
	
	return true;
}
stock void DV_StripWeapon(int client, bool drop = false) {
	int wepIdx = -1;
	for( int i = 0; i < 5; i++ ) {
		while( ( wepIdx = GetPlayerWeaponSlot( client, i ) ) != -1 ) {
			if( i == CS_SLOT_KNIFE || i == CS_SLOT_GRENADE || !drop ) {
				RemovePlayerItem( client, wepIdx );
				RemoveEdict( wepIdx );
			}
			else {
				CS_DropWeapon(client, wepIdx, true);
			}
		}
	}
}
stock void JB_DisplayMenu(Function menu, int ...) {
	Handle dp;
	va_start(2);
	
	CreateDataTimer(0.01, DV_REOPEN_MENU_TASK, dp, TIMER_DATA_HNDL_CLOSE);
	WritePackFunction(dp, menu);
	WritePackCell(dp, va_args());
	
	while ( va_more() )
		WritePackCell(dp, va_arg());
	va_end();
}

public Action DV_REOPEN_MENU_TASK(Handle timer, Handle dp) {
	if( !JB_IsDvActive(GetMyHandle()) )
		return;
	
	ResetPack(dp);
	Function menu = ReadPackFunction(dp);
	int count = ReadPackCell(dp);
	
	
	Call_StartFunction(INVALID_HANDLE, menu);
	for(int i =0; i<count; i++)
		Call_PushCell(ReadPackCell(dp));
	Call_Finish();
	
	delete dp;
}
