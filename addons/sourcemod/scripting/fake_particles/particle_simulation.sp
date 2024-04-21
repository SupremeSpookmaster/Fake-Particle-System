Function PSim_Logic[2049] = { INVALID_FUNCTION, ... };

Handle PSim_Plugin[2049] = { null, ... };

float PSim_EndTime[2049] = { 0.0, ... };

bool PSim_EraseBodies[2049] = { false, ... };
bool PSim_Exists[2049] = { false, ... };

int PSim_MaxEnts[2049] = { 0, ... };

Queue PSim_Bodies[2049] = { null, ... };

public void PSim_MakeNatives()
{
	CreateNative("ParticleSimulation.ParticleSimulation", Native_MakeParticleSimulation);
	CreateNative("ParticleSimulation.Destroy", Native_DestroyParticleSimulation);
	CreateNative("ParticleSimulation.Index.get", Native_GetParticleSimulationIndex);
	
	CreateNative("ParticleSimulation.Max_Entities.get", Native_GetPSimMaxEntities);
	CreateNative("ParticleSimulation.Max_Entities.set", Native_SetPSimMaxEntities);
	
	CreateNative("ParticleSimulation.End_Time.get", Native_GetPSimEndTime);
	CreateNative("ParticleSimulation.End_Time.set", Native_SetPSimEndTime);
	
	CreateNative("ParticleSimulation.Logic.set", Native_SetPSimLogic);
	
	CreateNative("ParticleSimulation.Logic_Plugin.get", Native_GetPSimLogicPlugin);
	CreateNative("ParticleSimulation.Logic_Plugin.set", Native_SetPSimLogicPlugin);
	
	CreateNative("ParticleSimulation.AttachToEntity", Native_AttachPSim);
	CreateNative("ParticleSimulation.DetachFromEntity", Native_DetachPSim);
	
	CreateNative("ParticleSimulation.Erase_Bodies_On_End.get", Native_GetPSimErase);
	CreateNative("ParticleSimulation.Erase_Bodies_On_End.set", Native_SetPSimErase);
	
	CreateNative("ParticleSimulation.Exists.get", Native_GetPSimExists);
	CreateNative("ParticleSimulation.Exists.set", Native_SetPSimExists);
	
	CreateNative("ParticleSimulation.PBodies.get", Native_GetPSimBodies);
	CreateNative("ParticleSimulation.PBodies.set", Native_SetPSimBodies);
	
	CreateNative("FPS_CreateParticleSimulation", Native_CreateParticleSimulation);
	
	CreateNative("ParticleSimulation.AddParticleBody", Native_AddPBody);
}

public void PSim_InternalLogic(int ref)
{
	int index = EntRefToEntIndex(ref);
	if (!IsValidEntity(index))
		return;
		
	ParticleSimulation PSim = view_as<ParticleSimulation>(index);
	
	float gt = GetGameTime();
	if (gt >= PSim.End_Time && PSim.End_Time > 0.0)
	{		
		RemoveEntity(index);
		return;
	}
	
	if (PSim_Logic[index] != INVALID_FUNCTION && PSim.Logic_Plugin != null)
	{
		Call_StartFunction(PSim.Logic_Plugin, PSim_Logic[index]);
		Call_PushCell(PSim.Index);
		Call_Finish();
	}
	
	RequestFrame(PSim_InternalLogic, ref);
}

public int Native_MakeParticleSimulation(Handle plugin, int numParams)
{
	Function logic = GetNativeCell(1);
	char pluginName[255];
	GetNativeString(2, pluginName, sizeof(pluginName));
	
	float pos[3], ang[3];
	GetNativeArray(3, pos, sizeof(pos));
	GetNativeArray(4, ang, sizeof(ang));
	int maxEnts = GetNativeCell(5);
	float lifespan = GetNativeCell(6);
	bool eraseOnEnd = GetNativeCell(7);
	
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
		
	PSim_Logic[ent] = logic;
	PSim_Plugin[ent] = GetPluginHandle(pluginName);
	PSim_MaxEnts[ent] = maxEnts;
	PSim_EraseBodies[ent] = eraseOnEnd;
	PSim_Exists[ent] = true;
		
	if (lifespan > 0.0)
		lifespan += GetGameTime();
			
	PSim_EndTime[ent] = lifespan;
		
	RequestFrame(PSim_InternalLogic, EntIndexToEntRef(ent));
		
	return ent;
}

public any Native_CreateParticleSimulation(Handle plugin, int numParams)
{
	float pos[3], ang[3];
	char pluginName[255];
	
	GetNativeArray(1, pos, sizeof(pos));
	GetNativeArray(2, ang, sizeof(ang));
	int maxEnts = GetNativeCell(3);
	float lifespan = GetNativeCell(4);
	GetNativeString(5, pluginName, sizeof(pluginName));
	Function logic = GetNativeFunction(6);
	bool eraseOnEnd = GetNativeCell(7);
	
	return new ParticleSimulation(logic, pluginName, pos, ang, maxEnts, lifespan, eraseOnEnd);
}

