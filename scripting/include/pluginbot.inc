#if defined pluginbot_included
	#endinput
#endif

#define pluginbot_included

/*
TODO:
finish vision arraylist functions
finish OnSound callback
IPathCost
custom Behaviors and Actions
make everthing handles
document everthing
*/

#define FOR_EACH_RESPONDER(%1) \
	for(INextBotEventResponder responder = %1.FirstContainedResponder(); \
	responder != Address_Null; \
	responder = %1.NextContainedResponder(responder))

enum INextBotEventResponder: {};
enum INextBotComponent: {};
enum INextBot: {};
enum ILocomotion: {};
enum IContextualQuery: {};
enum IIntention: {};
enum IVision: {};
enum IBody: {};
#if defined GAME_TF2
enum CKnownEntity: {};
#endif
enum PluginBotReply: {};
#if defined GAME_TF2
enum PluginBotAction: {};
enum ActionResult: {};
enum PluginBotForEachKnownEntity: {};
#endif
enum PluginBotEntityFilter: {};
enum Segment: {};
enum CursorData: {};
enum Path: {};
enum PathFollower: {};
enum ChasePath: {};

enum PluginBotHookType
{
	PluginBotHookType_Invalid = -1,
	OnLeaveGround,
	OnLandOnGround,
	OnContact,
	OnMoveToSuccess,
	OnMoveToFailure,
	OnStuck,
	OnUnStuck,
	OnPostureChanged,
	OnAnimationActivityComplete,
	OnAnimationActivityInterrupted,
	OnAnimationEvent,
	OnIgnite,
	OnInjured,
	OnKilled,
	OnOtherKilled,
	OnSight,
	OnLostSight,
	#if defined GAME_L4D2
	OnThreatChanged,
	#endif
	OnSound,
	OnSpokeConcept,
	#if defined GAME_TF2
	OnWeaponFired,
	#endif
	OnNavAreaChanged,
	OnModelChanged,
	OnPickUp,
	OnDrop,
	#if defined GAME_TF2
	OnActorEmoted,
	#endif
	OnCommandAttack,
	#if defined GAME_L4D2
	OnCommandAssault,
	#endif
	OnCommandApproach,
	OnCommandApproachEx,
	OnCommandRetreat,
	OnCommandPause,
	OnCommandResume,
	OnCommandString,
	OnShoved,
	OnBlinded,
	#if defined GAME_L4D2
	OnEnteredSpit,
	OnHitByVomitJar,
	#endif
	#if defined GAME_TF2
	OnTerritoryContested,
	OnTerritoryCaptured,
	OnTerritoryLost,
	OnWin,
	OnLose,
	#endif
	PluginBotHookType_Max,
};

enum Activity
{
	
};

enum TraverseWhenType
{

};

enum MoveCursorType
{
	MOVECUR_ABS = 0,
	MOVECUR_REL = 1,
	MOVECUR_MAX,
};

enum SegmentType
{
	SEG_GROUND      = 0, // ground movement
	SEG_FALL        = 1, // falling down
	SEG_CLIMBJUMP   = 2, // climbing up or jumping
	SEG_GAPJUMP     = 3, // gap jumping
	SEG_LADDER_UP   = 4, // ladder up
	SEG_LADDER_DOWN = 5, // ladder down
};

enum NextBotDebugType
{
	DEBUG_NONE = 0x0000,
	DEBUG_ANY  = 0xffff,

	DEBUG_BEHAVIOR   = (1 << 0), // NextBotBehavior
	DEBUG_LOOK_AT    = (1 << 1), // NextBotBodyInterface
	DEBUG_PATH       = (1 << 2), // NextBotPath, NextBotPathFollow, NextBotChasePath
	DEBUG_ANIMATION  = (1 << 3),
	DEBUG_LOCOMOTION = (1 << 4), // NextBotLocomotionInterface
	DEBUG_VISION     = (1 << 5), // NextBotVisionInterface
	DEBUG_HEARING    = (1 << 6),
	DEBUG_EVENTS     = (1 << 7), // NextBotEventResponderInterface
	DEBUG_ERRORS     = (1 << 8),
};

enum QueryResponse
{
	QUERY_NO   = 0,
	QUERY_YES  = 1,
	QUERY_ANY  = 2,
};

enum LookAtPriorityType
{
	PRI_BORING      = 0,
	PRI_INTERESTING = 1,
	PRI_IMPORTANT   = 2,
	PRI_CRITICAL    = 3,
	PRI_OVERRIDE    = 4,
};

enum PostureType
{
	POSTURE_STAND  = 0,
	POSTURE_CROUCH = 1,
	POSTURE_SIT    = 2,
	POSTURE_LIE    = 4,
};

enum ArousalType
{
	ALERT_YES = 0,
	ALERT_NO  = 1,
};

enum FailureReason
{
	FAIL_REJECTED      = 0, // AimHeadTowards denied the aim
	FAIL_PREEMPTED     = 1, // a higher priority aim preempted our aim
	FAIL_UNIMPLEMENTED = 2, // subclass didn't override IBody::AimHeadTowards
};

enum FieldOfViewCheckType
{
	USE_FOV       = 0,
	DISREGARD_FOV = 1,
};

#if defined GAME_TF2
methodmap ActionResult
{
	public static native ActionResult Continue();
	public static native ActionResult ChangeTo(PluginBotAction next, const char[] why);
	public static native ActionResult SuspendFor(PluginBotAction next, const char[] why);
	public static native ActionResult Done(const char[] why);
	public static native ActionResult Sustain(const char[] why);
};
#endif

