#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <entity>
#include <cfgmap>

float OFF_THE_MAP[3] = {1182792704.0, 1182792704.0, -964690944.0};

stock bool IsValidClient(int client)
{
	if(client <= 0 || client > MaxClients)
	{
		return false;
	}
	
	if(!IsClientInGame(client))
	{
		return false;
	}

	return true;
}

stock Handle getAimTrace(int client, TraceEntityFilter filter)
{
	float eyePos[3];
	float eyeAng[3];
	GetClientEyePosition(client, eyePos);
	GetClientEyeAngles(client, eyeAng);
	
	Handle trace;
	
	trace = TR_TraceRayFilterEx(eyePos, eyeAng, MASK_SHOT, RayType_Infinite, filter);
	
	return trace;
}

public bool Trace_OnlyHitWorld(entity, contentsMask)
{
	return entity == 0;
}

stock int GetIntFromConfigMap(ConfigMap map, char[] path, int defaultValue)
{
	char value[255];
	map.Get(path, value, sizeof(value));
	
	if (StrEqual(value, ""))
	{
		return defaultValue;
	}
	
	return StringToInt(value);
}

stock float GetFloatFromConfigMap(ConfigMap map, char[] path, float defaultValue)
{
	char value[255];
	map.Get(path, value, sizeof(value));
	
	if (StrEqual(value, ""))
	{
		return defaultValue;
	}
	
	return StringToFloat(value);
}

stock bool GetBoolFromConfigMap(ConfigMap map, char[] path, bool defaultValue)
{
	char value[255];
	map.Get(path, value, sizeof(value));
	
	if (StrEqual(value, ""))
	{
		return defaultValue;
	}
	
	return (StringToInt(value) != 0);
}

stock bool CheckFile(char path[255])
{
	bool exists = false;
	
	if (FileExists(path))
	{
		exists = true;
	}
	else
	{
		if (FileExists(path, true))
		{
			exists = true;
		}
	}
	
	return exists;
}

public Action Timer_RemoveEntity(Handle Timer_RemoveEntity, int entityId)
{
	int entity = EntRefToEntIndex(entityId);
	if (IsValidEntity(entity) && entity > MaxClients)
	{
		TeleportEntity(entity, OFF_THE_MAP, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "Kill");
		RemoveEntity(entity);
	}
	return Plugin_Continue;
}

stock void AddInFrontOf(float fVecOrigin[3], float fVecAngle[3], float fUnits, float fOutPut[3])
{
	float fVecView[3]; GetViewVector(fVecAngle, fVecView);
	
	fOutPut[0] = fVecView[0] * fUnits + fVecOrigin[0];
	fOutPut[1] = fVecView[1] * fUnits + fVecOrigin[1];
	fOutPut[2] = fVecView[2] * fUnits + fVecOrigin[2];
}

stock void GetViewVector(float fVecAngle[3], float fOutPut[3])
{
	fOutPut[0] = Cosine(fVecAngle[1] / (180 / FLOAT_PI));
	fOutPut[1] = Sine(fVecAngle[1] / (180 / FLOAT_PI));
	fOutPut[2] = -Sine(fVecAngle[0] / (180 / FLOAT_PI));
}