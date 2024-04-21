#if defined _fps_included_
  #endinput
#endif
#define _fps_included_

/*stock bool IsPlayerInvis(int client)
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
}*/

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

methodmap ParticleBody __nullable__
{
	/**
	 * Creates a new particle body, to be added to a ParticleSimulation.
	 *
	 * @param logic			A function which is called each frame while the particle body is active. Must take one integer, which is the particle body's entity index.
	 * @param plugin		The name of the plugin which contains the logic function.
	 * @param pos			Position to spawn the particle body at.
	 * @param ang			Angles to spawn the particle body with.
	 * @param lifespan		Time until the particle body is automatically deleted. <= 0.0: do not delete.
	 * @param faderate		If != 0.0: this ParticleBody and all entities attached to it will fade in (negative) or out (positive) at a rate of faderate per frame while active.
							If positive, the ParticleBody will automatically fade out when removed. Note that this is ignored if ParticleBody.Index is destroyed.
							If you wish to manually start or stop the fade, you may set ParticleBody.Fading. To change the fade rate, you may set ParticleBody.Fade_Rate.
							Also note that certain entities do not fade out properly, and some can't be faded out at all.
	 *
	 */
	public native ParticleBody(Function logic = INVALID_FUNCTION, char plugin[255] = "", float pos[3] = NULL_VECTOR, float ang[3] = NULL_VECTOR, float lifespan = 0.0, float fadeRate = 0.0);
	
	/**
	 * Adds the specified entity to the particle body.
	 *
	 * @param entity		The entity to be added.
	 * @param lifespan		Time until the entity is automatically deleted. <= 0.0: do not delete.
	 * @param logic			A function which is called each frame while this entity is active. Must take one integer, which is this entity.
	 * @param plugin		The plugin which contains the logic function.
	 */
	public native void AddEntity(int entity, float lifespan = 0.0, Function logic = INVALID_FUNCTION, char plugin[255] = "");
	
	/**
	 * Adds the specified particle effect to the particle body.
	 *
	 * @param name			The particle effect to add.
	 * @param lifespan		Time until the particle is automatically deleted. <= 0.0: do not delete.
	 * @param logic			A function which is called each frame while this particle is active. Must take one integer, which is this particle.
	 * @param plugin		The plugin which contains the logic function.
	 *
	 * @return 	The particle's entity index on successful spawn, -1 if failed.
	 */
	public native int AddParticle(char name[255], float lifespan = 0.0, Function logic = INVALID_FUNCTION, char plugin[255] = "");
	
	/**
	 * Adds a dynamic light to the particle body. Use this with caution, as dynamically spawned lights are known to sometimes cause lag.
	 *
	 * @param color			The RGB values of the light. The 4th slot is for intensity, NOT alpha.
	 * @param brightness	The intensity of the light.
	 * @param distance		Max distance the light can cast.
	 * @param inner			The inner angles of the spotlight beam, 0 for omnidirectional.
	 * @param outer			The outer angles of the spotlight beam, 0 for omnidirectional.
	 * @param spotlight_radius	The radius of the light on the object it is hitting.
	 * @param appearance	The style of the light. Can be used to make it flicker, fade in/out, etc.
	 * @param flags			Spawn flags.
	 * @param lifespan		Time until the light is automatically deleted. <= 0.0: do not delete.
	 * @param logic			A function which is called each frame while this light is active. Must take one integer, which is this light.
	 * @param plugin		The plugin which contains the logic function.
	 *
	 * @return 	The light's entity index on successful spawn, -1 if failed.
	 */
	public native int AddLight(int color[4], int brightness, float distance, int inner = 0, int outer = 0, float spotlight_radius = 0.0, int appearance = 0, int flags = 0, float lifespan = 0.0, Function logic = INVALID_FUNCTION, char plugin[255] = "");
	
	/**
	 * Adds a sprite to the particle body.
	 *
	 * @param name			The material to be used for the sprite.
	 * @param scale			Sprite scale.
	 * @param color			RGB values to use.
	 * @param alpha			Alpha to use. Requires the render mode to be anything other than RENDER_NORMAL.
	 * @param rendermode	Render mode to use.
	 * @param framerate		The frame rate to be used for animated sprites.
	 * @param startingframe	The frame to start on, used for animated sprites.
	 * @param lifespan		Time until the sprite is automatically deleted. <= 0.0: do not delete.
	 * @param logic			A function which is called each frame while this sprite is active. Must take one integer, which is this sprite.
	 * @param plugin		The plugin which contains the logic function.
	 *
	 * @return 	The sprite's entity index on successful spawn, -1 if failed.
	 */
	public native int AddSprite(char name[255], float scale, int color[3], int alpha, RenderMode rendermode = RENDER_TRANSCOLOR, int framerate = 30, float startingframe = 0.0, float lifespan = 0.0, Function logic = INVALID_FUNCTION, char plugin[255] = "");
	
	/**
	 * Adds a trail to the particle body.
	 *
	 * @param name			The material to be used for the trail.
	 * @param length		The duration each sprite lasts. Longer = longer trails.
	 * @param startwidth	The width of the trail at the beginning.
	 * @param endwidth		The width of the trail at the end.
	 * @param color			RGB values to use. Note that certain rendermodes will prevent this from working.
	 * @param alpha			Alpha to use. Requires the render mode to be anything other than RENDER_NORMAL.
	 * @param rendermode	Render mode to use.
	 * @param renderfx		Render effects to use.
	 * @param lifespan		Time until the trail is automatically deleted. <= 0.0: do not delete.
	 * @param logic			A function which is called each frame while this trail is active. Must take one integer, which is this trail.
	 * @param plugin		The plugin which contains the logic function.
	 *
	 * @return 	The trail's entity index on successful spawn, -1 if failed.
	 */
	public native int AddTrail(char name[255], float length, float startwidth, float endwidth, int color[3], int alpha, RenderMode rendermode = RENDER_TRANSCOLOR, int renderfx = 0, float lifespan = 0.0, Function logic = INVALID_FUNCTION, char plugin[255] = "");
	
	/**
	 * Destroys all of the entities which comprise this ParticleBody. Automatically called when the ParticleBody.Index is removed. This native DOES NOT destroy ParticleBody.Index.
	 */
	public native void Destroy();
	
	property int Index
	{
		public native get();
	}
	
	property float End_Time
	{
		public native get();
		public native set(float value);
	}
	
	property float Fade_Rate
	{
		public native get();
		public native set(float value);
	}
	
	property bool Exists
	{
		public native get();
		public native set(bool value);
	}
	
	property bool Fading
	{
		public native get();
		public native set(bool value);
	}
	
	property bool Will_Fade
	{
		public native get();
	}
	
	property Function Logic
	{
		public native set(Function value);
	}
	
	property Handle Logic_Plugin
	{
		public native get();
		public native set(Handle value);
	}
	
	property ArrayList Entities
	{
		public native get();
		public native set(ArrayList value);
	}
}

