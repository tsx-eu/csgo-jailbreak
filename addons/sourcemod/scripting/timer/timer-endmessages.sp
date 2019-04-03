#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <timer>
#include <timer-stocks>
#include <timer-config_loader.sp>
#include <timer-physics>
#include <timer-worldrecord>

#define SOUND_PERSRECORD "music/timer/server_personnalrecord.mp3"
#define SOUND_SR0 "music/timer/server_record.mp3"
#define SOUND_SR1 "music/timer/server_record1.mp3"
#define SOUND_SR2 "music/timer/server_record2.mp3"
#define SOUND_SR3 "music/timer/server_record3.mp3"
#define SOUND_NOTHYET "music/timer/server_nopersorecord.mp3"

public Plugin myinfo = {
	name = "[Timer] Finish Messages",
	author = "NeoX^",
	version = "1.5",
	description = "End messages when a client finish a map & messages for SR"
};

char g_szSRRecord[64];
Handle g_hHudSync;

public void OnPluginStart() {
	LoadPhysics();
	LoadTimerSettings();

	g_hHudSync = CreateHudSynchronizer();
}

public void OnMapStart() {
	LoadPhysics();
	LoadTimerSettings();
	PrecacheSound(SOUND_PERSRECORD, false);
	PrecacheSound(SOUND_SR0, false);
	PrecacheSound(SOUND_SR1, false);
	PrecacheSound(SOUND_SR2, false);
	PrecacheSound(SOUND_SR3, false);
	PrecacheSound(SOUND_NOTHYET, false);
}

