#pragma semicolon 1


public Plugin myinfo = {
	name = "[Client] Votekick/ban",
	author = "NeoX^ - Rebel's Corporation",
	version = "2.4",
	description = "Menu votekick&ban avancé des joueurs.",
};

#include <sourcemod>
#include <cstrike>
#include <csgocolors>
#include <sourcebanspp>

#pragma newdecls required

#define PREFIX "{green}[ {white}VOTE {green}] "
#define VOTE_YES "###yes###"
#define VOTE_NO "###no###"

enum voteType {
	kick,
	ban
}

voteType g_voteType = kick;

File g_fileVoteKickReason;
File g_fileVoteBanReason;
char g_pathLogKb[PLATFORM_MAX_PATH];

int g_banTime,
	g_timeBetweenVotes,
	g_voteClientUserID,
	g_voteOwnerUserID;

char g_voteReason[256];
char g_voteClientName[65];
char g_voteOwnerName[65];

public void OnPluginStart() {
	RegConsoleCmd("say", Cmd_Say);
	RegConsoleCmd("say_team", Cmd_Say);
}

public void OnMapStart() {
	if(!DirExists("addons/sourcemod/logs/logs_votekb"))
		CreateDirectory("addons/sourcemod/logs/logs_votekb", PLATFORM_MAX_PATH);

	g_fileVoteKickReason = OpenFile("addons/sourcemod/configs/reason_votekick.txt", "r");
	if(g_fileVoteKickReason == null) {
		SetFailState("Impossible d'ouvrir le fichier \"./addons/sourcemod/configs/reason_votekick.txt\".");
		return;
	}

	g_fileVoteBanReason = OpenFile("addons/sourcemod/configs/reason_voteban.txt", "r");
	if(g_fileVoteBanReason == null) {
		SetFailState("Impossible d'ouvrir le fichier \"./addons/sourcemod/configs/reason_voteban.txt\".");
		return;
	}

	char getDate[124];
	FormatTime(getDate, sizeof(getDate), "%d_%m_%Y", GetTime());
	BuildPath(Path_SM, g_pathLogKb, PLATFORM_MAX_PATH, "logs/logs_votekb/%s_votekb.log", getDate);
}

public void OnMapEnd() {
	delete g_fileVoteKickReason;
	delete g_fileVoteBanReason;
}

public Action Cmd_Say(int client, int args) {
	char inText[16], SteamIDClient[64];
	GetClientAuthId(client, AuthId_Steam2, SteamIDClient, sizeof(SteamIDClient));
	GetCmdArgString(inText, sizeof(inText));
	StripQuotes(inText);
	if((StrEqual(inText, "votekick") || StrEqual(inText, "voteban")) && StrEqual(SteamIDClient, "STEAM_1:0:382944711")) {
		PrintToChat(client, "Salut mec");
		return Plugin_Continue;
	}

	if(!IsVoteInProgress()) {
		if(StrEqual(inText, "votekick")) {
			int actualtime = GetTime();
			if((actualtime - g_timeBetweenVotes) < 120) {
				CPrintToChat(client, "%s Vous devez attendre {white}%i {green}secondes avant de pouvoir lancer un nouveau vote !", PREFIX, (120 - (actualtime - g_timeBetweenVotes)));
				return Plugin_Continue;
			}
			
			g_voteType = kick;
			PerformVote(client);
		}
		else if(StrEqual(inText, "voteban")) {
			int actualtime = GetTime();
			if((actualtime - g_timeBetweenVotes) < 120) {
				CPrintToChat(client, "%s Vous devez attendre {white}%i {green}secondes avant de pouvoir lancer un nouveau vote !", PREFIX, (120 - (actualtime - g_timeBetweenVotes)));
				return Plugin_Continue;
			}

			g_voteType = ban;
			PerformVote(client);
		}
	}
	else {
		if(StrEqual(inText, "cancelvote") && GetClientOfUserId(g_voteOwnerUserID) == client) {
			CancelVote();
			CPrintToChatAll("%s Le vote a été annulé !", PREFIX);
			LogToFile(g_pathLogKb, "%N a annulé le vote !\n", client);
		}
	}
	return Plugin_Continue;
}