methodmap INextBotEventResponder
{
	public native INextBotEventResponder FirstContainedResponder();
	public native INextBotEventResponder NextContainedResponder(INextBotEventResponder prev);
	#if defined GAME_L4D2
	public native void GetDebugString(char[] name, int maxlen);
	#endif
};

#if defined GAME_TF2
methodmap CKnownEntity
{
	public native void Destroy();
	public native void UpdatePosition();
	public native int GetEntity();

	public native void GetLastKnownPosition(float pos[3]);
	public native bool HasLastKnownPositionBeenSeen();
	public native void MarkLastKnownPositionAsSeen();
	public native Address /*CNavArea*/ GetLastKnownArea();
	public native float GetTimeSinceLastKnown();
	public native float GetTimeSinceBecameKnown();

	public native void UpdateVisibilityStatus(bool visible);
	public native bool IsVisibleInFOVNow();
	public native bool IsVisibleRecently();
	public native float GetTimeSinceBecameVisible();
	public native float GetTimeWhenBecameVisible();
	public native float GetTimeSinceLastSeen();
	public native bool WasEverVisible();

	public native bool IsObsolete();
	public native bool Is(int entity);
};
#endif

methodmap Path
{
	public native float GetLength();
	public native void GetPosition(float dist, Segment seg, float pos[3]);
	public native void GetStartPosition(float pos[3]);
	public native void GetEndPosition(float pos[3]);
	public native int GetSubject();
	#if defined GAME_L4D2
	public native void SetSubject(int entity);
	#endif
	public native Segment GetCurrentGoal();
	public native float GetAge();
	public native void MoveCursorToStart();
	public native void MoveCursorToEnd();
	public native void MoveCursor(float dist, MoveCursorType mctype);
	public native float GetCursorPosition();
	public native CursorData GetCursorData();
	public native bool IsValid();
	public native void Invalidate();
	public native void Draw(Segment seg);
	public native void DrawInterpolated(float from, float to);
	public native Segment FirstSegment();
	public native Segment NextSegment(Segment seg);
	public native Segment PriorSegment(Segment seg);
	public native Segment LastSegment();
};

methodmap PathFollower < Path
{
	public native void Update(INextBot nextbot);
	public native void SetMinLookAheadDistance(float dist);
	public native int GetHindrance();
	public native bool IsDiscontinuityAhead(INextBot nextbot, SegmentType stype, float max_dist);
};

methodmap ChasePath < PathFollower
{
	public native float GetLeadRadius();
	public native float GetMaxPathLength();
	public native void PredictSubjectPosition(INextBot nextbot, int entity, float pos[3]);
	public native bool IsRepathNeeded(INextBot nextbot, int entity);
	public native float GetLifetime();
};

methodmap INextBotComponent < INextBotEventResponder
{
	public native void Reset();
	public native void Update();
	public native void Upkeep();

	public native INextBot GetBot();
};

methodmap PluginBotEntityFilter  < Handle
{
	
};

#if defined GAME_TF2
methodmap PluginBotForEachKnownEntity  < Handle
{
	
};
#endif

methodmap IVision < INextBotComponent
{
	#if defined GAME_TF2
	public native bool ForEachKnownEntity(PluginBotForEachKnownEntity functor);
	public native void CollectKnownEntities(ArrayList knowns);
	public native CKnownEntity GetPrimaryKnownThreat(bool only_recently_visible);
	public native CKnownEntity GetClosestKnown(int teamnum);
	public native int GetKnownCount(int teamnum, bool only_recently_visible, float range);
	public native CKnownEntity GetClosestKnownEx(PluginBotEntityFilter filter);
	public native CKnownEntity GetKnown(int entity);
	public native void AddKnownEntity(int entity);
	public native void ForgetEntity(int entity);
	public native void ForgetAllKnownEntities();
	public native void CollectPotentiallyVisibleEntities(ArrayList ents);
	#endif

	public native float GetTimeSinceVisible(int teamnum);

	#if defined GAME_L4D2
	public native int GetPrimaryRecognizedThreat();
	public native int GetClosestRecognized(int teamnum);
	public native int GetRecognizedCount(int teamnum, float range);
	public native int GetClosestRecognizedEx(PluginBotEntityFilter filter);
	#endif

	public native float GetMaxVisionRange();
	public native float GetMinRecognizeTime();
	public native bool IsAbleToSee(int entity, FieldOfViewCheckType ctype, float vec[3]);
	public native bool IsAbleToSeeEx(float vec[3], FieldOfViewCheckType ctype);
	public native bool IsIgnored(int entity);

	#if defined GAME_TF2
	public native bool IsVisibleEntityNoticed(int entity);
	#endif

	public native bool IsInFieldOfView(float vec[3]);
	public native bool IsInFieldOfViewEx(int entity);
	public native float GetDefaultFieldOfView();
	public native float GetFieldOfView();
	public native void SetFieldOfView(float fov);
	public native bool IsLineOfSightClear(float vec[3]);
	public native bool IsLineOfSightClearToEntity(int entity, float vec[3]);
	public native bool IsLookingAt(float vec[3], float cos_half_fov);
	public native bool IsLookingAtEx(int entity, float cos_half_fov);
};

