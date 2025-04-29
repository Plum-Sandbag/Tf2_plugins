/**
 * Gravity Invlude File
 *
 * Created this include for to use reflection for these accessor methods.
 */

/**
 *	Retrieves the plugin's handle
 *	Useful for calling other subplugins, if using the reflective method.
 *	
 *	@param pluginName		Plugin Name
 *	@return 				Handle of plugin
 **/
stock Handle FindPlugin(char[] pluginName)
{
	char buffer[256];
	char path[PLATFORM_MAX_PATH];
	Handle iter=GetPluginIterator();
	Handle pl=null;
	while(MorePlugins(iter))
	{
		pl=ReadPlugin(iter);
		Format(path, sizeof(path), "%s", pluginName);
		GetPluginFilename(pl, buffer, sizeof(buffer));
		if(StrContains(buffer, path, false) >= 0)
		{
			break;
		}
		else
		{
			pl=null;
		}
	}
	delete iter;
	return pl;
}

/**
 *	Check if plugin exists
 *	
 *	@param pluginName		Plugin Name
 *	@return					True if plugin exists, false otherwise.
 **/
stock bool PluginExists(char[] pluginName)
{
	Handle plugin=FindPlugin(pluginName);
	if(plugin!=null) return true;
	return false;
}

/**
 *	Hook Abilities from boss config
 *	Can be used to restore changed values
 *	
 *	@param bossIdx		Boss index
 *	@param bossClientIdx	Client index
 *	@return					True if plugin exists, false otherwise.
 **/
stock bool GRV_HookAbilities(int bossIdx, int bossClientIdx)
{
	bool result = false;

	Handle plugin = FindPlugin("ff2_gravity.ff2");
	if(plugin != INVALID_HANDLE)
	{
		Function func = GetFunctionByName(plugin, "HookAbilities");
		if (func != INVALID_FUNCTION)
		{
			Call_StartFunction(plugin, func);
			Call_PushCell(bossIdx);
			Call_PushCell(BossClientIdx);
			Call_Finish(result);
		}
		else
			PrintToServer("ERROR: Could not find ff2_gravity.sp:HookAbilities().");
	}
	else
		PrintToServer("ERROR: Could not find ff2_gravity plugin. HookAbilities() failed.");
		
	return result;
}

/**
 *	Change Ability Fundamental Status "rage_shockwave"
 *	
 *	@param bossClientIdx	Client index
 *	@param PlayerDamage		New Player Damage Value
 *	@param BuildingDamage	New Building Damage value
 *	@param Radius			New Rage Radius
 *	@param KockbackForce	New Knockback Force
 * 	@param MinZ_Insenity	New Minimum Z insenity 
 *	@return					True if plugin exists, false otherwise.
 **/
stock bool SHW_ChangeFundamentalStats(int bossClientIdx, float PlayerDamage, float BuildingDamage, float Radius, float KnockbackForce, float MinZ_Insenity)
{
	bool result = false;

	Handle plugin = FindPlugin("ff2_gravity.ff2");
	if(plugin != INVALID_HANDLE)
	{
		Function func = GetFunctionByName(plugin, "SHW_ChangeFundamentalStats");
		if (func != INVALID_FUNCTION)
		{
			Call_StartFunction(plugin, func);
			Call_PushCell(BossClientIdx);
			Call_PushFloat(PlayerDamage);
			Call_PushFloat(BuildingDamage);
			Call_PushFloat(Radius);
			Call_PushFloat(KnockbackForce);
			Call_PushFloat(MinZ_Insenity);
			Call_Finish(result);
		}
		else
			PrintToServer("ERROR: Could not find ff2_gravity.sp: SHW_ChangeFundamentalStats().");
	}
	else
		PrintToServer("ERROR: Could not find ff2_gravity plugin.  SHW_ChangeFundamentalStats() failed.");
		
	return result;
}

/**
 *	Change Ability Fundamental Status "rage_sigma"
 *	
 *	@param bossClientIdx	Client index
 *	@param Position			New center Position, 0:Stand Pos, 1:Aim Pos, -1:Don't Change
 *	@param VelocityForce	New velocity force, -1:Don't Change
 *	@param VelocityDuration	New velocity force duration, -1:Don't Change
 *	@param GravityForce		New gravity force, -1:Don't Change
 *	@param GravityDuration	New gravity froce duration, -1:Don't Change
 * 	@param ExplodeBuilding	New value, 1:Explode Building, 0:Don't, -1:Don't Change
 * 	@param Damage			New damage value, -1:Don't Change
 *	@param ParticleName		New particle name. Leave blank for don't change
 *	@param particlePos		New particle position. Leave blank for don't change
 *	@return					True if plugin exists, false otherwise.
 **/
stock bool SIG_ChangeFundamentalStats(int bossClientIdx, int Position, float Radius, float VelocityForce, float VelocityDuration, float GravityForce, float GravityDuration, int ExplodeBuilding, float Damage, const char[] ParticleName, const char[] ParticlePos)
{
	bool result = false;

	Handle plugin = FindPlugin("ff2_gravity.ff2");
	if(plugin != INVALID_HANDLE)
	{
		Function func = GetFunctionByName(plugin, "SIG_ChangeFundamentalStats");
		if (func != INVALID_FUNCTION)
		{
			Call_StartFunction(plugin, func);
			Call_PushCell(BossClientIdx);
			Call_PushCell(Position);
			Call_PushFloat(VelocityForce);
			Call_PushFloat(VelocityDuration);
			Call_PushFloat(GravityForce);
			Call_PushFloat(GravityDuration);
			Call_PushCell(ExplodeBuilding);
			Call_PushFloat(Damage);
			Call_PushString(Particlename);
			Call_PushString(ParticlePos);
			Call_Finish(result);
		}
		else
			PrintToServer("ERROR: Could not find ff2_gravity.sp:SIG_ChangeFundamentalStats().");
	}
	else
		PrintToServer("ERROR: Could not find ff2_gravity plugin. SIG_ChangeFundamentalStats() failed.");
		
	return result;
}

/**
 *	Fix Player Gravity	(Def 1.0)
 *	
 *	@param clientIdx		Client index (-1 for everyone)
 *	@return					True if plugin exists, false otherwise.
 **/
stock bool GRV_FixGravity(int clientIdx)
{
	bool result = false;

	Handle plugin = FindPlugin("ff2_gravity.ff2");
	if(plugin != INVALID_HANDLE)
	{
		Function func = GetFunctionByName(plugin, "GRV_FixGravity");
		if (func != INVALID_FUNCTION)
		{
			Call_StartFunction(plugin, func);
			Call_PushCell(clientIdx);
			Call_Finish(result);
		}
		else
			PrintToServer("ERROR: Could not find ff2_gravity.sp:SIG_ChangeFundamentalStats().");
	}
	else
		PrintToServer("ERROR: Could not find ff2_gravity plugin. SIG_ChangeFundamentalStats() failed.");
		
	return result;
}