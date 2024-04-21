Function PBod_Logic[2049] = { INVALID_FUNCTION, ... };

Handle PBod_Plugin[2049] = { null, ... };

bool PBod_Exists[2049] = { false, ... };
bool PBod_Fading[2049] = { false, ... };
bool FadeOutInitiated[2049] = { false, ... };

ArrayList PBod_Entities[2049] = { null, ... };

float PBod_EndTime[2049] = { 0.0, ... };
float PBod_FadeRate[2049] = { 0.0, ... };
float Light_Radius[2049] = { 0.0, ... };

int Light_Brightness[2049][4];
int Sprite_Alpha[2049] = { 0, ... };

public void PBod_MakeNatives()
{
	CreateNative("ParticleBody.ParticleBody", Native_MakeParticleBody);
	CreateNative("FPS_CreateParticleBody", Native_CreateParticleBody)
	
	CreateNative("ParticleBody.Index.get", Native_GetParticleBodyIndex);
	
	CreateNative("ParticleBody.End_Time.get", Native_GetPBodEndTime);
	CreateNative("ParticleBody.End_Time.set", Native_SetPBodEndTime);
	
	CreateNative("ParticleBody.Fade_Rate.get", Native_GetPBodFadeRate);
	CreateNative("ParticleBody.Fade_Rate.set", Native_SetPBodFadeRate);
	CreateNative("ParticleBody.Will_Fade.get", Native_GetPBodWillFade);
	CreateNative("ParticleBody.Fading.get", Native_GetParticleBodyFading);
	CreateNative("ParticleBody.Fading.set", Native_SetParticleBodyFading);
	
	CreateNative("ParticleBody.Logic.set", Native_SetPBodLogic);
	
	CreateNative("ParticleBody.Logic_Plugin.get", Native_GetPBodLogicPlugin);
	CreateNative("ParticleBody.Logic_Plugin.set", Native_SetPBodLogicPlugin);
	
	CreateNative("ParticleBody.Exists.get", Native_GetPBodExists);
	CreateNative("ParticleBody.Exists.set", Native_SetPBodExists);
	
	CreateNative("ParticleBody.Entities.get", Native_GetPBodEntities);
	CreateNative("ParticleBody.Entities.set", Native_SetPBodEntities);
	
	CreateNative("ParticleBody.Destroy", Native_DestroyParticleBody);
	
	CreateNative("ParticleBody.AddEntity", Native_AddEntityToPBod);
	CreateNative("ParticleBody.AddParticle", Native_AddParticleToPBod);
	CreateNative("ParticleBody.AddLight", Native_AddLightToPBod);
	CreateNative("ParticleBody.AddSprite", Native_AddSpriteToPBod);
	CreateNative("ParticleBody.AddTrail", Native_AddTrailToPBod);
}

public int Native_MakeParticleBody(Handle plugin, int numParams)
{
	Function logic = GetNativeCell(1);
	char pluginName[255];
	GetNativeString(2, pluginName, sizeof(pluginName));
	
	float pos[3], ang[3];
	GetNativeArray(3, pos, sizeof(pos));
	GetNativeArray(4, ang, sizeof(ang));
	float lifespan = GetNativeCell(5);
	float faderate = GetNativeCell(6);
	
	int ent = CreateEntityByName("info_target");
	if (!IsValidEntity(ent))
		return -1;
		
	//SetEntityModel(ent, MODEL_DEFAULT);
	DispatchKeyValue(ent, "spawnflags", "1");	
	DispatchSpawn(ent);
	ActivateEntity(ent);
	//SetEntityCollisionGroup(ent, 10);
	//SetEntityRenderMode(ent, RENDER_NONE);
	TeleportEntity(ent, pos, ang, NULL_VECTOR);
	//SetEntityMoveType(ent, MOVETYPE_NONE);
	
	PBod_Logic[ent] = logic;
	PBod_Plugin[ent] = GetPluginHandle(pluginName);
	PBod_Exists[ent] = true;
	PBod_FadeRate[ent] = faderate;
	FadeOutInitiated[ent] = false;
	
	if (lifespan > 0.0)
		lifespan += GetGameTime();
			
	PBod_EndTime[ent] = lifespan;
		
	RequestFrame(PBod_InternalLogic, EntIndexToEntRef(ent));
		
	return ent;
}