//Then, we add a method to Particle Simulation called "AddToSimulation" which takes a ParticleBody as a parameter.
methodmap ParticleSimulation __nullable__
{
	/**
	 * Creates a new particle simulation. WARNING: THESE CAN GET VERY EXPENSIVE VERY QUICKLY! USE WITH CAUTION!
	 *
	 * @param logic			A function which is called each frame while the simulation is active. Must take one integer, which is the simulation's entity index.
	 * @param plugin		The name of the plugin which contains the logic function.
	 * @param pos			Position to spawn the simulation at.
	 * @param ang			Angles to spawn the simlation with.
	 * @param maxEnts		The maximum number of ParticleBody collections in this simulation at the same time. If a ParticleBody is added above this cap, the oldest still-existing ParticleBody is deleted. <= 0 = no cap.
	 * @param lifespan		Time until the simulation is automatically deleted. <= 0.0: do not delete.
	 * @param eraseOnEnd	If true, all ParticleBodies in the collection are immediately deleted when the simulation ends.
	 *
	 */
	public native ParticleSimulation(Function logic = INVALID_FUNCTION, char plugin[255] = "", float pos[3] = NULL_VECTOR, float ang[3] = NULL_VECTOR, int maxEnts = 10, float lifespan = 0.0, bool eraseOnEnd = false);
	
	/**
	 * Resets all of the simulation's stats and clears its logic. Called automatically if ParticleSimulation.Index is removed. This DOES NOT destroy ParticleSimulation.Index.
	 */
	public native void Destroy();
	
	/**
	 * Attaches the particle simulation to a given entity.
	 *
	 * @param entity		The entity to attach to.
	 * @param point			Attachment point.
	 * @param xOffset		Optional x-axis offset.
	 * @param yOffset		Optional y-axis offset.
	 * @param zOffset		Optional z-axis offset.
	 */
	public native void AttachToEntity(int entity, char point[255] = "", float xOffset = 0.0, float yOffset = 0.0, float zOffset = 0.0);
	
	/**
	 * Detaches the particle simulation from whatever entity it is currently attached to.
	 */
	public native void DetachFromEntity();
	
	/**
	 * Adds a given ParticleBody collection to the simulation.
	 *
	 * @param PBod 	The ParticleBody to add.
	 * @param parent	If true, the ParticleBody will be parented to the simulation.
	 */
	public native void AddParticleBody(ParticleBody PBod, bool parent = true);
	
	property int Index
	{
		public native get();
	}
	
	property int Max_Entities 
	{
		public native get();
		public native set(int value);
	}
	
	property float End_Time
	{
		public native get();
		public native set(float value);
	}
	
	property bool Erase_Bodies_On_End
	{
		public native get();
		public native set(bool value);
	}
	
	property bool Exists
	{
		public native get();
		public native set(bool value);
	}
	
	property Function Logic
	{
		public native set(Function value);
	}
	
	property Handle Logic_Plugin
	{
		public native get();
		public native set(Handle value);
	}
	
	property Queue PBodies
	{
		public native get();
		public native set(Queue value);
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
 * Spawns a prop_dynamic at the given coordinates. Intended to be used to spawn fake particle effects.
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
 * Spawns a unique model at the given coordinates which simulates an `env_sprite`, with added customization. 
 * Billboard particles are VERY expensive and must be used sparingly, as they achieve their `env_sprite` simulation by spawning a unique model for every client.
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

/**
 * Creates a particle simulation, which makes use of particle bodies to approximately simulate how an *actual* particle effect works.
 * NOTE: THESE CAN BECOME EXTREMELY EXPENSIVE ON THE ENTITY LIMIT! USE WITH CAUTION!
 *
 * @param pos		The origin of the particle simulation.
 * @param ang		The angles of the particle simulation.
 * @param maxEnts	The maximum number of ParticleBody collections in this simulation at the same time. If a ParticleBody is added above this cap, the oldest still-existing ParticleBody is deleted. <= 0 = no cap.
 * @param lifespan	The duration of the particle simulation. <= 0.0: No limit.
 * @param plugin	Optional plugin name, required for the "logic" parameter.
 * @param logic		Optional function called every frame for the particle simulation. This function must take an integer, which represents the particle simulation's root entity (ParticleSimulation.Index).
 * @param eraseOnEnd	If true, all ParticleBody collections in the simulation are immediately deleted when the simulation ends.
 *
 * @return A ParticleSimulation methodmap which can be used to control how the particle simulation behaves. Accessing ParticleSimulation.Index allows you to directly access the simulation's base entity to control things like position, angles, velocity, etc.
 */
native ParticleSimulation FPS_CreateParticleSimulation(float pos[3], float ang[3], int maxEnts = 100, float lifespan = 0.0, char plugin[255] = "", Function logic = INVALID_FUNCTION, bool eraseOnEnd = true);

/**
 * Creates a particle body, which is a root entity with natives to attach various visual effects (lights, sprites, trails, particles, etc) to create a more appealing visual effect.
 * Can be used on its own, or attached to a ParticleSimulation via ParticleSimulation.AddParticleBody as part of a bigger visual effect.
 *
 * @param pos	The origin of the particle body.
 * @param ang	The angles of the particle body.
 * @param lifespan	The duraton of the particle body. <= 0.0: No limit.
 * @param plugin	The name of the plugin which contains the "logic" function.
 * @param logic		A function which is called for this particle body every frame, useful for adding your own custom logic. The function must take an integer, which represents the particle body's root entity (ParticleBody.Index).
 * @param faderate		If != 0.0: this ParticleBody and all entities attached to it will fade in (negative) or out (positive) at a rate of faderate per frame while active.
						If positive, the ParticleBody will automatically fade out when removed. Note that this is ignored if ParticleBody.Index is destroyed.
						If you wish to manually start or stop the fade, you may set ParticleBody.Fading. To change the fade rate, you may set ParticleBody.Fade_Rate.
						Also note that certain entities do not fade out properly, and some can't be faded out at all.
 *
 * @return A ParticleBody methodmap which can be used to control how the particle body behaves. Accessing ParticleBody.Index allows you to directly access the particle body's base entity to control things like position, angles, velocity, etc.
 */
native ParticleBody FPS_CreateParticleBody(float pos[3], float ang[3], float lifespan = 0.0, char plugin[255] = "", Function logic = INVALID_FUNCTION, float faderate = 0.0);