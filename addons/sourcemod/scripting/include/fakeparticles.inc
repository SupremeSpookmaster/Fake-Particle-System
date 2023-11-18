#if defined _fps_included_
  #endinput
#endif
#define _fps_included_

stock bool IsPlayerInvis(int client)
{
	if (!IsValidClient(client))
		return false;
		
	//Check for empty model:
	char model[255];
	GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
	
	if (StrContains(model, "empty.mdl") != -1)
		return true;
		
	//Check for zero alpha:
	int r, g, b, a;
	GetEntityRenderColor(client, r, g, b, a);
	if (a == 0)
		return true;
	
	//Check for RENDERFX_NONE and TF2's invisibility conditions:
	return GetEntityRenderMode(client) == RENDER_NONE || TF2_IsPlayerInCondition(client, TFCond_Cloaked) || TF2_IsPlayerInCondition(client, TFCond_Stealthed) || TF2_IsPlayerInCondition(client, TFCond_StealthedUserBuffFade);
}

enum FPS_ParticleType
{
	FPS_ParticleType_None = -1,
	FPS_ParticleType_Normal,
	FPS_ParticleType_Billboard
};

FakeParticleEffect ActiveEffects[2049];

enum struct FakeParticleEffect
{
	int EntIndex;
	int BillboardTarget;
	
	bool BBX;
	bool BBY;
	bool BBZ;
	
	FPS_ParticleType Type;
	
	void Create(int newIndex, FPS_ParticleType newType, int target = 0, bool xRot = true, bool yRot = true, bool zRot = true)
	{
		this.EntIndex = newIndex;
		this.Type = newType;
		if (IsValidClient(target))
			this.BillboardTarget = GetClientUserId(target);
		
		SDKHook(this.EntIndex, SDKHook_SetTransmit, FPE_Transmit);
		SetEdictFlags(this.EntIndex, GetEdictFlags(this.EntIndex)&(~FL_EDICT_ALWAYS));
		
		if (this.Type == FPS_ParticleType_Billboard)
		{
			this.BBX = xRot;
			this.BBY = yRot;
			this.BBZ = zRot;
		}
	}
	
	void Remove()
	{
		if (IsValidEntity(this.EntIndex))
		{
			RemoveEntity(this.EntIndex);
		}
		
		this.Delete();
	}
	
	void Delete()
	{
		this.EntIndex = -1;
		this.BillboardTarget = -1;
		this.Type = FPS_ParticleType_None;
		//TODO: Call FPS_OnFakeParticleRemoved
	}
}

public Action FPE_Transmit(int entity, int client)
{
 	SetEdictFlags(entity, GetEdictFlags(entity)&(~FL_EDICT_ALWAYS));
 	
 	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
 	
 	if (IsPlayerInvis(owner) || (client == owner && (!GetEntProp(client, Prop_Send, "m_nForceTauntCam") && !TF2_IsPlayerInCondition(client, TFCond_Taunting))))
 	{
 		return Plugin_Handled;
 	}
 	
 	if (ActiveEffects[entity].Type == FPS_ParticleType_Billboard)
 	{
	 	int target = GetClientOfUserId(ActiveEffects[entity].BillboardTarget);
	 	if (client != target)
	 	{
	 		return Plugin_Handled;
	 	}
	 	
	 	//Orient the entity to always face directly at the target's eyes:
		float ang[3], pos[3], eyePos[3], DummyAngles[3], fVecFinal[3], fFinalPos[3], currentAng[3];
		GetClientEyePosition(target, eyePos);
		GetClientEyeAngles(target, DummyAngles);
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		GetEntPropVector(entity, Prop_Send, "m_angRotation", ang);	
		
		AddInFrontOf(eyePos, DummyAngles, 7.0, fVecFinal);
		MakeVectorFromPoints(pos, fVecFinal, fFinalPos);
	
		GetVectorAngles(fFinalPos, ang);
		
		GetEntPropVector(entity, Prop_Data, "m_angRotation", currentAng); 
	 	
	 	ang[0] = ActiveEffects[entity].BBX ? ang[0] : currentAng[0];
	 	ang[1] = ActiveEffects[entity].BBY ? ang[1] : currentAng[1];
	 	ang[2] = ActiveEffects[entity].BBZ ? ang[2] : currentAng[2];
	 	
	 	TeleportEntity(entity, NULL_VECTOR, ang, NULL_VECTOR);
	 }
 	
 	return Plugin_Continue;
}

/**
 * Spawns a model at the given coordinates. Intended to be used to spawn fake particle effects.
 *
 * @param pos		The position at which to spawn the fake particle effect.
 * @param ang		The angles with which the fake particle effect should be spawned.
 * @param particle	The model name of the fake particle effect.
 * @param skin		Model skin to use for the fake particle effect.
 * @param sequence	Optional sequence for the fake particle effect to use.
 * @param rate		Optional playback rate for the fake particle effect's sequence to use, if a sequence is assigned.
 * @param duration	Optional duration of the fake particle effect. 0.0 or below: infinite.
 * @param r			Optional render color parameter for the fake particle effect to use, R value, 0-255.
 * @param g			Optional render color parameter for the fake particle effect to use, G value, 0-255.
 * @param b			Optional render color parameter for the fake particle effect to use, B value, 0-255.
 * @param alpha		Optional render color parameter for the fake particle effect to use, alpha value, 0-255.
 * @param scale		Optional model scale for the fake particle effect.
 *
 * @return The entity index of the fake particle effect which was spawned.
 * @error  The model passed to the ''particle'' parameter does not exist.
 */
native int FPS_SpawnFakeParticle(float pos[3], float ang[3], char particle[255], int skin, char sequence[255] = "ref", float rate = 1.0, float duration = 0.0, int r = 255, int g = 255, int b = 255, int alpha = 255, float scale = 1.0);