methodmap IContextualQuery
{
	public native QueryResponse ShouldPickUp(INextBot bot, int entity);
	public native QueryResponse ShouldHurry(INextBot bot);
	
	#if defined GAME_TF2
	public native QueryResponse ShouldRetreat(INextBot bot);
	public native QueryResponse ShouldAttack(INextBot bot, CKnownEntity knownentity);
	#endif

	public native QueryResponse IsHindrance(INextBot bot, int entity);

	public native void SelectTargetPoint(INextBot bot, int entity, float point[3]);

	public native QueryResponse IsPositionAllowed(INextBot bot, const float pos[3]);
	
	#if defined GAME_L4D2
	public native PathFollower QueryCurrentPath(INextBot bot);
	#endif

	#if defined GAME_TF2
	public native CKnownEntity SelectMoreDangerousThreat(INextBot bot, int entity, CKnownEntity threat1, CKnownEntity threat2);
	#endif
	
	#if defined GAME_L4D2
	public native int SelectMoreDangerousThreat(INextBot bot, int entity, int threat1, int threat2);
	#endif
};

methodmap IIntention < INextBotComponent
{
	public native QueryResponse ShouldPickUp(INextBot bot, int entity);
	public native QueryResponse ShouldHurry(INextBot bot);
	
	#if defined GAME_TF2
	public native QueryResponse ShouldRetreat(INextBot bot);
	public native QueryResponse ShouldAttack(INextBot bot, CKnownEntity knownentity);
	#endif

	public native QueryResponse IsHindrance(INextBot bot, int entity);

	public native void SelectTargetPoint(INextBot bot, int entity, float point[3]);

	public native QueryResponse IsPositionAllowed(INextBot bot, const float pos[3]);
	
	#if defined GAME_L4D2
	public native PathFollower QueryCurrentPath(INextBot bot);
	#endif

	#if defined GAME_TF2
	public native CKnownEntity SelectMoreDangerousThreat(INextBot bot, int entity, CKnownEntity threat1, CKnownEntity threat2);
	#endif
	
	#if defined GAME_L4D2
	public native int SelectMoreDangerousThreat(INextBot bot, int entity, int threat1, int threat2);
	#endif
};

methodmap IBody < INextBotComponent
{
	public native bool SetPosition(float pos[3]);

	public native void GetEyePosition(float eyepos[3]);
	public native void GetViewVector(float view[3]);

	public native void AimHeadTowards(float pos[3], LookAtPriorityType priority, float duration, PluginBotReply reply, const char[] reason);
	public native void AimHeadTowardsEx(int entity, LookAtPriorityType priority, float duration, PluginBotReply reply, const char[] reason);

	public native bool IsHeadAimingOnTarget();
	public native bool IsHeadSteady();
	public native float GetHeadSteadyDuration();
	public native float GetHeadAimSubjectLeadTime();
	public native float GetHeadAimTrackingInterval();
	public native void ClearPendingAimReply();
	public native float GetMaxHeadAngularVelocity();

	public native bool StartActivity(Activity act, int unknown);
	public native int SelectAnimationSequence(Activity act);
	public native Activity GetActivity();
	public native bool IsActivity(Activity act);
	public native bool HasActivityType(int unknown);

	public native void SetDesiredPosture(PostureType posture);
	public native PostureType GetDesiredPosture();
	public native bool IsDesiredPosture(PostureType posture);
	public native bool IsInDesiredPosture();
	public native PostureType GetActualPosture();
	public native bool IsActualPosture(PostureType posture);
	public native bool IsPostureMobile();
	public native bool IsPostureChanging();

	public native void SetArousal(ArousalType arousal);
	public native ArousalType GetArousal();
	public native bool IsArousal(ArousalType arousal);

	public native float GetHullWidth();
	public native float GetHullHeight();
	public native float GetStandHullHeight();
	public native float GetCrouchHullHeight();
	public native void GetHullMins(float mins[3]);
	public native void GetHullMaxs(float maxs[3]);

	public native int GetSolidMask();
	public native int GetCollisionGroup();

	#if defined GAME_L4D2
	public native int GetEntity();
	#endif
};

methodmap ILocomotion < INextBotComponent
{
	public native void Approach(const float dst[3], float unknown);
	public native void DriveTo(const float dst[3]);

	public native bool ClimbUpToLedge(const float dst[3], const float dir[3], int entity);
	public native void JumpAcrossGap(const float dst[3], const float dir[3]);
	public native void Jump();
	public native bool IsClimbingOrJumping();
	public native bool IsClimbingUpToLedge();
	public native bool IsJumpingAcrossGap();
	public native bool IsScrambling();

	public native void Run();
	public native void Walk();
	public native void Stop();

	public native bool IsRunning();

	public native void SetDesiredSpeed(float speed);
	public native float GetDesiredSpeed();

	public native void SetSpeedLimit(float limit);
	public native float GetSpeedLimit();

	public native bool IsOnGround();
	public native int GetGround();
	public native void GetGroundNormal(float normal[3]);
	public native float GetGroundSpeed();
	public native void GetGroundMotionVector(float motion[3]);

	public native void ClimbLadder(Address CNavLadder, Address CNavArea);
	public native void DescendLadder(Address CNavLadder, Address CNavArea);

	public native bool IsUsingLadder();
	public native bool IsAscendingOrDescendingLadder();
	public native bool IsAbleToAutoCenterOnLadder();

	public native void FaceTowards(const float pos[3]);

	public native void SetDesiredLean(const float lean[3]);
	public native void GetDesiredLean(float lean[3]);

	#if defined GAME_TF2
	public native bool IsAbleToJumpAcrossGaps();
	public native bool IsAbleToClimb();
	#endif

	public native void GetFeet(float feet[3]);

	public native float GetStepHeight();
	public native float GetMaxJumpHeight();
	public native float GetDeathDropHeight();
	public native float GetRunSpeed();
	public native float GetWalkSpeed();

	#if defined GAME_TF2
	public native float GetMaxAcceleration();
	public native float GetMaxDeceleration();
	#endif

	public native void GetVelocity(float vel[3]);

	public native float GetSpeed();

	public native void GetMotionVector(float motion[3]);

	public native bool IsAreaTraversable(Address CNavArea);
	public native float GetTraversableSlopeLimit();

	public native bool IsPotentiallyTraversable(const float from[3], const float to[3], TraverseWhenType when);
	public native bool HasPotentialGap(const float from[3], const float to[3]);
	public native bool IsGap(const float from[3], const float to[3]);
	public native bool IsEntityTraversable(int entity, TraverseWhenType when);

	public native bool IsStuck();
	public native float GetStuckDuration();
	public native void ClearStuckStatus(const char[] reason);

	public native bool IsAttemptingToMove();

	#if defined GAME_TF2
	public native bool ShouldCollideWith(int entity);
	#endif

	public native void AdjustPosture(const float lean[3]);

	#if defined GAME_TF2
	public native void StuckMonitor();
	#endif
};