public int Native_DestroyParticleSimulation(Handle plugin, int numParams)
{
	int entity = GetNativeCell(1);
	
	ParticleSimulation PSim = view_as<ParticleSimulation>(entity);
	
	if (PSim.PBodies != null)
	{
		while (!PSim.PBodies.Empty)
		{
			int ent = EntRefToEntIndex(PSim.PBodies.Pop());
			if (IsValidEntity(ent))
			{
				ParticleBody PBod = view_as<ParticleBody>(ent);
				
				if (!PSim.Erase_Bodies_On_End || PBod.Will_Fade)
				{
					SetVariantString("!activator");
					AcceptEntityInput(ent, "SetParent", ent, ent);
					if (PBod.Will_Fade)
						PBod.Fading = true;
				}
				else
				{
					RemoveEntity(ent);
				}
			}
		}
	}
	
	//TODO: Call forward
	
	PSim_Logic[entity] = INVALID_FUNCTION;
	PSim_Plugin[entity] = null;
	PSim_MaxEnts[entity] = 0;
	PSim_EndTime[entity] = 0.0;
	PSim_EraseBodies[entity] = false;
	delete PSim_Bodies[entity];
	
	return 0;
}

public int Native_GetParticleSimulationIndex(Handle plugin, int numParams)
{
	return GetNativeCell(1);
}

public int Native_GetPSimMaxEntities(Handle plugin, int numParams)
{
	return PSim_MaxEnts[GetNativeCell(1)];
}

public int Native_SetPSimMaxEntities(Handle plugin, int numParams)
{
	PSim_MaxEnts[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetPSimEndTime(Handle plugin, int numParams)
{
	return PSim_EndTime[GetNativeCell(1)];
}

public int Native_SetPSimEndTime(Handle plugin, int numParams)
{
	PSim_EndTime[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetPSimErase(Handle plugin, int numParams)
{
	return PSim_EraseBodies[GetNativeCell(1)];
}

public int Native_SetPSimErase(Handle plugin, int numParams)
{
	PSim_EraseBodies[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetPSimExists(Handle plugin, int numParams)
{
	return PSim_Exists[GetNativeCell(1)];
}

public int Native_SetPSimExists(Handle plugin, int numParams)
{
	PSim_Exists[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public any Native_GetPSimBodies(Handle plugin, int numParams)
{
	return PSim_Bodies[GetNativeCell(1)];
}

public int Native_SetPSimBodies(Handle plugin, int numParams)
{
	PSim_Bodies[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public int Native_SetPSimLogic(Handle plugin, int numParams)
{
	PSim_Logic[GetNativeCell(1)] = GetNativeFunction(2);
	return 0;
}

public any Native_GetPSimLogicPlugin(Handle plugin, int numParams)
{
	return PSim_Plugin[GetNativeCell(1)];
}

public int Native_SetPSimLogicPlugin(Handle plugin, int numParams)
{
	PSim_Plugin[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public int Native_AttachPSim(Handle plugin, int numParams)
{
	int PSim = GetNativeCell(1);
	int target = GetNativeCell(2);
	char attachment[255];
	GetNativeString(3, attachment, sizeof(attachment));
	float xOff = GetNativeCell(4);
	float yOff = GetNativeCell(5);
	float zOff = GetNativeCell(6);
	
	float pos[3];
	if (HasEntProp(target, Prop_Data, "m_vecAbsOrigin"))
	{
		GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", pos);
	}
	else if (HasEntProp(target, Prop_Send, "m_vecOrigin"))
	{
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
	}
			
	pos[0] += xOff;
	pos[1] += yOff;
	pos[2] += zOff;
	
	TeleportEntity(PSim, pos, NULL_VECTOR, NULL_VECTOR);
	
	SetVariantString("!activator");
	AcceptEntityInput(PSim, "SetParent", target, PSim);
	
	if (!StrEqual(attachment, ""))
	{
		SetVariantString(attachment);
		AcceptEntityInput(PSim, "SetParentAttachmentMaintainOffset", PSim, PSim);
	}
	
	return 0;
}

public int Native_DetachPSim(Handle plugin, int numParams)
{
	int PSim = GetNativeCell(1);
	
	SetVariantString("!activator");
	AcceptEntityInput(PSim, "SetParent", PSim, PSim);
	
	return 0;
}

public int Native_AddPBody(Handle plugin, int numParams)
{
	int owner = GetNativeCell(1);
	ParticleSimulation PSim = view_as<ParticleSimulation>(owner);
	
	int entity = GetNativeCell(2);
	
	bool parent = GetNativeCell(3);
	
	if (parent)
	{
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", owner, entity);
	}
	
	if (PSim.PBodies == null)
		PSim.PBodies = new Queue();
		
	PSim.PBodies.Push(EntIndexToEntRef(entity));
		
	if (PSim.Max_Entities > 0)
	{	
		while (PSim.PBodies.Length > PSim.Max_Entities)
		{
			int ent = EntRefToEntIndex(PSim.PBodies.Pop());
			if (IsValidEntity(ent))
			{
				ParticleBody PBod = view_as<ParticleBody>(ent);
				if (PBod.Will_Fade)
					PBod.Fading = true;
				else
					RemoveEntity(ent);
			}
		}
	}
	
	return 0;
}