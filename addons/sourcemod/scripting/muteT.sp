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
	ChangeMute();
	
	HookEvent("player_death", Event_ChangeMute);
	HookEvent("player_spawn", Event_ChangeMute);
	HookEvent("round_start", Event_ChangeMute);
}

public Action Event_ChangeMute(Handle event, const char[] name, bool dontBroadcast) {
	ChangeMute();
}

public void ChangeMute() {
	for (int i = 1; i <= MaxClients; i++) {
		if(!IsClientValid(i) || BaseComm_IsClientMuted(i)) {
			continue;
		}
		
		if(IsClientAdmin(i)) {
			SetClientListeningFlags(i, VOICE_SPEAKALL);
			continue;
		}
			
		if(!IsPlayerAlive(i)) {
			SetClientListeningFlags(i, VOICE_MUTED);
			continue;
		}
		
		if(GetClientTeam(i) == 3) {
			SetClientListeningFlags(i, VOICE_NORMAL);
			continue;
		}
		
		if(GetClientTeam(i) == 2) {
			SetClientListeningFlags(i, GetTAlive() > 6 ? VOICE_MUTED:VOICE_SPEAKALL);
		}
	}	
}

stock bool IsClientAdmin(int client)
{
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM2) {
		return false;
	}
	
	if(GetUserFlagBits(client) & ADMFLAG_ROOT|ADMFLAG_BAN) {
		return true;
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