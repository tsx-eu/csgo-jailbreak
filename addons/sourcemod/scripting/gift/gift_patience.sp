#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <gift>
#include <csgocolors>
#include <cstrike>
#include <smlib>

#pragma newdecls required

int g_iGift = -1;
Handle g_hWeapon[65];

public Plugin myinfo = {
	name = "Gift: PATIENCE",
	author = "KoSSoLaX, Mack",
	description = "Ajoute un peu de munitions",
	version = "1.0.0",
	url = "zaretti.be"
};

public void Gift_OnGiftStart() {
	g_iGift = Gift_RegisterNewGift("Patience", "Patience", true, false, 100.0, -1, ADMFLAG_CUSTOM1|ADMFLAG_ROOT);
}
public void OnPluginStart() {
	HookEvent("round_start", 		OnRoundStart, 			EventHookMode_Post);
}

public Action Gift_OnRandomGift(int client, int gift) {
	if(gift != g_iGift)
		return Plugin_Handled;
	
	CPrintToChat(client, "{lightgreen}%s {green} Vous êtes PATIENT!", PREFIX);
	
	int wpnId = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if( wpnId > 0 )
		AcceptEntityInput(wpnId, "Kill");
	
	wpnId = EntIndexToEntRef(Client_GiveWeaponAndAmmo(client, "weapon_p250", true, 0, 0, 1, 0));
	
	Handle dp;
	g_hWeapon[client] = CreateDataTimer(20.0, Timer_IncrementAmmunition, dp, TIMER_REPEAT);
	WritePackCell(dp, client);
	WritePackCell(dp, wpnId);
	
	return Plugin_Handled;
}
public Action Timer_IncrementAmmunition(Handle timer, Handle dp) {
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int wpnId = EntRefToEntIndex(ReadPackCell(dp));
	if( wpnId == INVALID_ENT_REFERENCE ) {
		KillTimer(g_hWeapon[client]);
		g_hWeapon[client] = null;
		return Plugin_Stop;
	}
	
	if( client == Weapon_GetOwner(wpnId) ) {
		int ammo = Weapon_GetPrimaryClip(wpnId) + 1;
		if( ammo <= 2 ) {
			Weapon_SetPrimaryClip(wpnId, ammo);
			CPrintToChat(client, "{lightgreen}%s {green} Une nouvelle balle est disponible dans votre chargeur!", PREFIX);
		}
	}
	
	return Plugin_Continue;
}
public Action OnRoundStart(Handle ev, const char[] name, bool dontBroadcast) {
	for (int i = 0; i < MaxClients; i++) {
		if( g_hWeapon[i] != null )
			KillTimer(g_hWeapon[i]);
		g_hWeapon[i] = null;
	}
}