public int OnTimerRecord(int client, int track, int style, float newTime, float bestTime, int currentRank, int newRank) {
	char szNewPlayerTime[64], szBestPlayerTime[64], szPlayerAuth[32];
	Timer_SecondsToTime(newTime, szNewPlayerTime, sizeof(szNewPlayerTime), 2);
	Timer_SecondsToTime(bestTime, szBestPlayerTime, sizeof(szBestPlayerTime), 2);
	GetClientAuthId(client, AuthId_Steam2, szPlayerAuth, sizeof(szPlayerAuth));

	bool IsRankedStyle = view_as<bool>(Timer_IsStyleRanked(style));

	int iTotalRanks, iRecordID;
	float fServerRecordTime, fPlayerLastTime, fSRTimeDiff, fBeatenPlayerTime, fBeatenPlayerTimeDiff, fPersonalPlayerTimeDiff;
	char szTimeDiffSR[64], szBeatenPlayerName[MAX_NAME_LENGTH], szBeatenPlayerTimeDiff[64], szPersonalPlayerTimeDiff[64];
	bool enable = false, jumps, fpsmax;
	Timer_GetClientTimer(client, enable, fPlayerLastTime, jumps, fpsmax);
	Timer_GetStyleRecordWRStats(style, track, iRecordID, fServerRecordTime, iTotalRanks);
	Timer_GetRecordTimeInfo(style, track, newRank + 1, fBeatenPlayerTime, szBeatenPlayerTimeDiff, sizeof(szBeatenPlayerTimeDiff));
	Timer_GetRecordHolderName(style, track, newRank + 1, szBeatenPlayerName, sizeof(szBeatenPlayerName));
	Timer_SecondsToTime(fServerRecordTime, g_szSRRecord, sizeof(g_szSRRecord), 2);

	fSRTimeDiff = fServerRecordTime - newTime;
	if(fSRTimeDiff < 0.0)
		fSRTimeDiff = fSRTimeDiff * -1.0;
	Timer_SecondsToTime(fSRTimeDiff, szTimeDiffSR, sizeof(szTimeDiffSR), 2);

	fPersonalPlayerTimeDiff = bestTime - newTime;
	Timer_SecondsToTime(fPersonalPlayerTimeDiff, szPersonalPlayerTimeDiff, sizeof(szPersonalPlayerTimeDiff), 2);

	fBeatenPlayerTimeDiff = fBeatenPlayerTime - newTime;
	Timer_SecondsToTime(fBeatenPlayerTimeDiff, szBeatenPlayerTimeDiff, sizeof(szBeatenPlayerTimeDiff), 2);

	PrintToChatAll("%f - fServerRecordTime", fServerRecordTime);
	PrintToChatAll("%f - newTime", newTime);
	PrintToChatAll("%f - bestTime", bestTime);

	char szGetTrack[32], szGetPlayerPosition[32], szGetTrackName[32];
	if(track == 0) {
		FormatEx(szGetTrack, sizeof(szGetTrack), "la map");
		FormatEx(szGetTrackName, sizeof(szGetTrackName), "Normal");
	}
	else if(track == 1) {
		FormatEx(szGetTrack, sizeof(szGetTrack), "le bonus");
		FormatEx(szGetTrackName, sizeof(szGetTrackName), "Bonus");
	}
	else if(track == 2) {
		FormatEx(szGetTrack, sizeof(szGetTrack), "le bonus 2");
		FormatEx(szGetTrackName, sizeof(szGetTrackName), "Bonus 2");
	}
	else if(track == 3) {
		FormatEx(szGetTrack, sizeof(szGetTrack), "le bonus 3");
		FormatEx(szGetTrackName, sizeof(szGetTrackName), "Bonus 3");
	}
	else if(track == 4) {
		FormatEx(szGetTrack, sizeof(szGetTrack), "le bonus 4");
		FormatEx(szGetTrackName, sizeof(szGetTrackName), "Bonus 4");
	}
	else if(track == 5) {
		FormatEx(szGetTrack, sizeof(szGetTrack), "le bonus 5");
		FormatEx(szGetTrackName, sizeof(szGetTrackName), "Bonus 5");
	}
	FormatEx(szGetPlayerPosition, sizeof(szGetPlayerPosition), "Pos : {white}%d/%d{blue}.", newRank, iTotalRanks);

	if(newTime == fServerRecordTime) {
		if(track == 0)
			SetHudTextParamsEx(-1.0, 0.3, 2.0, {255, 102, 0, 255}, {255, 255, 255, 255}, 2, 0.10, 0.08, 0.010);
		else
			SetHudTextParamsEx(-1.0, 0.3, 2.0, {204, 0, 153, 255}, {255, 255, 255, 255}, 2, 0.10, 0.08, 0.010);

		for(int i = 1; i <= MaxClients; i++) {
			if(Valid_Client(i))
				ShowSyncHudText(i, g_hHudSync, "* SERVEUR RECORD [%s] : %N en %s *", szGetTrackName, client, szNewPlayerTime);
		}
	}

	if(IsRankedStyle) {
		if(newTime == fServerRecordTime) { //Nouveau serveur record
			ChooseRandomSoundSR();
			CPrintToChatAll("{darkred}*** NOUVEAU RECORD SERVEUR ***");
			if((iTotalRanks - 1) == 0 && currentRank <= 0) { //Premier temps sur la map
				CPrintToChatAll("%s {grey}%N {blue}a fini %s en {grey}%s {blue}et inaugure le bal !", PREFIX, client, szGetTrack, g_Physics[style][StyleName]);
				CPrintToChatAll("%s Temps : {white}%s {blue}en {white}%d {blue}sauts.", PREFIX, szNewPlayerTime, jumps);
				return;
			}
			else if(currentRank <= 0) { //Joueur fini la map pour la première fois
				if(iTotalRanks > 1) 
					CPrintToChatAll("%s {grey}%N {blue}a fini %s en {grey}%s {blue}du premier coup et a battu {grey}%s {blue}!", PREFIX, client, szGetTrack, g_Physics[style][StyleName], szBeatenPlayerName);
			}
			else if(newRank < currentRank) //Joueur a battu quelqu'un
				CPrintToChatAll("%s {grey}%N {blue}a fini %s en {grey}%s {blue}et a battu {grey}%s {blue}!", PREFIX, client, szGetTrack, g_Physics[style][StyleName], szBeatenPlayerName);
			else { //Joueur a amélioré son temps
				CPrintToChatAll("%s {grey}%N {blue}a fini %s en {grey}%s {blue}et s'est amélioré !", PREFIX, client, szGetTrack, g_Physics[style][StyleName]);
				CPrintToChatAll("%s Temps : {white}%s {blue}[{green}-%s{blue}] en {white}%d {blue}sauts. %s", PREFIX, szNewPlayerTime, szPersonalPlayerTimeDiff, jumps, szGetPlayerPosition);
				return;
			}
			CPrintToChatAll("%s Temps : {white}%s {blue}[SR {green}-%s{blue}] en {white}%d {blue}sauts. %s", PREFIX, szNewPlayerTime, szBeatenPlayerTimeDiff, jumps, szGetPlayerPosition);
			return;
		}
		else if(newTime < bestTime) { //Nouveau record personnel & possibilité de battre quelqu'un
			EmitSoundToClient(client, SOUND_PERSRECORD);
			if(newRank < currentRank) { //Joueur a battu quelqu'un
				CPrintToChatAll("%s {grey}%N {blue}a fini %s en {grey}%s {blue}et a battu {grey}%s {blue}!", PREFIX, client, szGetTrack, g_Physics[style][StyleName], szBeatenPlayerName);
				CPrintToChatAll("%s Temps : {white}%s {blue}[{green}-%s{blue}] en {white}%d {blue}sauts. %s", PREFIX, szNewPlayerTime, szBeatenPlayerTimeDiff, jumps, szGetPlayerPosition);
			}
			else if(newRank == currentRank) { //Joueur a amélioré son temps
				CPrintToChatAll("%s {grey}%N {blue}a fini %s en {grey}%s {blue}et s'est amélioré !", PREFIX, client, szGetTrack, g_Physics[style][StyleName]);
				CPrintToChatAll("%s Temps : {white}%s {blue}[{green}-%s{blue}] en {white}%d {blue}sauts. %s", PREFIX, szNewPlayerTime, szPersonalPlayerTimeDiff, jumps, szGetPlayerPosition);
			}
			return;
		}
		else if(newTime >= bestTime) { //Pas de nouveau record perso
			if(bestTime != 0.0) {
				EmitSoundToClient(client, SOUND_NOTHYET);
				CPrintToChat(client, "%s Vous avez fini %s sans aucune amélioration ...", PREFIX, szGetTrack);
			}
			else {
				EmitSoundToClient(client, SOUND_PERSRECORD);
				CPrintToChat(client, "%s Vous avez fini %s pour la première fois !", PREFIX, szGetTrack);
			}
			CPrintToChatAll("%s {grey}%N {blue}a fini %s en {grey}%s{blue}. Temps : {white}%s {blue}[SR {darkred}+%s{blue}].", PREFIX, client, szGetTrack, g_Physics[style][StyleName], szNewPlayerTime, szTimeDiffSR);
			return;
		}
	}
}

stock void ChooseRandomSoundSR() {
	switch(GetRandomInt(1, 4)) {
		case 1: EmitSoundToAll(SOUND_SR0);
		case 2: EmitSoundToAll(SOUND_SR1);
		case 3: EmitSoundToAll(SOUND_SR2);
		case 4: EmitSoundToAll(SOUND_SR3);
	}
}

stock bool Valid_Client(int id) {
	return (id > 0 && id <= MaxClients && IsClientInGame(id) && IsClientConnected(id) && !IsClientInKickQueue(id));
}

stock void FlashTimer(Handle &timer) {
	if(timer != null)
		delete timer;
	timer = null;
}