methodmap INextBot < INextBotEventResponder
{
	public native void Reset();
	public native void Update();
	public native void Upkeep();

	public native bool IsRemovedOnReset();

	public native int GetEntity();
	public native int GetNextBotCombatCharacter();

	#if defined GAME_L4D2
	public native int MySurvivorBotPointer();
	#endif

	public native ILocomotion GetLocomotionInterface();
	public native IBody GetBodyInterface();
	public native IIntention GetIntentionInterface();
	public native IVision GetVisionInterface();

	public native bool SetPosition(const float pos[3]);
	public native void GetPosition(float pos[3]);

	public native bool IsEnemy(int entity);
	public native bool IsFriend(int entity);
	public native bool IsSelf(int entity);

	public native bool IsAbleToClimbOnto(int entity);
	public native bool IsAbleToBreak(int entity);
	public native bool IsAbleToBlockMovementOf(INextBot bot);

	public native bool ShouldTouch(int entity);

	#if defined GAME_L4D2
	public native void ReactToSurvivorVisibility();
	public native void ReactToSurvivorNoise();
	public native void ReactToSurvivorContact();
	#endif

	public native bool IsImmobile();
	public native float GetImmobileDuration();
	public native void ClearImmobileStatus();
	public native float GetImmobileSpeedThreshold();

	#if defined GAME_TF2
	public native PathFollower GetCurrentPath();
	public native void SetCurrentPath(const PathFollower path);
	public native void NotifyPathDestruction(const PathFollower path);
	#endif

	public native bool IsRangeLessThan(int entity, float dist);
	public native bool IsRangeLessThanEx(const float pos[3], float dist);
	public native bool IsRangeGreaterThan(int entity, float dist);
	public native bool IsRangeGreaterThanEx(const float pos[3], float dist);

	public native float GetRangeTo(int entity);
	public native float GetRangeToEx(const float pos[3]);
	public native float GetRangeSquaredTo(int entity);
	public native float GetRangeSquaredToEx(const float pos[3]);

	#if defined GAME_L4D2
	public native float Get2DRangeToEx(int entity);
	public native float Get2DRangeTo(const float pos[3]);
	#endif

	public native bool IsDebugging(NextBotDebugType type);
	public native void GetDebugIdentifier(char[] name, int maxsize);
	public native bool IsDebugFilterMatch(const char[] name);
	public native void DisplayDebugText(const char[] name);
};

typedef OnSuccessFunc = function void (INextBot bot);
typedef OnFailFunc = function void (INextBot bot, FailureReason reason);

#if defined GAME_TF2
typedef InspectFunc = function bool (CKnownEntity entity);
#endif

typedef IsAllowedFunc = function bool (int entity);

typeset PluginBotHookFunc
{
	/*
	OnLeaveGround
	OnLandOnGround
	OnAnimationActivityComplete
	OnAnimationActivityInterrupted
	OnSight
	OnLostSight
	OnDrop
	OnCommandAttack
	OnCommandApproachEx
	OnShoved
	OnBlinded
	TF2: OnTerritoryContested
	TF2: OnTerritoryCaptured
	TF2: OnTerritoryLost
	L4D2: OnThreatChanged
	L4D2: OnHitByVomitJar
	*/
	function void (INextBotEventResponder responder, int param1);

	/*
	OnContact
	OnMoveToSuccess
	OnOtherKilled
	*/
	function void (INextBotEventResponder responder, int param1, Address param2);

	/*
	OnMoveToSuccess
	OnAnimationEvent
	OnInjured
	OnKilled
	*/
	function void (INextBotEventResponder responder, Address param1);

	/*
	OnMoveToFailure
	*/
	function void (INextBotEventResponder responder, Address param1, int param2);

	/*
	OnStuck
	OnUnStuck
	OnPostureChanged
	OnIgnite
	OnModelChanged
	OnCommandResume
	TF2: OnWin
	TF2: OnLose
	L4D2: OnEnteredSpit
	L4D2: OnCommandAssault
	*/
	function void (INextBotEventResponder responder);

	/*
	OnSound
	*/
	function void (INextBotEventResponder responder, int param1, const float param2[3], KeyValues param3);

	/*
	OnSpokeConcept
	*/
	function void (INextBotEventResponder responder, int param1, const char[] param2, Address param3);

	/*
	TF2: OnWeaponFired
	OnPickUp
	TF2: OnActorEmoted
	*/
	function void (INextBotEventResponder responder, int param1, int param2);

	/*
	OnNavAreaChanged
	*/
	function void (INextBotEventResponder responder, Address param1, Address param2);

	/*
	OnCommandApproach
	*/
	function void (INextBotEventResponder responder, const float param1[3], float param2);

	/*
	OnCommandRetreat
	*/
	function void (INextBotEventResponder responder, int param1, float param2);

	/*
	OnCommandPause
	*/
	function void (INextBotEventResponder responder, float param1);

	/*
	OnCommandString
	*/
	function void (INextBotEventResponder responder, const char[] param1);
};

