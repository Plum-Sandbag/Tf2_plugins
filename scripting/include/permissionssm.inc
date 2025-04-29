/** Double-include prevention */
#if defined _permissionssm_included_
  #endinput
#endif
#define _permissionssm_included_
 
/**
 * Checks if Client has Permission Node directly or via Groups.
 *
 * @param client	Client index.
 * @param node	String that represents the Permission Node. Format usually: <PluginName.Command>.
 * @param ...		Parameters to Format String.
 * @return			True if Player has Permission, false if not.
 */
native bool:PsmHasPermission(client, String:node[], any:...);

/**
 * Compares immunity
 *
 * @param client	Client index of the targeting person.
 * @param target	Client index of the targeted person.
 * @return			True if Client has higher immunity than target, false if not.
 */
native bool:PsmCanTarget(client, target);

public SharedPlugin:__pl_PermissionsSM = {
	name = "permissionssm",
	file = "PermissionsSM.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_PermissionsSM_SetNTVOptional() {
	MarkNativeAsOptional("PsmHasPermission");
	MarkNativeAsOptional("PsmCanTarget");
}
#endif