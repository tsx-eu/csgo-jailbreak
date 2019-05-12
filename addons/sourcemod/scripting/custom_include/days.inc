#if defined _days_included
#endinput
#endif
#define _days_included

#define DAYS_PREFIX "[Days]"
#define DEFAULT_TIME 60*3

forward void Days_OnPluginStart();

native void Days_Register(char[] name, char[] id, char[] desc, int time = DEFAULT_TIME, eventDays start = INVALID_FUNCTION, eventDays end = INVALID_FUNCTION);
native bool Days_IsActive(char[] id);

typeset eventDays {
	function void();
}