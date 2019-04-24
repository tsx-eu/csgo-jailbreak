#pragma semicolon 1

#include <sourcemod>
#include <steamworks>

#pragma newdecls required

#define SERVICE_URL	"http://check.getipintel.net/check.php?ip=%s&contact=kossolax@gmail.com&flags=f"
#define	BAN_TIME	60
#define	QUEUE_SPEED	5.0

public Plugin myinfo = {
	name = "VPN Blocker",
	author = "KoSSoLaX`",
	description = "Help to remove useless players",
	version = "1.0",
	url = "zaretti.be"
};

StringMap g_hScoring;
ArrayList g_hQueue;
bool g_bProcessing;

Handle g_hCvarScore;

public void OnPluginStart() {
	
	g_hScoring = new StringMap();
	g_hQueue = new ArrayList(16, 0);
	g_bProcessing = false;
	
	CreateTimer(QUEUE_SPEED, Timer_TICK, _, TIMER_REPEAT);
	
	g_hCvarScore = CreateConVar("sv_autoban_vpn_score", "0.95");
	AutoExecConfig();
}

public void OnClientPostAdminCheck(int client) {
	char tmp[16];
	float score;
	
	GetClientIP(client, tmp, sizeof(tmp));
	
	if( g_hScoring.GetValue(tmp, score) ) {
		if( score >= GetConVarFloat(g_hCvarScore) ) {
			BanClient(client, BAN_TIME, BANFLAG_IP, "VPN", "VPN are not allowed on this server");
		}
	}
	else {
		g_hQueue.PushString(tmp);
	}	
}
public Action Timer_TICK(Handle timer, any none) {
	static char tmp[16], URL[128];
	
	if( !g_bProcessing && g_hQueue.Length > 0 ) {
		g_hQueue.GetString(0, tmp, sizeof(tmp));
		g_hQueue.Erase(0);
		
		float score;
		if( !g_hScoring.GetValue(tmp, score) ) {
			Format(URL, sizeof(URL), SERVICE_URL, tmp);
			
			Handle dp = CreateDataPack();
			WritePackString(dp, tmp);
			
			g_bProcessing = true;		
			Handle req = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, URL);
			SteamWorks_SetHTTPCallbacks(req, OnSteamWorksHTTPComplete);
			SteamWorks_SendHTTPRequest(req);
		}
	}
}

public int OnSteamWorksHTTPComplete(Handle hRequest, bool fail, bool success, EHTTPStatusCode statusCode, any dp) {
	char IP[16], body[32];
	
	ResetPack(dp);
	ReadPackString(dp, IP, sizeof(IP));
	
	
	if( success && statusCode == k_EHTTPStatusCode200OK ) {
		SteamWorks_GetHTTPResponseBodyData(hRequest, body, sizeof(body));
		
		float score = StringToFloat(body);
		g_hScoring.SetValue(IP, score);
		
		
		if( score >= GetConVarFloat(g_hCvarScore) ) {
			for (int i = 1; i <= MaxClients; i++) {
				if( !IsClientInGame(i) )
					continue;
				
				GetClientIP(i, body, sizeof(body));
				
				if( StrEqual(IP, body) ) {
					BanClient(i, BAN_TIME, BANFLAG_IP, "VPN", "VPN are not allowed on this server");
				}
			}
		}
	}
	
	CloseHandle(hRequest);
	CloseHandle(dp);
	g_bProcessing = false;
}