#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <basecomm>
#include <rsc_utils>

public Plugin myinfo = {
	name = "Terrorist Mute",
	author = "Kriax",
	version = "1.0",
};

public void OnPluginStart() {
	for (int i = 1; i <= MaxClients; i++) {
		if(IsClientValid(i)) {
			ChangeMute(i);
		}
	}
	
	HookEvent("player_death", Event_ChangeMute);
	HookEvent("player_spawn", Event_ChangeMute);
	HookEvent("round_start", Event_RoundStart);
}

public Action Event_ChangeMute(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(IsClientValid(client)) {
		ChangeMute(client);
	}
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	for (int i = 1; i <= MaxClients; i++) {
		if(IsClientValid(i)) {
			ChangeMute(i);
		}
	}
}

public void ChangeMute(int client) {

	if(BaseComm_IsClientMuted(client)) {
		return;
	}
	
	if(IsClientAdmin(client)) {
		SetClientListeningFlags(client, VOICE_SPEAKALL);
		LogAction(0, 0, "admin %N VOICE_SPEAKALL", client);
		return;
	}
		
	if(!IsPlayerAlive(client)) {
		SetClientListeningFlags(client, VOICE_MUTED);
		return;
	
	}
	if(GetClientTeam(client) == 3) {
		SetClientListeningFlags(client, VOICE_NORMAL);
		return;
	}
	
	if(GetClientTeam(client) == 2) {
		SetClientListeningFlags(client, GetTAlive() > 6 ? VOICE_MUTED:VOICE_SPEAKALL);
	}
}

stock bool IsClientAdmin(int client)
{	
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM2) {
		return false;
	}
	
	if(GetUserFlagBits(client) & ADMFLAG_BAN || GetUserFlagBits(client) & ADMFLAG_ROOT) {
		return true
	}
	
	return false;
}

stock int GetTAlive() {
	int amount;
	
	for (int i = 1; i <= MaxClients; i++) {
		if(!IsClientConnected(i) || !IsClientInGame(i) || !IsPlayerAlive(i)) {
			continue;
		}
		
		if(GetClientTeam(i) != 2) {
			continue;
		}
		
		amount++;
	}
	
	return amount;
}