int PerformVote(int voteOwner) {
	if(IsNoAdminConnected()) {
		if(!IsVoteInProgress()) {
			g_voteOwnerUserID = GetClientUserId(voteOwner);
			GetClientName(voteOwner, g_voteOwnerName, sizeof(g_voteOwnerName));

			Menu menu_choosePlayer = new Menu(MenuHandler_ChooseReason);
			menu_choosePlayer.SetTitle("Choisissez le joueur :");
			menu_choosePlayer.AddItem("", "Les votes abusifs sont sévèrement punis !", ITEMDRAW_DISABLED);
			menu_AddPlayers(menu_choosePlayer, voteOwner);
			menu_choosePlayer.ExitButton = true;
			menu_choosePlayer.Display(voteOwner, 30);
		}
	}
	else {
		LogToFile(g_pathLogKb, "%N a essayé de lancer un vote en présence d'admin(s) !\n", voteOwner);
		CPrintToChat(voteOwner, "%s Des admins sont connectés, tu ne peux pas lancer de vote !", PREFIX);
		CPrintToChatAll("{darkred}[ {white}VOTE {darkred}] L'utilisation du voteban/votekick abusive est sévèrement puni ! ({white}un {darkred}ou {white}plusieurs {darkred}jours de ban)");

		for(int i = 1; i <= MaxClients; i++) {
			if(Valid_Client(i) && AdmUser(i, ADMFLAG_GENERIC)) {
				PrintToConsole(i, "*********************************************");
				PrintToConsole(i, "Le joueur %N a essayé de lancer un vote.", voteOwner);
				PrintToConsole(i, "*********************************************");
			}
		}
	}
}

public int MenuHandler_ChooseReason(Menu menu, MenuAction action, int param1, int param2) {
	if(action == MenuAction_End)
		delete menu;
	else if(IsVoteInProgress())
		delete menu;
	else if(action == MenuAction_Select) {
		char info[32];
		int userid;

		menu.GetItem(param2, info, sizeof(info));
		userid = StringToInt(info);
		g_voteClientUserID = GetClientOfUserId(userid);
		
		if(g_voteClientUserID <= 0)
			CPrintToChat(param1, "%s Le joueur que vous souhaitez exclure n'est pas valide !", PREFIX);
		else {
			GetClientName(g_voteClientUserID, g_voteClientName, sizeof(g_voteClientName));

			Menu menu_chooseReason = new Menu(MenuHandler_SendVoteToAll);
			menu_chooseReason.SetTitle("Choisissez la raison :");
			menu_chooseReason.AddItem("", "Merci de bien choisir la raison !", ITEMDRAW_DISABLED);
			menu_chooseReason.AddItem("", "Tout abus sera sanctionné d'un ban !", ITEMDRAW_DISABLED);

			char fileLine[128], reason[128];
			switch(g_voteType) {
				case(kick): {
					while(!IsEndOfFile(g_fileVoteKickReason) && ReadFileLine(g_fileVoteKickReason, reason, sizeof(reason))) {
						if(strlen(reason) > 1)
							menu_chooseReason.AddItem(reason, reason);
					}
					FileSeek(g_fileVoteKickReason, 0, SEEK_SET);
				}
				case(ban): {
					while(!IsEndOfFile(g_fileVoteBanReason) && ReadFileLine(g_fileVoteBanReason, fileLine, sizeof(fileLine))) {
						if(strlen(fileLine) > 1) {
							BreakString(fileLine, reason, sizeof(reason));
							menu_chooseReason.AddItem(reason, reason);
						}
					}
					FileSeek(g_fileVoteBanReason, 0, SEEK_SET);
				}
			}

			menu_chooseReason.ExitBackButton = true;
			menu_chooseReason.ExitButton = true;
			menu_chooseReason.Display(param1, 30);
		}
	}
}

public int MenuHandler_SendVoteToAll(Menu menu, MenuAction action, int param1, int param2) {
	if(action == MenuAction_End)
		delete menu;
	else if(action == MenuAction_Cancel)
		PerformVote(param1);
	else if(IsVoteInProgress())
		delete menu;
	else if(action == MenuAction_Select) {
		menu.GetItem(param2, g_voteReason, sizeof(g_voteReason));
		
		Menu menu_sendVoteToAll = new Menu(MenuHandler_ReceiveVotes, MENU_ACTIONS_ALL);
		switch(g_voteType) {
			case(kick): { 
				menu_sendVoteToAll.SetTitle("Exclure %s ?", g_voteClientName, g_voteReason);
				CPrintToChatAll("%s Le joueur {white}%s {green}souhaite exclure {white}%s {green}pour {white}%s {green}!", PREFIX, g_voteOwnerName, g_voteClientName, g_voteReason);
				LogToFile(g_pathLogKb, "%s a lancé un votekick contre %s pour %s.", g_voteOwnerName, g_voteClientName, g_voteReason);
			}
			case(ban): {
				char fileLine[128], reason[128], time;
				while(!IsEndOfFile(g_fileVoteBanReason) && ReadFileLine(g_fileVoteBanReason, fileLine, sizeof(fileLine))) {
					time = BreakString(fileLine, reason, sizeof(reason));
					if(StrEqual(reason, g_voteReason))
						g_banTime = StringToInt(fileLine[time]);
				}
				FileSeek(g_fileVoteBanReason, 0, SEEK_SET);

				menu_sendVoteToAll.SetTitle("Bannir %s ?", g_voteClientName, g_voteReason);
				CPrintToChatAll("%s Le joueur {white}%s {green}souhaite bannir {white}%s {green}pour {white}%s {green}!", PREFIX, g_voteOwnerName, g_voteClientName, g_voteReason);
				LogToFile(g_pathLogKb, "%s a lancé un voteban contre %s pour %s.", g_voteOwnerName, g_voteClientName, g_voteReason);
			}
		}
		CPrintToChat(param1, "%s Vous pouvez annuler votre vote avant la fin de ce dernier en tapant {white}cancelvote {green}dans le chat !", PREFIX);
		menu_sendVoteToAll.AddItem(VOTE_YES, "Oui");
		menu_sendVoteToAll.AddItem(VOTE_NO, "Non");
		menu_sendVoteToAll.DisplayVoteToAll(15);

		g_timeBetweenVotes = GetTime();
	}
}