public any Native_CreateParticleBody(Handle plugin, int numParams)
{
	float pos[3], ang[3];
	GetNativeArray(1, pos, sizeof(pos));
	GetNativeArray(2, ang, sizeof(ang));
	
	float lifespan = GetNativeCell(3);
	char pluginName[255];
	GetNativeString(4, pluginName, sizeof(pluginName));
	Function logic = GetNativeFunction(5);
	float faderate = GetNativeCell(6);
	
	return new ParticleBody(logic, pluginName, pos, ang, lifespan, faderate);
}

public void PBod_InternalLogic(int ref)
{
	int index = EntRefToEntIndex(ref);
	if (!IsValidEntity(index))
		return;
		
	ParticleBody PBod = view_as<ParticleBody>(index);
	
	float gt = GetGameTime();
	bool FullyFaded = false;
	
	if (PBod.Fading)
	{
		if (FadeOutInitiated[PBod.Index])
			FullyFaded = PBod.Fade_Rate <= 0.0;
			
		if (!FullyFaded)
		{
			for (int i = 0; i < GetArraySize(PBod.Entities); i++)
			{
				int ent = EntRefToEntIndex(GetArrayCell(PBod.Entities, i));
				if (IsValidEntity(ent))
				{
					char classname[255];
					GetEntityClassname(ent, classname, sizeof(classname));
					
					if (StrEqual(classname, "light_dynamic"))
					{
						Light_Brightness[ent][3] -= RoundFloat(PBod.Fade_Rate);
						Light_Radius[ent] -= PBod.Fade_Rate;
						if (Light_Brightness[ent][3] <= 0 || Light_Radius[ent] <= 0.0)
						{
							RemoveEntity(ent);
							RemoveFromArray(PBod.Entities, i);
						}
						else
						{
							if (Light_Brightness[ent][3] > 255)
								Light_Brightness[ent][3] = 255;
								
							//char colorchar[32];
							//Format(colorchar, sizeof(colorchar), "%i %i %i %i", Light_Brightness[ent][0], Light_Brightness[ent][1], Light_Brightness[ent][2], Light_Brightness[ent][3]);
							//DispatchKeyValue(ent, "_light", colorchar);
							DispatchKeyValueFloat(ent, "distance", Light_Radius[ent]);
							DispatchSpawn(ent);
							SetEntPropFloat(ent, Prop_Send, "m_Radius", Light_Radius[ent]);
						}
					}
					else if (StrContains(classname, "env_sprite") != -1)
					{
						Sprite_Alpha[ent] -= RoundFloat(PBod.Fade_Rate);
						if (Sprite_Alpha[ent] <= 0)
						{
							RemoveEntity(ent);
							RemoveFromArray(PBod.Entities, i);
						}
						else
						{
							if (Sprite_Alpha[ent] > 255)
								Sprite_Alpha[ent] = 255;
								
							char alpha[255];
							IntToString(Sprite_Alpha[ent], alpha, sizeof(alpha));
							DispatchKeyValue(ent, "renderamt", alpha);
							DispatchSpawn(ent);
						}
					}
					else
					{
						int r, g, b, a;
						GetEntityRenderColor(ent, r, g, b, a);
						a -= RoundFloat(PBod.Fade_Rate);
						
						if (a <= 0)
						{
							RemoveEntity(ent);
							RemoveFromArray(PBod.Entities, i);
						}
						else
						{
							if (a > 255)
								a = 255;
								
							SetEntityRenderMode(ent, RENDER_TRANSALPHA);
							SetEntityRenderColor(ent, r, g, b, a);
						}
					}
				}
			}
			
			FullyFaded = GetArraySize(PBod.Entities) <= 0;
		}
	}
	
	if ((gt >= PBod.End_Time && PBod.End_Time > 0.0 && !FadeOutInitiated[PBod.Index]) || FullyFaded)
	{
		if (PBod.Will_Fade && PBod.Entities != null && !FadeOutInitiated[PBod.Index])
		{
			PBod.Fading = true;
			FadeOutInitiated[PBod.Index] = true;
		}
		else
		{
			RemoveEntity(index);
			return;
		}
	}
	
	if (PBod_Logic[index] != INVALID_FUNCTION && PBod.Logic_Plugin != null)
	{
		Call_StartFunction(PBod.Logic_Plugin, PBod_Logic[index]);
		Call_PushCell(PBod.Index);
		Call_Finish();
	}
	
	RequestFrame(PBod_InternalLogic, ref);
}

