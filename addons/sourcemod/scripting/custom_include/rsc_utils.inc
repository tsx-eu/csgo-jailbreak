#if defined _rsc_included
#endinput
#endif
#define _rsc_included

#include <sourcemod>
#include <sdktools>

stock bool IsClientValid(int client, bool alive = false)
{
	if(client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		if(alive && !IsPlayerAlive(client))
			return false;
		
		return true;
	}
	return false;
}

stock FakePrecacheSound(const char[] szPath)
{
	AddToStringTable( FindStringTable( "soundprecache" ), szPath );
}

stock void TimeToProgressBar(int time, int maxtime, int bartime, char[] buffer, int maxlen, char[] load, char[] notload)
{
	float convert = float(bartime) * (float(time) / float(maxtime));

	for (int i = 1; i <= bartime; i++)
		Format(buffer, maxlen, "%s%s", buffer, convert >= i ? load:notload);
}

stock void FlashTimer(Handle &timer)
{
	if(timer != null)
		delete timer;
	timer = null;
}

stock void ClientDisarm(int client)
{
	int index;
	for (int i = 0; i < 6; i++)
		if (i < 6 && (index = GetPlayerWeaponSlot(client, i)) != -1)
			RemovePlayerItem(client, index);
}

stock void DeleteEntityDelay(int entity, float time = 0.1)
{
	CreateTimer(time, Timer_DeleteEntity, EntIndexToEntRef(entity));
}

public Action Timer_DeleteEntity(Handle timer, any ref)
{
	int entity = EntRefToEntIndex(ref);

	if(IsValidEntity(entity) && IsValidEdict(entity) && entity > 0)
		AcceptEntityInput(entity, "Kill");
}

stock void TimeToMinuts(int time, char[] buffer, int size)
{
	int minutes = time / 60;
	int seconds = time - 60 * minutes;
	
	Format(buffer, size, "%s%i'%s%i", (minutes < 10 ? "0":""), minutes, (seconds < 10 ? "0":""), seconds);
}

public bool KnifeWeapon(const char[] weapon) {
	if(StrContains(weapon, "knife") != -1) {
		return true;
	}
	
	if(StrContains(weapon, "bayonet") != -1) {
		return true;
	}
	
	return false;
}

/* ---------------------------------------------------------------------- */

/* Fonction qui supprime un timer */
stock void DeleteTimer(Handle &timer) {
	if(timer != null) {
		delete timer;
	}
	
	timer = null;
}

/* Precache d'effect */
stock void PrecacheParticleEffect(char[] sEffectName) {
	/*int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE) {
		table = FindStringTable("ParticleEffectNames");
	}*/
	
	int table = FindStringTable("ParticleEffectNames");
	bool save = LockStringTables(false);
	AddToStringTable(table, sEffectName);
	LockStringTables(save);
}

/* ---------------------------------------------------------------------- */

/* Fonction qui trouve un client via son steamid */
stock int FindPlayerByAuthid(char[] buffer, AuthIdType authid) {
	char szAuthId[32];
	
	for (int i = 1; i <= MaxClients; i++) {
		if(!IsClientValid(i)) {
			continue;
		}
		
		GetClientAuthId(i, authid, szAuthId, sizeof(szAuthId));
		
		if(StrEqual(buffer, szAuthId)) {
			return i;
		}
	}
	
	return 0;
}

/* Fonction qui reprend le nombre de joueur pas en spec (je sais plus pourquoi) */
stock int GetNumbPlayer() {
	int amount;
	
	for (int i = 1; i <= MaxClients; i++) {
		if(IsClientValid(i)) {
			if(GetClientTeam(i) > 1) {
				amount++;
			}
		}
	}
	
	return amount;
}