native INextBot PluginBot_GetNextBotOfEntity(int entity);
native PluginBotReply PluginBot_CreateReply(OnSuccessFunc success, OnFailFunc fail);

#if defined GAME_TF2
native PluginBotForEachKnownEntity PluginBot_CreateEachKnownEntityFunctor(InspectFunc inspect);

typeset PluginBotActionFuncs
{
	/*
	OnStart
	OnSuspend
	OnResume
	*/
	function ActionResult (int actor, PluginBotAction action);

	/*
	Update
	*/
	function ActionResult (int actor, float dt);

	/*
	OnEnd
	*/
	function void (int actor, PluginBotAction action);

	/*
	InitialContainedAction
	*/
	function PluginBotAction (int actor);
};

typedef GetMainActionFunc = function PluginBotAction ();

native void PluginBot_CreateBehavior(IIntention intention, GetMainActionFunc mainaction);
native PluginBotAction PluginBot_CreateAction(
	PluginBotActionFuncs OnStart=INVALID_FUNCTION,
	PluginBotActionFuncs Update=INVALID_FUNCTION,
	PluginBotActionFuncs OnEnd=INVALID_FUNCTION,
	PluginBotActionFuncs OnSuspend=INVALID_FUNCTION,
	PluginBotActionFuncs OnResume=INVALID_FUNCTION,
	PluginBotActionFuncs InitialContainedAction=INVALID_FUNCTION);


#endif

native PluginBotEntityFilter PluginBot_CreateNextBotEntityFilterFunctor(IsAllowedFunc isallowed);
native bool PluginBot_HookFunction(INextBotEventResponder responder, PluginBotHookFunc callback, PluginBotHookType type);
native bool PluginBot_RemoveHook(INextBotEventResponder responder, PluginBotHookFunc callback, PluginBotHookType type);
native any PluginBot_PlaceHolder(any param1=0, any param2=0, any param3=0);