public int Native_GetParticleBodyIndex(Handle plugin, int numParams)
{
	return GetNativeCell(1);
}

public any Native_GetPBodEndTime(Handle plugin, int numParams)
{
	return PBod_EndTime[GetNativeCell(1)];
}

public int Native_SetPBodEndTime(Handle plugin, int numParams)
{
	PBod_EndTime[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetPBodWillFade(Handle plugin, int numParams)
{
	return PBod_FadeRate[GetNativeCell(1)] > 0.0;
}

public any Native_GetPBodFadeRate(Handle plugin, int numParams)
{
	return PBod_FadeRate[GetNativeCell(1)];
}

public int Native_SetPBodFadeRate(Handle plugin, int numParams)
{
	PBod_FadeRate[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public int Native_SetPBodLogic(Handle plugin, int numParams)
{
	PBod_Logic[GetNativeCell(1)] = GetNativeFunction(2);
	return 0;
}

public any Native_GetPBodLogicPlugin(Handle plugin, int numParams)
{
	return PBod_Plugin[GetNativeCell(1)];
}

public int Native_SetPBodLogicPlugin(Handle plugin, int numParams)
{
	PBod_Plugin[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetPBodExists(Handle plugin, int numParams)
{
	return PBod_Exists[GetNativeCell(1)];
}

public int Native_SetPBodExists(Handle plugin, int numParams)
{
	PBod_Exists[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetPBodEntities(Handle plugin, int numParams)
{
	return PBod_Entities[GetNativeCell(1)];
}

public int Native_SetPBodEntities(Handle plugin, int numParams)
{
	PBod_Entities[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public int Native_DestroyParticleBody(Handle plugin, int numParams)
{
	ParticleBody PBod = view_as<ParticleBody>(GetNativeCell(1));
	
	PBod.Logic = INVALID_FUNCTION;
	PBod.Logic_Plugin = null;
	PBod.End_Time = 0.0;
	
	if (PBod.Entities != null)
	{
		for (int i = 0; i < GetArraySize(PBod.Entities); i++)
		{
			int ent = EntRefToEntIndex(GetArrayCell(PBod.Entities, i));
			if (IsValidEntity(ent))
				RemoveEntity(ent);
		}
		
		delete PBod.Entities;
	}
	
	return 0;
}

public any Native_GetParticleBodyFading(Handle plugin, int numParams)
{
	return PBod_Fading[GetNativeCell(1)];
}

public int Native_SetParticleBodyFading(Handle plugin, int numParams)
{	
	PBod_Fading[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public int Native_AddEntityToPBod(Handle plugin, int numParams)
{
	int PBod = GetNativeCell(1);
	int entity = GetNativeCell(2);
	float lifespan = GetNativeCell(3);
	Function logic = GetNativeFunction(4);
	char pluginName[255];
	GetNativeString(5, pluginName, sizeof(pluginName));
	
	//Parent the entity to the PBod:
	float pos[3], ang[3];
	GetEntPropVector(PBod, Prop_Data, "m_vecOrigin", pos);
	GetEntPropVector(PBod, Prop_Send, "m_angRotation", ang);
	
	char classname[255];
	GetEntityClassname(entity, classname, sizeof(classname));
	if (StrEqual(classname, "env_sprite"))
	{
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		
		DataPack pack = new DataPack();
		WritePackCell(pack, EntIndexToEntRef(PBod));
		WritePackCell(pack, EntIndexToEntRef(entity));
		RequestFrame(PBod_MoveSprite, pack);
	}
	else
	{
		TeleportEntity(entity, pos, ang, NULL_VECTOR);
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", PBod, entity);
	}
	
	//If we have a lifespan or custom logic, create the RequestFrame:
	bool AtLeastOne = false;
	if (lifespan > 0.0)
	{
		lifespan += GetGameTime();
		AtLeastOne = true;
	}
		
	Handle pluginHandle = GetPluginHandle(pluginName);
	if (pluginHandle != null)
		AtLeastOne = true;
		
	if (AtLeastOne)
	{
		DataPack pack = new DataPack();
		WritePackCell(pack, EntIndexToEntRef(entity));
		WritePackFloat(pack, lifespan);
		WritePackFunction(pack, logic);
		WritePackCell(pack, pluginHandle);
		
		RequestFrame(PBod_PartLogic, pack);
	}
	
	ParticleBody body = view_as<ParticleBody>(PBod);
	if (body.Entities == null)
		body.Entities = new ArrayList(255);
		
	PushArrayCell(body.Entities, EntIndexToEntRef(entity));
	
	return 0;
}

//I have absolutely no idea why, but parenting a sprite to the PBody just causes the sprite to erase itself.
//This is probably not the *optimal* way to do this but I do not care.
public void PBod_MoveSprite(DataPack pack)
{
	ResetPack(pack);
	int PBod = EntRefToEntIndex(ReadPackCell(pack));
	int entity = EntRefToEntIndex(ReadPackCell(pack));
	
	if (!IsValidEntity(PBod) || !IsValidEntity(entity))
	{
		delete pack;
		return;
	}
	
	float pos[3];
	GetEntPropVector(PBod, Prop_Data, "m_vecAbsOrigin", pos);
	
	int frame = GetEntProp(entity, Prop_Send, "m_ubInterpolationFrame");

	TeleportEntity(entity, pos);
	
	SetEntProp(entity, Prop_Send, "m_ubInterpolationFrame", frame);
	
	RequestFrame(PBod_MoveSprite, pack);
}

public void PBod_PartLogic(DataPack pack)
{
	ResetPack(pack);
	int entity = EntRefToEntIndex(ReadPackCell(pack));
	float endTime = ReadPackFloat(pack);
	Function logic = ReadPackFunction(pack);
	Handle plugin = ReadPackCell(pack);
	
	if (!IsValidEntity(entity))
	{
		delete pack;
		return;
	}
	
	if (GetGameTime() >= endTime && endTime > 0.0)
	{
		RemoveEntity(entity);
		delete pack;
		return;
	}
	
	if (logic != INVALID_FUNCTION && plugin != null)
	{
		Call_StartFunction(plugin, logic);
		Call_PushCell(entity);
		Call_Finish();
	}
	
	RequestFrame(PBod_PartLogic, pack);
}

public int Native_AddParticleToPBod(Handle plugin, int numParams)
{
	ParticleBody PBod = view_as<ParticleBody>(GetNativeCell(1));
	
	char pluginName[255], particleName[255];
	GetNativeString(2, particleName, sizeof(particleName));
	float lifespan = GetNativeCell(3);
	Function logic = GetNativeFunction(4);
	GetNativeString(5, pluginName, sizeof(pluginName));
	
	int particle = SpawnParticle(NULL_VECTOR, particleName);
	if (IsValidEntity(particle))
	{
		PBod.AddEntity(particle, lifespan, logic, pluginName);
		return particle;
	}
	
	return -1;
}

public int Native_AddLightToPBod(Handle plugin, int numParams)
{
	ParticleBody PBod = view_as<ParticleBody>(GetNativeCell(1));
	
	int light = CreateEntityByName("light_dynamic");
	if (IsValidEntity(light))
	{
		int color[4];
		GetNativeArray(2, color, sizeof(color));
		int brightness = GetNativeCell(3);
		float distance = GetNativeCell(4);
		int inner = GetNativeCell(5);
		int outer = GetNativeCell(6);
		float spotRad = GetNativeCell(7);
		int appearance = GetNativeCell(8);
		int flags = GetNativeCell(9);
		float lifespan = GetNativeCell(10);
		Function logic = GetNativeFunction(11);
		char pluginName[255];
		GetNativeString(12, pluginName, sizeof(pluginName));
		
		char colorchar[32];
		Format(colorchar, sizeof(colorchar), "%i %i %i %i", color[0], color[1], color[2], color[3]);
		DispatchKeyValue(light, "_light", colorchar);
		
		DispatchKeyValueInt(light, "brightness", brightness);
		DispatchKeyValueFloat(light, "distance", distance);
		DispatchKeyValueInt(light, "_inner_cone", inner);
		DispatchKeyValueInt(light, "_cone", outer);
		DispatchKeyValueFloat(light, "spotlight_radius", spotRad);
		DispatchKeyValueInt(light, "style", appearance);
		SetEntProp(light, Prop_Data, "m_fFlags", flags);
		
		Light_Brightness[light][0] = color[0];
		Light_Brightness[light][1] = color[1];
		Light_Brightness[light][2] = color[2];
		Light_Brightness[light][3] = color[3];
		Light_Radius[light] = distance;
		
		DispatchSpawn(light);
		ActivateEntity(light);
		
		PBod.AddEntity(light, lifespan, logic, pluginName);
		return light;
	}
	
	return -1;
}

public int Native_AddSpriteToPBod(Handle plugin, int numParams)
{
	ParticleBody PBod = view_as<ParticleBody>(GetNativeCell(1));
	
	int sprite = CreateEntityByName("env_sprite");
	if (IsValidEntity(sprite))
	{
		char name[255], pluginName[255];
		GetNativeString(2, name, sizeof(name));
		float scale = GetNativeCell(3);
		int color[3];
		GetNativeArray(4, color, sizeof(color));
		int alpha = GetNativeCell(5);
		RenderMode render = GetNativeCell(6);
		int framerate = GetNativeCell(7);
		float startframe = GetNativeCell(8);
		float lifespan = GetNativeCell(9);
		Function logic = GetNativeFunction(10);
		GetNativeString(11, pluginName, sizeof(pluginName));
		
		DispatchKeyValue(sprite, "model", name);
		DispatchKeyValueFloat(sprite, "scale", scale);
		
		SetEntityRenderColor(sprite, color[0], color[1], color[2], alpha);
		SetEntityRenderMode(sprite, render);
		
		DispatchKeyValueInt(sprite, "framerate", framerate);
		DispatchKeyValueFloat(sprite, "frame", startframe);
		
		DispatchKeyValue(sprite, "spawnflags", "1");
		DispatchKeyValue(sprite, "rendermode", "1");
		
		DispatchSpawn(sprite);
		ActivateEntity(sprite);
		
		Sprite_Alpha[sprite] = alpha;
		
		AcceptEntityInput(sprite, "ShowSprite");
		
		PBod.AddEntity(sprite, lifespan, logic, pluginName);
		return sprite;
	}
	
	return -1;
}

public int Native_AddTrailToPBod(Handle plugin, int numParams)
{
	ParticleBody PBod = view_as<ParticleBody>(GetNativeCell(1));
	
	int trail = CreateEntityByName("env_spritetrail");
	if (IsValidEntity(trail))
	{
		char name[255], pluginName[255];
		GetNativeString(2, name, sizeof(name));
		float length = GetNativeCell(3);
		float startWidth = GetNativeCell(4);
		float endWidth = GetNativeCell(5);
		int color[3];
		GetNativeArray(6, color, sizeof(color));
		int alpha = GetNativeCell(7);
		RenderMode render = GetNativeCell(8);
		int renderfx = GetNativeCell(9);
		float lifespan = GetNativeCell(10);
		Function logic = GetNativeFunction(11);
		GetNativeString(12, pluginName, sizeof(pluginName));
		
		DispatchKeyValue(trail, "spritename", name);
		
		DispatchKeyValueFloat(trail, "startwidth", startWidth);
		DispatchKeyValueFloat(trail, "endwidth", endWidth);
		DispatchKeyValueFloat(trail, "lifetime", length);
		
		SetEntityRenderColor(trail, color[0], color[1], color[2], alpha);
		SetEntityRenderMode(trail, render);
		
		DispatchKeyValueInt(trail, "renderfx", renderfx);
		
		DispatchSpawn(trail);
		ActivateEntity(trail);
		
		Sprite_Alpha[trail] = alpha;
		
		SetEntPropFloat(trail, Prop_Send, "m_flTextureRes", 0.05); 
		
		PBod.AddEntity(trail, lifespan, logic, pluginName);
		return trail;
	}
	
	return -1;
}