/**
 * Attaches a model to a given entity. Intended to be used to attach fake particle effects to entities.
 *
 * @param entity	The entity to attach the fake particle effect to.
 * @param point		The attachment point to attach the fake particle effect to.
 * @param particle	The model name of the fake particle effect.
 * @param skin		Model skin to use for the fake particle effect.
 * @param sequence	Optional sequence for the fake particle effect to use.
 * @param rate		Optional playback rate for the fake particle effect's sequence to use, if a sequence is assigned.
 * @param duration	Optional duration of the fake particle effect. 0.0 or below: infinite.
 * @param r			Optional render color parameter for the fake particle effect to use, R value, 0-255.
 * @param g			Optional render color parameter for the fake particle effect to use, G value, 0-255.
 * @param b			Optional render color parameter for the fake particle effect to use, B value, 0-255.
 * @param alpha		Optional render color parameter for the fake particle effect to use, alpha value, 0-255.
 * @param scale		Optional model scale for the fake particle effect.
 * @param posOffset	Optional positional offset.
 * @param angOffset Optional angle offset.
 *
 * @return The entity index of the fake particle effect which was attached.
 * @error  Invalid entity index passed to the ''entity'' parameter, or the model passed to the ''particle'' parameter does not exist. 
 */
native int FPS_AttachFakeParticleToEntity(int entity, char point[255], char particle[255], int skin, char sequence[255] = "ref", float rate = 1.0, float duration = 0.0, int r = 255, int g = 255, int b = 255, int alpha = 255, float scale = 1.0, float posOffset[3] = NULL_VECTOR, float angOffset[3] = NULL_VECTOR);

/**
 * Spawns a unique model at the given coordinates for every client, which faces its target client at all times. It's like a sprite, but more customizable.
 * Example: if you've ever played Super Mario 64, this does what the trees in the starting area do, for *every* client.
 * As such, billboard particles are VERY expensive on the entity limit and should be used sparingly.
 *
 * @param pos		The position at which to spawn the fake particle effect.
 * @param particle	The model name of the fake particle effect.
 * @param skin		Model skin to use for the fake particle effect.
 * @param sequence	Optional sequence for the fake particle effect to use.
 * @param rate		Optional playback rate for the fake particle effect's sequence to use, if a sequence is assigned.
 * @param duration	Optional duration of the fake particle effect. 0.0 or below: infinite.
 * @param r			Optional render color parameter for the fake particle effect to use, R value, 0-255.
 * @param g			Optional render color parameter for the fake particle effect to use, G value, 0-255.
 * @param b			Optional render color parameter for the fake particle effect to use, B value, 0-255.
 * @param alpha		Optional render color parameter for the fake particle effect to use, alpha value, 0-255.
 * @param scale		Optional model scale for the fake particle effect.
 * @param xRot		Should this billboard particle turn to face its client on the X axis?
 * @param yRot		Should this billboard particle turn to face its client on the Y axis?
 * @param zRot		Should this billboard particle turn to face its client on the Z axis?
 *
 * @return An array handle containing the entity references of every model spawned by this method. DELETE THIS HANDLE WHEN YOU ARE DONE WITH IT, EVEN IF YOU DO NOT USE IT AT ALL!
 * @error  The model passed to the ''particle'' parameter does not exist.
 */
native Handle FPS_SpawnBillboardParticle(float pos[3], char particle[255], int skin, char sequence[255] = "ref", float rate = 1.0, float duration = 0.0, int r = 255, int g = 255, int b = 255, int alpha = 255, float scale = 1.0, bool xRot = true, bool yRot = true, bool zRot = true);

/**
 * Functions the same as FPS_SpawnBillboardParticle, but with the added functionality of allowing you to attach the model to a given entity.
 *
 * @param entity	The entity to attach the fake particle effect to.
 * @param point		The attachment point to attach the fake particle effect to.
 * @param particle	The model name of the fake particle effect.
 * @param skin		Model skin to use for the fake particle effect.
 * @param sequence	Optional sequence for the fake particle effect to use.
 * @param rate		Optional playback rate for the fake particle effect's sequence to use, if a sequence is assigned.
 * @param duration	Optional duration of the fake particle effect. 0.0 or below: infinite.
 * @param r			Optional render color parameter for the fake particle effect to use, R value, 0-255.
 * @param g			Optional render color parameter for the fake particle effect to use, G value, 0-255.
 * @param b			Optional render color parameter for the fake particle effect to use, B value, 0-255.
 * @param alpha		Optional render color parameter for the fake particle effect to use, alpha value, 0-255.
 * @param scale		Optional model scale for the fake particle effect.
 * @param xRot		Should this billboard particle turn to face its client on the X axis?
 * @param yRot		Should this billboard particle turn to face its client on the Y axis?
 * @param zRot		Should this billboard particle turn to face its client on the Z axis?
 * @param posOffset	Optional positional offset.
 *
 * @return An array handle containing the entity references of every model spawned by this method. DELETE THIS HANDLE WHEN YOU ARE DONE WITH IT, EVEN IF YOU DO NOT USE IT AT ALL!
 * @error  Invalid entity index passed to the ''entity'' parameter, or the model passed to the ''particle'' parameter does not exist. 
 */
native Handle FPS_AttachBillboardParticleToEntity(int entity, char point[255], char particle[255], int skin, char sequence[255] = "ref", float rate = 1.0, float duration = 0.0, int r = 255, int g = 255, int b = 255, int alpha = 255, float scale = 1.0, bool xRot = true, bool yRot = true, bool zRot = true, float posOffset[3] = NULL_VECTOR);