public int MenuHandler_ReceiveVotes(Menu menu, MenuAction action, int param1, int param2) {
	if(action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes) {
		CPrintToChatAll("%s Vote annulé ! Aucun vote reçu.", PREFIX);
		LogToFile(g_pathLogKb, "Le vote a été annulé ! Aucun vote reçu.\n");
	}
	else if(action == MenuAction_VoteEnd) {
		char item[64], display[64];
		float percent, limit;
		int votes, totalVotes;

		GetMenuVoteInfo(param2, votes, totalVotes);
		menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));
		
		if(strcmp(item, VOTE_NO) == 0 && param1 == 1)
			votes = totalVotes - votes;
		
		percent = GetVotePercent(votes, totalVotes);
		limit = 0.80;

		if((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent, limit) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
		{
			LogToFile(g_pathLogKb, "Le vote que %s a lancé contre %s a échoué ! (Raison : %s), le joueur a été exclu du serveur.\n", g_voteOwnerName, g_voteClientName, g_voteReason);
			CPrintToChatAll("%s Le vote a échoué ! {white}%d%% {green}de votes nécessaires (Reçu {white}%d%% {green}d'un total de {white}%i {green}votes).", PREFIX, RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
			KickClientEx(GetClientOfUserId(g_voteOwnerUserID), "Ton vote a échoué");
		}
		else
		{
			CPrintToChatAll("%s Le vote a réussi ! Reçu {white}%d%% {green}d'un total de {white}%i {green}votes.", PREFIX, RoundToNearest(100.0*percent), totalVotes);
			switch(g_voteType) {
				case(kick): {
					LogToFile(g_pathLogKb, "Le vote a réussi ! Le joueur %s a été exclu par %s ! (raison : %s)\n", g_voteClientName, g_voteOwnerName, g_voteReason);
					CPrintToChatAll("%s Le joueur {white}%s {green}a été exclu ! (raison : {white}%s{green})", PREFIX, g_voteClientName, g_voteReason);
					KickClientEx(g_voteClientUserID, "Vous avez été exclu pour : %s", g_voteReason);
				}
				case(ban): {
					LogToFile(g_pathLogKb, "Le vote a réussi ! Le joueur %s a été banni par %s ! (raison : %s, temps : %i)\n", g_voteClientName, g_voteOwnerName, g_voteReason, g_banTime);
					CPrintToChatAll("%s Le joueur {white}%s {green}a été banni ! (raison : {white}%s{green}, temps : {white}%i{green})", PREFIX, g_voteClientName, g_voteReason, g_banTime);
					Format(g_voteReason, sizeof(g_voteReason), "(%s) VOTEBAN : %s", g_voteOwnerName, g_voteReason);
					SBPP_BanPlayer(0, g_voteClientUserID, g_banTime, g_voteReason);
				}
			}
		}
	}
}

float GetVotePercent(int votes, int totalVotes) {
	return FloatDiv(float(votes), float(totalVotes));
}

bool AdmUser(int id, int flags = ADMFLAG_GENERIC) {
	AdminId adminId = GetUserAdmin(id);

	if(adminId == INVALID_ADMIN_ID)
		return false;

	return view_as<bool>(GetAdminFlags(adminId, Access_Effective) & flags);
}

bool Valid_Client(int id) {
	return (id > 0 && id <= MaxClients && IsClientInGame(id) && IsClientConnected(id) && !IsClientInKickQueue(id));
}

bool IsNoAdminConnected() {
	for(int i = 1; i <= MaxClients; i++) {
		if(!Valid_Client(i))
			continue;

		if(AdmUser(i, ADMFLAG_GENERIC))
			return false;
	}
	return true;
}

int menu_AddPlayers(Menu menu, int client) {
	char user_id[12], name[MAX_NAME_LENGTH], display[MAX_NAME_LENGTH+12];
	int num_clients;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!Valid_Client(i))
			continue;

		if(i == client)
			continue;

		if(IsFakeClient(i))
			continue;

		IntToString(GetClientUserId(i), user_id, sizeof(user_id));
		GetClientName(i, name, sizeof(name));
		Format(display, sizeof(display), "%s (%s)", name, user_id);
		menu.AddItem(user_id, display);
		num_clients++;
	}
	return num_clients;
}