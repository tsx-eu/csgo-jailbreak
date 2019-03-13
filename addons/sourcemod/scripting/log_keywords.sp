#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <csgocolors>

#pragma newdecls required

public Plugin myinfo = {
	name = "Un truc pour les admins",
	author = "KoSSoLaX",
	description = "qui fait des choses que vous devez pas savoir",
	version = "1.0.0",
	url = "zaretti.be"
};

ArrayList g_hKeyWords = null;

public void OnPluginStart() {
	RegConsoleCmd("say", 			Command_Say);
	RegConsoleCmd("say_team", 		Command_Say);
}
public void OnMapStart() {
	static char path[256], line[MAX_MESSAGE_LENGTH];
	BuildPath(Path_SM, path, sizeof(path), "data/keywords_badword.txt");
	
	if( FileExists(path) ) {
		g_hKeyWords = new ArrayList(MAX_MESSAGE_LENGTH, 0);
		
		File o = OpenFile(path, "r");
		while( o.ReadLine(line, sizeof(line) ) ) {
			TrimString(line);
			g_hKeyWords.PushString(line);
		}
	}
}

public Action Command_Say(int client, int args) {
	static char line[MAX_MESSAGE_LENGTH], words[MAX_MESSAGE_LENGTH];
	GetCmdArgString(line, sizeof(line));
	TrimString(line);
	
	if( g_hKeyWords != null ) {
		for (int i = 0; i < g_hKeyWords.Length; i++) {
			g_hKeyWords.GetString(i, words, sizeof(words));
			if( StrContains(line, words, false) != -1 ) {
				ReportPlayer(client, words, line);
				break;
			}
		}
	}
}

void ReportPlayer(int client, const char[] match, const char[] text) {
	static char path[256];
	BuildPath(Path_SM, path, sizeof(path), "data/keywords_report.txt");
	static char IP[64];
	GetClientIP(client, IP, sizeof(IP));
	LogToFile(path, "%L<%s> - %s - %s", client, IP, match, text);
}