#if !defined REQUIRE_EXTENSIONS
	public void __ext_pluginbot_SetNTVOptional()
	{
		MarkNativeAsOptional("PluginBot_GetNextBotOfEntity");
		MarkNativeAsOptional("PluginBot_CreateReply");
		MarkNativeAsOptional("PluginBot_CreateNextBotEntityFilterFunctor");
		MarkNativeAsOptional("PluginBot_HookFunction");
		MarkNativeAsOptional("PluginBot_RemoveHook");

		#if defined GAME_TF2
		MarkNativeAsOptional("PluginBot_CreateEachKnownEntityFunctor");
		MarkNativeAsOptional("PluginBot_CreateBehavior");
		MarkNativeAsOptional("PluginBot_CreateAction");

		MarkNativeAsOptional("ActionResult.Continue");
		MarkNativeAsOptional("ActionResult.ChangeTo");
		MarkNativeAsOptional("ActionResult.SuspendFor");
		MarkNativeAsOptional("ActionResult.Done");
		MarkNativeAsOptional("ActionResult.Sustain");
		#endif

		MarkNativeAsOptional("PluginBot_PlaceHolder");

		MarkNativeAsOptional("INextBotEventResponder.FirstContainedResponder");
		MarkNativeAsOptional("INextBotEventResponder.NextContainedResponder");

		MarkNativeAsOptional("INextBotComponent.Reset");
		MarkNativeAsOptional("INextBotComponent.Update");
		MarkNativeAsOptional("INextBotComponent.Upkeep");
		MarkNativeAsOptional("INextBotComponent.GetBot");

		MarkNativeAsOptional("IIntention.ShouldPickUp");
		MarkNativeAsOptional("IIntention.ShouldHurry");

		#if defined GAME_TF2
		MarkNativeAsOptional("IIntention.ShouldRetreat");
		MarkNativeAsOptional("IIntention.ShouldAttack");
		#endif

		MarkNativeAsOptional("IIntention.IsHindrance");
		MarkNativeAsOptional("IIntention.SelectTargetPoint");
		MarkNativeAsOptional("IIntention.IsPositionAllowed");

		#if defined GAME_L4D2
		MarkNativeAsOptional("IIntention.QueryCurrentPath");
		#endif

		MarkNativeAsOptional("IIntention.SelectMoreDangerousThreat");

		MarkNativeAsOptional("IContextualQuery.ShouldPickUp");
		MarkNativeAsOptional("IContextualQuery.ShouldHurry");

		#if defined GAME_TF2
		MarkNativeAsOptional("IContextualQuery.ShouldRetreat");
		MarkNativeAsOptional("IContextualQuery.ShouldAttack");
		#endif

		MarkNativeAsOptional("IContextualQuery.IsHindrance");
		MarkNativeAsOptional("IContextualQuery.SelectTargetPoint");
		MarkNativeAsOptional("IContextualQuery.IsPositionAllowed");

		#if defined GAME_L4D2
		MarkNativeAsOptional("IContextualQuery.QueryCurrentPath");
		#endif

		MarkNativeAsOptional("IContextualQuery.SelectMoreDangerousThreat");

		#if defined GAME_TF2
		MarkNativeAsOptional("CKnownEntity.Destroy");
		MarkNativeAsOptional("CKnownEntity.UpdatePosition");
		MarkNativeAsOptional("CKnownEntity.GetEntity");
		MarkNativeAsOptional("CKnownEntity.GetLastKnownPosition");
		MarkNativeAsOptional("CKnownEntity.HasLastKnownPositionBeenSeen");
		MarkNativeAsOptional("CKnownEntity.MarkLastKnownPositionAsSeen");
		MarkNativeAsOptional("CKnownEntity.GetLastKnownArea");
		MarkNativeAsOptional("CKnownEntity.GetTimeSinceLastKnown");
		MarkNativeAsOptional("CKnownEntity.GetTimeSinceBecameKnown");
		MarkNativeAsOptional("CKnownEntity.UpdateVisibilityStatus");
		MarkNativeAsOptional("CKnownEntity.IsVisibleInFOVNow");
		MarkNativeAsOptional("CKnownEntity.IsVisibleRecently");
		MarkNativeAsOptional("CKnownEntity.GetTimeSinceBecameVisible");
		MarkNativeAsOptional("CKnownEntity.GetTimeWhenBecameVisible");
		MarkNativeAsOptional("CKnownEntity.GetTimeSinceLastSeen");
		MarkNativeAsOptional("CKnownEntity.WasEverVisible");
		MarkNativeAsOptional("CKnownEntity.IsObsolete");
		MarkNativeAsOptional("CKnownEntity.Is");
		#endif

		MarkNativeAsOptional("INextBot.Reset");
		MarkNativeAsOptional("INextBot.Update");
		MarkNativeAsOptional("INextBot.Upkeep");
		MarkNativeAsOptional("INextBot.IsRemovedOnReset");
		MarkNativeAsOptional("INextBot.GetEntity");
		MarkNativeAsOptional("INextBot.GetNextBotCombatCharacter");
		#if defined GAME_L4D2
		MarkNativeAsOptional("INextBot.MySurvivorBotPointer");
		#endif
		MarkNativeAsOptional("INextBot.GetLocomotionInterface");
		MarkNativeAsOptional("INextBot.GetBodyInterface");
		MarkNativeAsOptional("INextBot.GetIntentionInterface");
		MarkNativeAsOptional("INextBot.GetVisionInterface");
		MarkNativeAsOptional("INextBot.SetPosition");
		MarkNativeAsOptional("INextBot.GetPosition");
		MarkNativeAsOptional("INextBot.IsEnemy");
		MarkNativeAsOptional("INextBot.IsFriend");
		MarkNativeAsOptional("INextBot.IsSelf");
		MarkNativeAsOptional("INextBot.IsAbleToClimbOnto");
		MarkNativeAsOptional("INextBot.IsAbleToBreak");
		MarkNativeAsOptional("INextBot.ShouldTouch");
		#if defined GAME_L4D2
		MarkNativeAsOptional("INextBot.ReactToSurvivorVisibility");
		MarkNativeAsOptional("INextBot.ReactToSurvivorNoise");
		MarkNativeAsOptional("INextBot.ReactToSurvivorContact");
		#endif
		MarkNativeAsOptional("INextBot.IsImmobile");
		MarkNativeAsOptional("INextBot.GetImmobileDuration");
		MarkNativeAsOptional("INextBot.ClearImmobileStatus");
		MarkNativeAsOptional("INextBot.GetImmobileSpeedThreshold");
		#if defined GAME_TF2
		MarkNativeAsOptional("INextBot.GetCurrentPath");
		MarkNativeAsOptional("INextBot.SetCurrentPath");
		MarkNativeAsOptional("INextBot.NotifyPathDestruction");
		#endif
		MarkNativeAsOptional("INextBot.IsRangeLessThan");
		MarkNativeAsOptional("INextBot.IsRangeLessThanEx");
		MarkNativeAsOptional("INextBot.IsRangeGreaterThan");
		MarkNativeAsOptional("INextBot.IsRangeGreaterThanEx");
		MarkNativeAsOptional("INextBot.GetRangeTo");
		MarkNativeAsOptional("INextBot.GetRangeToEx");
		MarkNativeAsOptional("INextBot.GetRangeSquaredTo");
		MarkNativeAsOptional("INextBot.GetRangeSquaredToEx");
		#if defined GAME_L4D2
		MarkNativeAsOptional("INextBot.Get2DRangeTo");
		MarkNativeAsOptional("INextBot.Get2DRangeToEx");
		#endif
		MarkNativeAsOptional("INextBot.IsDebugging");
		MarkNativeAsOptional("INextBot.GetDebugIdentifier");
		MarkNativeAsOptional("INextBot.IsDebugFilterMatch");
		MarkNativeAsOptional("INextBot.DisplayDebugText");

		#if defined GAME_TF2
		MarkNativeAsOptional("IVision.ForEachKnownEntity");
		MarkNativeAsOptional("IVision.CollectKnownEntities");
		MarkNativeAsOptional("IVision.GetPrimaryKnownThreat");
		MarkNativeAsOptional("IVision.GetClosestKnown");
		MarkNativeAsOptional("IVision.GetKnownCount");
		MarkNativeAsOptional("IVision.GetClosestKnownEx");
		MarkNativeAsOptional("IVision.GetKnown");
		MarkNativeAsOptional("IVision.AddKnownEntity");
		MarkNativeAsOptional("IVision.ForgetEntity");
		MarkNativeAsOptional("IVision.ForgetAllKnownEntities");
		MarkNativeAsOptional("IVision.CollectPotentiallyVisibleEntities");
		#endif

		MarkNativeAsOptional("IVision.GetTimeSinceVisible");

		#if defined GAME_L4D2
		MarkNativeAsOptional("IVision.GetClosestRecognized");
		MarkNativeAsOptional("IVision.GetRecognizedCount");
		MarkNativeAsOptional("IVision.GetClosestRecognizedEx");
		#endif

		MarkNativeAsOptional("IVision.GetMaxVisionRange");
		MarkNativeAsOptional("IVision.GetMinRecognizeTime");
		MarkNativeAsOptional("IVision.IsAbleToSee");
		MarkNativeAsOptional("IVision.IsAbleToSeeEx");
		MarkNativeAsOptional("IVision.IsIgnored");

		#if defined GAME_TF2
		MarkNativeAsOptional("IVision.IsVisibleEntityNoticed");
		#endif

		MarkNativeAsOptional("IVision.IsInFieldOfView");
		MarkNativeAsOptional("IVision.IsInFieldOfViewEx");
		MarkNativeAsOptional("IVision.GetDefaultFieldOfView");
		MarkNativeAsOptional("IVision.GetFieldOfView");
		MarkNativeAsOptional("IVision.SetFieldOfView");
		MarkNativeAsOptional("IVision.IsLineOfSightClear");
		MarkNativeAsOptional("IVision.IsLineOfSightClearToEntity");
		MarkNativeAsOptional("IVision.IsLookingAt");
		MarkNativeAsOptional("IVision.IsLookingAtEx");

		MarkNativeAsOptional("IBody.SetPosition");
		MarkNativeAsOptional("IBody.GetEyePosition");
		MarkNativeAsOptional("IBody.GetViewVector");
		MarkNativeAsOptional("IBody.AimHeadTowards");
		MarkNativeAsOptional("IBody.AimHeadTowardsEx");
		MarkNativeAsOptional("IBody.IsHeadAimingOnTarget");
		MarkNativeAsOptional("IBody.IsHeadSteady");
		MarkNativeAsOptional("IBody.GetHeadSteadyDuration");
		MarkNativeAsOptional("IBody.GetHeadAimSubjectLeadTime");
		MarkNativeAsOptional("IBody.GetHeadAimTrackingInterval");
		MarkNativeAsOptional("IBody.ClearPendingAimReply");
		MarkNativeAsOptional("IBody.GetMaxHeadAngularVelocity");
		MarkNativeAsOptional("IBody.StartActivity");
		MarkNativeAsOptional("IBody.SelectAnimationSequence");
		MarkNativeAsOptional("IBody.GetActivity");
		MarkNativeAsOptional("IBody.IsActivity");
		MarkNativeAsOptional("IBody.HasActivityType");
		MarkNativeAsOptional("IBody.SetDesiredPosture");
		MarkNativeAsOptional("IBody.GetDesiredPosture");
		MarkNativeAsOptional("IBody.IsDesiredPosture");
		MarkNativeAsOptional("IBody.IsInDesiredPosture");
		MarkNativeAsOptional("IBody.GetActualPosture");
		MarkNativeAsOptional("IBody.IsActualPosture");
		MarkNativeAsOptional("IBody.IsPostureMobile");
		MarkNativeAsOptional("IBody.IsPostureChanging");
		MarkNativeAsOptional("IBody.SetArousal");
		MarkNativeAsOptional("IBody.GetArousal");
		MarkNativeAsOptional("IBody.IsArousal");
		MarkNativeAsOptional("IBody.GetHullWidth");
		MarkNativeAsOptional("IBody.GetHullHeight");
		MarkNativeAsOptional("IBody.GetStandHullHeight");
		MarkNativeAsOptional("IBody.GetCrouchHullHeight");
		MarkNativeAsOptional("IBody.GetHullMins");
		MarkNativeAsOptional("IBody.GetHullMaxs");
		MarkNativeAsOptional("IBody.GetSolidMask");
		MarkNativeAsOptional("IBody.GetCollisionGroup");
		#if defined GAME_L4D2
		MarkNativeAsOptional("IBody.GetEntity");
		#endif

		MarkNativeAsOptional("ILocomotion.Approach");
		MarkNativeAsOptional("ILocomotion.DriveTo");
		MarkNativeAsOptional("ILocomotion.ClimbUpToLedge");
		MarkNativeAsOptional("ILocomotion.JumpAcrossGap");
		MarkNativeAsOptional("ILocomotion.Jump");
		MarkNativeAsOptional("ILocomotion.IsClimbingOrJumping");
		MarkNativeAsOptional("ILocomotion.IsClimbingUpToLedge");
		MarkNativeAsOptional("ILocomotion.IsJumpingAcrossGap");
		MarkNativeAsOptional("ILocomotion.IsScrambling");
		MarkNativeAsOptional("ILocomotion.Run");
		MarkNativeAsOptional("ILocomotion.Walk");
		MarkNativeAsOptional("ILocomotion.Stop");
		MarkNativeAsOptional("ILocomotion.IsRunning");
		MarkNativeAsOptional("ILocomotion.SetDesiredSpeed");
		MarkNativeAsOptional("ILocomotion.GetDesiredSpeed");
		MarkNativeAsOptional("ILocomotion.SetSpeedLimit");
		MarkNativeAsOptional("ILocomotion.GetSpeedLimit");
		MarkNativeAsOptional("ILocomotion.IsOnGround");
		MarkNativeAsOptional("ILocomotion.GetGround");
		MarkNativeAsOptional("ILocomotion.GetGroundNormal");
		MarkNativeAsOptional("ILocomotion.GetGroundSpeed");
		MarkNativeAsOptional("ILocomotion.GetGroundMotionVector");
		MarkNativeAsOptional("ILocomotion.ClimbLadder");
		MarkNativeAsOptional("ILocomotion.DescendLadder");
		MarkNativeAsOptional("ILocomotion.IsUsingLadder");
		MarkNativeAsOptional("ILocomotion.IsAscendingOrDescendingLadder");
		MarkNativeAsOptional("ILocomotion.IsAbleToAutoCenterOnLadder");
		MarkNativeAsOptional("ILocomotion.FaceTowards");
		MarkNativeAsOptional("ILocomotion.SetDesiredLean");
		MarkNativeAsOptional("ILocomotion.GetDesiredLean");
		#if defined GAME_TF2
		MarkNativeAsOptional("ILocomotion.IsAbleToJumpAcrossGaps");
		MarkNativeAsOptional("ILocomotion.IsAbleToClimb");
		#endif
		MarkNativeAsOptional("ILocomotion.GetFeet");
		MarkNativeAsOptional("ILocomotion.GetStepHeight");
		MarkNativeAsOptional("ILocomotion.GetMaxJumpHeight");
		MarkNativeAsOptional("ILocomotion.GetDeathDropHeight");
		MarkNativeAsOptional("ILocomotion.GetRunSpeed");
		MarkNativeAsOptional("ILocomotion.GetWalkSpeed");
		#if defined GAME_TF2
		MarkNativeAsOptional("ILocomotion.GetMaxAcceleration");
		MarkNativeAsOptional("ILocomotion.GetMaxDeceleration");
		#endif
		MarkNativeAsOptional("ILocomotion.GetVelocity");
		MarkNativeAsOptional("ILocomotion.GetSpeed");
		MarkNativeAsOptional("ILocomotion.GetMotionVector");
		MarkNativeAsOptional("ILocomotion.IsAreaTraversable");
		MarkNativeAsOptional("ILocomotion.GetTraversableSlopeLimit");
		MarkNativeAsOptional("ILocomotion.IsPotentiallyTraversable");
		MarkNativeAsOptional("ILocomotion.HasPotentialGap");
		MarkNativeAsOptional("ILocomotion.IsGap");
		MarkNativeAsOptional("ILocomotion.IsEntityTraversable");
		MarkNativeAsOptional("ILocomotion.IsStuck");
		MarkNativeAsOptional("ILocomotion.GetStuckDuration");
		MarkNativeAsOptional("ILocomotion.ClearStuckStatus");
		MarkNativeAsOptional("ILocomotion.IsAttemptingToMove");
		#if defined GAME_TF2
		MarkNativeAsOptional("ILocomotion.ShouldCollideWith");
		#endif
		MarkNativeAsOptional("ILocomotion.AdjustPosture");
		#if defined GAME_TF2
		MarkNativeAsOptional("ILocomotion.StuckMonitor");
		#endif

		MarkNativeAsOptional("Path.GetLength");
		MarkNativeAsOptional("Path.GetPosition");
		MarkNativeAsOptional("Path.GetStartPosition");
		MarkNativeAsOptional("Path.GetEndPosition");
		MarkNativeAsOptional("Path.GetSubject");
		#if defined GAME_L4D2
		MarkNativeAsOptional("Path.SetSubject");
		#endif
		MarkNativeAsOptional("Path.GetCurrentGoal");
		MarkNativeAsOptional("Path.GetAge");
		MarkNativeAsOptional("Path.MoveCursorToStart");
		MarkNativeAsOptional("Path.MoveCursorToEnd");
		MarkNativeAsOptional("Path.MoveCursor");
		MarkNativeAsOptional("Path.GetCursorPosition");
		MarkNativeAsOptional("Path.GetCursorData");
		MarkNativeAsOptional("Path.IsValid");
		MarkNativeAsOptional("Path.Invalidate");
		MarkNativeAsOptional("Path.Draw");
		MarkNativeAsOptional("Path.DrawInterpolated");
		MarkNativeAsOptional("Path.FirstSegment");
		MarkNativeAsOptional("Path.NextSegment");
		MarkNativeAsOptional("Path.PriorSegment");
		MarkNativeAsOptional("Path.LastSegment");

		MarkNativeAsOptional("PathFollower.Update");
		MarkNativeAsOptional("PathFollower.SetMinLookAheadDistance");
		MarkNativeAsOptional("PathFollower.GetHindrance");
		MarkNativeAsOptional("PathFollower.IsDiscontinuityAhead");

		MarkNativeAsOptional("ChasePath.GetLeadRadius");
		MarkNativeAsOptional("ChasePath.GetMaxPathLength");
		MarkNativeAsOptional("ChasePath.PredictSubjectPosition");
		MarkNativeAsOptional("ChasePath.IsRepathNeeded");
		MarkNativeAsOptional("ChasePath.GetLifetime");
	}
#endif

public Extension __ext_pluginbot = 
{
	name = "pluginbot", 
	file = "pluginbot.ext", 
	
	#if defined AUTOLOAD_EXTENSIONS
		autoload = 1,
	#else
		autoload = 0,
	#endif
	
	#if defined REQUIRE_EXTENSIONS
		required = 1,
	#else
		required = 0,
	#endif
};