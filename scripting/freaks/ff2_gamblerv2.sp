
#define DEBUG

#define PLUGIN_NAME           "ff2_gamblerv2"
#define GAMBLER				  "ff2_gamblerv2"
#define PLUGIN_AUTHOR         "Spookmaster"
#define PLUGIN_DESCRIPTION    "Manages The Gambler V2's abilities."
#define PLUGIN_VERSION        "1.0"
#define PLUGIN_URL            ""


#define CLUBS "utaunt_meteor_parent"
#define SPADES "utaunt_hellpit_parent"
#define DIAMONDS "utaunt_cash_confetti"
#define HEARTS "utaunt_hearts_glow_parent"

#include <sourcemod>
#include <sdktools>
//#include <smlib/clients>
#include <sdkhooks>
#include <freak_fortress_2>
#include <tf2items>
#include <tf2_stocks>
#include <morecolors>
#include <ff2_dynamic_defaults>
#include <entity>
#include <rtd2>
#include <keyvalues>

new particle;
new playerParticle[MAXPLAYERS+1];

#pragma semicolon 1

#define POWERUP "item_powerup_rune"
float OFF_THE_MAP[3] = {16383.0, 16383.0, -16383.0};

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

//The following is an absolute trainwreck of global variables. I am sorry.

bool KeyDown[MAXPLAYERS+1]={false, ...};
bool KeyDown2[MAXPLAYERS+1]={false, ...};
bool nukeCalled = false;
bool rigged = false;
bool allIn = false;
bool reRolling = false;
bool rerollCD = false;
bool speedRoll = false;
bool AllInMenu = false;
bool busted = false;
bool ludicrous = false;
bool wretched = false;
bool shark = false;
bool nightmare = false;
bool wasting = false;
bool frail = false;
bool someoneHasReflect = false; //Necessary to prevent both RED and BLU players having Reflect, otherwise it can cause an infinite loop and hard-crash your server

float instaWin = 0.0;
float cash = 0.0;
float maxCash = 0.0;
float skillCD[10]={0.0, ...};
float skillCost[10]={0.0, ...};
float damageTracker = 0.0;
float finalMultiplier = 0.0;
float chosenSpeed = 0.0;
float speedTime = 0.0;
float healthMultiBLU = 0.0;
float minHealthMult = 0.0;
float maxHealthMult = 0.0;
float finalPercent = 0.0;
float PositivePerkChance = 0.0;
float NegativePerkChance = 0.0;
float perkDur = 0.0;
float finalHackTime = 0.0;
float coinDMG[MAXPLAYERS+1] = {0.0, ...};
float coin_AvgDMG = 0.0;

int gamblerIDX = 0;
int skill = 0;
int rerolls = 0;
int suit[MAXPLAYERS+1]={0, ...};
int setSuit[MAXPLAYERS+1]={0, ...};
int numTargs = 0;
int clubs = 0;
int spades = 0;
int diamonds = 0;
int hearts = 0;
int enemyPowers = 0;
int allyPowers = 0;
int gamblePower = 0;
int targets = 0;
int RTDTime = 0;
int redGood = 0;
int redBad = 0;
int blueGood = 0;
int blueBad = 0;

static char gamblePowerText[256];
static char gambleRTD[256];

RTDPerk rollItNow[MAXPLAYERS+1];

Handle cashRando = INVALID_HANDLE;
Handle speedRando = INVALID_HANDLE;
Handle healSelfRando = INVALID_HANDLE;
Handle damageFoesRando = INVALID_HANDLE;
Handle cardsRando = INVALID_HANDLE;
Handle perkRando = INVALID_HANDLE;
Handle hackRando = INVALID_HANDLE;
Handle diceRando = INVALID_HANDLE;
Handle slotCurse = INVALID_HANDLE;
Handle revertTimer[MAXPLAYERS+1]={INVALID_HANDLE, ...};
//Handle reflectChecker = INVALID_HANDLE;



public void OnPluginStart()
{
	HookEvent("arena_round_start", gamblerStart);
}

public OnMapStart()
{
	PrecacheSound("freak_fortress_2/gamblerv2/gamblerv2_nukesiren.mp3", true);
	PrecacheSound("freak_fortress_2/gamblerv2/gamblerv2_rigged.mp3", true);
	PrecacheSound("mvm/mvm_bomb_explode.wav", true);
	PrecacheSound("misc/rd_finale_beep01.wav", true);
	PrecacheSound("mvm/mvm_bought_upgrade.wav", true);
	PrecacheSound("mvm/mvm_player_died.wav", true);
	PrecacheSound("mvm/mvm_bomb_warning.wav", true);
	PrecacheSound("mvm/mvm_tank_start.wav", true);
	PrecacheSound("mvm/mvm_tele_activate.wav", true);
	PrecacheSound("items/powerup_pickup_supernova.wav", true);
	PrecacheSound("items/powerup_pickup_knockout_melee_hit.wav", true);
	PrecacheSound("player/medic_charged_death.wav", true);
	PrecacheSound("player/invuln_on_vaccinator.wav", true);
	PrecacheSound("weapons/airstrike_fire_crit.wav", true);
	PrecacheSound("weapons/airstrike_small_explosion_03.wav", true);
	PrecacheSound("weapons/rescue_ranger_teleport_send_02.wav", true);
	PrecacheSound("replay/record_fail.wav", true);
	PrecacheSound("mvm/ambient_mp3/mvm_siren.mp3", true);
	PrecacheSound("weapons/diamond_back_01_crit.wav", true);
	PrecacheSound("items/pumpkin_explode3.wav", true);
	PrecacheSound("freak_fortress_2/gamblerv2/gamblerv2_badresult1.mp3", true);
	PrecacheSound("freak_fortress_2/gamblerv2/gamblerv2_badresult2.mp3", true);
	PrecacheSound("freak_fortress_2/gamblerv2/gamblerv2_badresult3.mp3", true);
	PrecacheSound("freak_fortress_2/gamblerv2/gamblerv2_badresult4.mp3", true);
	PrecacheSound("freak_fortress_2/gamblerv2/gamblerv2_badresult5.mp3", true);
	PrecacheSound("freak_fortress_2/gamblerv2/gamblerv2_badresult6.mp3", true);
	PrecacheSound("freak_fortress_2/gamblerv2/gamblerv2_badresult7.mp3", true);
	PrecacheSound("freak_fortress_2/gamblerv2/gamblerv2_badresult8.mp3", true);
	PrecacheSound("freak_fortress_2/gamblerv2/gamblerv2_goodresult1.mp3", true);
	PrecacheSound("freak_fortress_2/gamblerv2/gamblerv2_goodresult2.mp3", true);
	PrecacheSound("freak_fortress_2/gamblerv2/gamblerv2_goodresult3.mp3", true);
	PrecacheSound("freak_fortress_2/gamblerv2/gamblerv2_goodresult4.mp3", true);
	PrecacheSound("freak_fortress_2/gamblerv2/gamblerv2_goodresult5.mp3", true);
	PrecacheSound("freak_fortress_2/gamblerv2/gamblerv2_goodresult6.mp3", true);
	PrecacheSound("freak_fortress_2/gamblerv2/gamblerv2_goodresult7.mp3", true);
	PrecacheSound("freak_fortress_2/gamblerv2/gamblerv2_goodresult8.mp3", true);
}

public void gamblerStart(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			int bossIDX = FF2_GetBossIndex(client);
			if (bossIDX != -1)
			{
				if (FF2_HasAbility(bossIDX, PLUGIN_NAME, GAMBLER))
				{
					KeyDown2[client] = (GetClientButtons(client) & IN_RELOAD) != 0;
					KeyDown[client] = (GetClientButtons(client) & IN_ATTACK3) != 0;
					CreateTimer(0.1, gamblerHUD, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					cash = FF2_GetArgF(bossIDX, PLUGIN_NAME, GAMBLER, "arg100", 100, 0.0);
					maxCash = FF2_GetArgF(bossIDX, PLUGIN_NAME, GAMBLER, "arg104", 104, 0.0);
					instaWin = FF2_GetArgF(bossIDX, PLUGIN_NAME, GAMBLER, "arg105", 105, 0.0);
					nukeCalled = false;
					gamblerIDX = client;
					skill = 0;
					rerolls = FF2_GetArgI(bossIDX, PLUGIN_NAME, GAMBLER, "arg1", 1, 0);
					
					skillCost[0] = 0.0;
					skillCost[1] = FF2_GetArgF(bossIDX, PLUGIN_NAME, GAMBLER, "arg13", 13, 0.0);
					skillCost[2] = FF2_GetArgF(bossIDX, PLUGIN_NAME, GAMBLER, "arg17", 17, 0.0);
					skillCost[3] = FF2_GetArgF(bossIDX, PLUGIN_NAME, GAMBLER, "arg23", 23, 0.0);
					skillCost[4] = FF2_GetArgF(bossIDX, PLUGIN_NAME, GAMBLER, "arg32", 32, 0.0);
					skillCost[5] = FF2_GetArgF(bossIDX, PLUGIN_NAME, GAMBLER, "arg38", 38, 0.0);
					skillCost[6] = FF2_GetArgF(bossIDX, PLUGIN_NAME, GAMBLER, "arg43", 43, 0.0);
					skillCost[7] = FF2_GetArgF(bossIDX, PLUGIN_NAME, GAMBLER, "arg46", 46, 0.0);
					skillCost[8] = 0.0;
					skillCost[9] = FF2_GetArgF(bossIDX, PLUGIN_NAME, GAMBLER, "arg48", 48, 0.0);
					
					SDKHook(gamblerIDX, SDKHook_PreThink, gambler_PreThink);
					
					HookEvent("player_death", player_killed);
					HookEvent("teamplay_round_win", gambleEnd);
				}
			}
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public void gambleEnd(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	UnhookEvent("player_death", player_killed);
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			DeleteParticle(client);
			KeyDown[client] = false;
			KeyDown2[client] = false;
			suit[client] = 0;
			setSuit[client] = 0;
			if (revertTimer[client] != INVALID_HANDLE)
			{
				KillTimer(revertTimer[client]);
			}
			revertTimer[client] = INVALID_HANDLE;
			SDKUnhook(client, SDKHook_PreThink, gambler_PreThink);
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			coinDMG[client] = 0.0;
		}
	}
	
	nukeCalled = false;
	rigged = false;
	allIn = false;
	reRolling = false;
	rerollCD = false;
	speedRoll = false;
	AllInMenu = false;
	busted = false;
	ludicrous = false;
	wretched = false;
	shark = false;
	nightmare = false;
	wasting = false;
	frail = false;
	someoneHasReflect = false;
	
	gamblerIDX = 0;
	skill = 0;
	rerolls = 0;
	numTargs = 0;
	clubs = 0;
	spades = 0;
	diamonds = 0;
	hearts = 0;
	enemyPowers = 0;
	allyPowers = 0;
	gamblePower = 0;
	targets = 0;
	RTDTime = 0;
	redGood = 0;
	redBad = 0;
	blueGood = 0;
	blueBad = 0;
	finalHackTime = 0.0;
	
	instaWin = 0.0;
	cash = 0.0;
	maxCash = 0.0;
	for (int i = 0; i < 10; i++)
	{
		skillCD[i] = 0.0;
		skillCost[i] = 0.0;
	}
	damageTracker = 0.0;
	finalMultiplier = 0.0;
	chosenSpeed = 0.0;
	speedTime = 0.0;
	healthMultiBLU = 0.0;
	minHealthMult = 0.0;
	maxHealthMult = 0.0;
	finalPercent = 0.0;
	perkDur = 0.0;
	PositivePerkChance = 0.0;
	NegativePerkChance = 0.0;
	coin_AvgDMG = 0.0;
	
	
	if (cashRando != INVALID_HANDLE)
	{
		KillTimer(cashRando);
	}
	cashRando = INVALID_HANDLE;
	
	if (speedRando != INVALID_HANDLE)
	{
		KillTimer(speedRando);
	}
	speedRando = INVALID_HANDLE;
	
	if (healSelfRando != INVALID_HANDLE)
	{
		KillTimer(healSelfRando);
	}
	healSelfRando = INVALID_HANDLE;
	
	if (damageFoesRando != INVALID_HANDLE)
	{
		KillTimer(damageFoesRando);
	}
	damageFoesRando = INVALID_HANDLE;
	
	if (cardsRando != INVALID_HANDLE)
	{
		KillTimer(cardsRando);
	}
	cardsRando = INVALID_HANDLE;
	
	if (perkRando != INVALID_HANDLE)
	{
		KillTimer(perkRando);
	}
	perkRando = INVALID_HANDLE;
	
	if (hackRando != INVALID_HANDLE)
	{
		KillTimer(hackRando);
	}
	hackRando = INVALID_HANDLE;
	
	if (diceRando != INVALID_HANDLE)
	{
		KillTimer(diceRando);
	}
	diceRando = INVALID_HANDLE;
	
	if (slotCurse != INVALID_HANDLE)
	{
		KillTimer(slotCurse);
	}
	slotCurse = INVALID_HANDLE;
	
	UnhookEvent("teamplay_round_win", gambleEnd);
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	new bool:keyDown = (buttons & IN_ATTACK3) != 0;
	new bool:keyDown2 = (buttons & IN_RELOAD) != 0;
	if (IsValidClient(gamblerIDX) && IsValidClient(client))
	{
		if (keyDown2 && !KeyDown2[gamblerIDX] && client == gamblerIDX && FF2_GetRoundState() == 1 && !reRolling && !AllInMenu)
		{
			skill++;
			switch(FF2_GetBossLives(FF2_GetBossIndex(gamblerIDX)))
			{
				case 3:
				{
					if (skill >= 3)
					{
						skill = 0;
					}
				}
				case 2:
				{
					if (skill >= 7)
					{
						skill = 0;
					}
				}
				case 1:
				{
					if (skill == 8 && rigged || skill == 8 && FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg700", 700, 0) == 0)
					{
						skill = 9;
					}
					if (skill == 9 && allIn)
					{
						skill = 0;
					}
				}
			}
			if (skill > 9)
			{
				skill = 0;
			}
			EmitSoundToClient(gamblerIDX, "misc/rd_finale_beep01.wav", _, _, _, _, _, SNDPITCH_HIGH);
		}
		if (keyDown && !KeyDown[gamblerIDX] && client == gamblerIDX && FF2_GetRoundState() == 1 && skillCD[skill] <= 0.1 && !reRolling && cash >= skillCost[skill] && !AllInMenu && !allIn)
		{
			if (skill == 6 && GetLivingReds() <= FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg401", 401, 0))
			{
				CPrintToChat(gamblerIDX, "{orange}[赌狗] {red}敌方玩家在 %i 人及以下时无法使用此技能.", FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg401", 401, 0));
				EmitSoundToClient(gamblerIDX, "replay/record_fail.wav");
			}
			else
			{
				if (skill == 8)
				{
					cash += skillCost[9];
				}
				activateSkill(skill);
				if (skill != 9)
				{
					cash += -skillCost[skill];
				}
			}
		}
		else if (keyDown && !KeyDown[gamblerIDX] && client == gamblerIDX && FF2_GetRoundState() == 1 && cash < skillCost[skill] || keyDown && !KeyDown[gamblerIDX] && client == gamblerIDX && FF2_GetRoundState() == 1 && skillCD[skill] > 0.1)
		{
			EmitSoundToClient(gamblerIDX, "replay/record_fail.wav");
		}
		KeyDown[client] = keyDown;
		KeyDown2[client] = keyDown2;
	}
}




public void activateSkill(int ability)
{
	if (IsValidClient(gamblerIDX))
	{
		int gambleBoss = FF2_GetBossIndex(gamblerIDX);
		if (gambleBoss != -1 && FF2_HasAbility(gambleBoss, PLUGIN_NAME, GAMBLER))
		{
			float reRollTimeFrame = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg0", 0, 0.0);
			switch(ability)
			{
				case 0:
				{
					float minMultiplier = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg5", 5, 0.0);
					float maxMultiplier = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg6", 6, 0.0);
					finalMultiplier = GetRandomFloat(minMultiplier, maxMultiplier);
					if (rigged && finalMultiplier < 1.0 && FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg701", 701, 0) == 1)
					{
						finalMultiplier += 1.0;
					}
					float result = cash * finalMultiplier;
					if (rerolls > 0 && !rerollCD && !reRolling)
					{
						Menu reRollMenu = new Menu(rollMenu);
						if (result > cash)
						{
							reRollMenu.SetTitle("你将获得约 $%i. 要重骰吗?", RoundFloat(result - cash));
						}
						else
						{
							reRollMenu.SetTitle("你将失去约 $%i. 要重骰吗?", RoundFloat(cash - result));
						}
						reRollMenu.ExitButton = false;
						reRollMenu.AddItem("option1", "给爷骰!");
						reRollMenu.AddItem("option2", "不用了.");
						DisplayMenu(reRollMenu, gamblerIDX, RoundFloat(reRollTimeFrame));
						reRolling = true;
						cashRando = CreateTimer(reRollTimeFrame + 0.1, cancelCashRoll, TIMER_FLAG_NO_MAPCHANGE);
					}
					else
					{
						if (result < cash)
						{
							CPrintToChat(gamblerIDX, "{orange}[赌狗] {red}倒霉! 你失去了 $%i. {default}祝你下次好运!", RoundFloat(cash - result));
							EmitSoundToClient(gamblerIDX, "mvm/mvm_player_died.wav");
							PlayBadResult();
						}
						else if (result > cash)
						{
							CPrintToChat(gamblerIDX, "{orange}[赌狗] {green}好! 你获得了 $%i. {default}不要一下子就花光了哦...", RoundFloat(result - cash));
							EmitSoundToClient(gamblerIDX, "mvm/mvm_bought_upgrade.wav");
							PlayGoodResult();
						}
						cash = result;
					}
					skillCD[0] = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg7", 7, 0.0);
				}
				case 1:
				{
					float minSpeed = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg8", 8, 0.0);
					float maxSpeed = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg9", 9, 0.0);
					float minTime = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg10", 10, 0.0);
					float maxTime = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg11", 11, 0.0);
					float baseSpeed = GetEntPropFloat(gamblerIDX, Prop_Send, "m_flMaxspeed");
					chosenSpeed = GetRandomFloat(minSpeed, maxSpeed);
					if (FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg702", 702, 0) == 1 && rigged)
					{
						while (chosenSpeed <= baseSpeed)
						{
							chosenSpeed = GetRandomFloat(minSpeed, maxSpeed);
						}
					}
					speedTime = GetRandomFloat(minTime, maxTime);
					
					float displaySpeed = chosenSpeed/GetEntPropFloat(gamblerIDX, Prop_Send, "m_flMaxspeed");
					if (rerolls > 0 && !rerollCD && !reRolling)
					{
						Menu reRollMenu = new Menu(rollMenu);
						if (displaySpeed > 1.0)
						{
							reRollMenu.SetTitle("你将获得百分之 %i 的加速  %i 秒. 你要重骰吗?", RoundFloat((displaySpeed - 1.0) * 100.0), RoundFloat(speedTime));
						}
						else
						{
							reRollMenu.SetTitle("你将获得百分之 %i的减速  %i 秒. 你要重骰吗?", RoundFloat((1.0 - displaySpeed) * 100.0), RoundFloat(speedTime));
						}
						reRollMenu.ExitButton = false;
						reRollMenu.AddItem("option1", "给爷骰!");
						reRollMenu.AddItem("option2", "不用了.");
						DisplayMenu(reRollMenu, gamblerIDX, RoundFloat(reRollTimeFrame));
						reRolling = true;
						speedRando = CreateTimer(reRollTimeFrame + 0.1, cancelSpeedRoll, TIMER_FLAG_NO_MAPCHANGE);
					}
					else
					{
						if (displaySpeed > 1.0)
						{
							CPrintToChat(gamblerIDX, "{orange}[赌狗] {green}好! 你将获得百分之 %i的加速  %i 秒. {default}疾驰如风!", RoundFloat((displaySpeed - 1.0) * 100.0), RoundFloat(speedTime));
							EmitSoundToAll("mvm/mvm_tele_activate.wav", gamblerIDX);
							PlayGoodResult();
						}
						else
						{
							CPrintToChat(gamblerIDX, "{orange}[赌狗] {red}倒霉! 你将获得百分之 %i的减速  %i 秒. {default}好好享受吧!", RoundFloat((1.0 - displaySpeed) * 100.0), RoundFloat(speedTime));
							EmitSoundToAll("mvm/mvm_tank_start.wav", gamblerIDX);
							PlayBadResult();
						}
						speedRoll = true;
						//SDKHook(gamblerIDX, SDKHook_PreThink, gambler_PreThink);
						CreateTimer(speedTime, endSpeed, _, TIMER_FLAG_NO_MAPCHANGE);
					}
					skillCD[1] = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg12", 12, 0.0);
				}
				case 2:
				{
					float minMult = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg14", 14, 0.0);
					float maxMult = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg15", 15, 0.0);
					healthMultiBLU = GetRandomFloat(minMult, maxMult);
					if (FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg703", 703, 0) == 1 && rigged)
					{
						while (healthMultiBLU < 0.0)
						{
							healthMultiBLU = GetRandomFloat(minMult, maxMult);
						}
					}
					if (rerolls > 0 && !rerollCD && !reRolling)
					{
						Menu reRollMenu = new Menu(rollMenu);
						if (healthMultiBLU >= 0.0)
						{
							reRollMenu.SetTitle("你将获得 %i HP. 你要重骰吗?", RoundFloat(healthMultiBLU * FF2_GetBossMaxHealth(gambleBoss)));
						}
						else
						{
							reRollMenu.SetTitle("你将失去 %i HP. 你要重骰吗?", -1 * RoundFloat(healthMultiBLU * FF2_GetBossMaxHealth(gambleBoss)));
						}
						reRollMenu.ExitButton = false;
						reRollMenu.AddItem("option1", "给爷骰!");
						reRollMenu.AddItem("option2", "不用了.");
						DisplayMenu(reRollMenu, gamblerIDX, RoundFloat(reRollTimeFrame));
						reRolling = true;
						healSelfRando = CreateTimer(reRollTimeFrame + 0.1, cancelBlueHPRoll, TIMER_FLAG_NO_MAPCHANGE);
					}
					else
					{
						if (healthMultiBLU >= 0.0)
						{
							CPrintToChat(gamblerIDX, "{orange}[赌狗] {green}好! 你获得了 %i HP. {default}笑一笑十年少!", RoundFloat(healthMultiBLU * FF2_GetBossMaxHealth(gambleBoss)));
							EmitSoundToAll("items/powerup_pickup_supernova.wav", gamblerIDX);
							PlayGoodResult();
						}
						else
						{
							CPrintToChat(gamblerIDX, "{orange}[赌狗] {red}倒霉! 你失去了 %i HP. {default}逊欸，你很逊欸?", -1 * RoundFloat(healthMultiBLU * FF2_GetBossMaxHealth(gambleBoss)));
							EmitSoundToAll("items/powerup_pickup_knockout_melee_hit.wav", gamblerIDX);
							PlayBadResult();
						}
						FF2_SetBossHealth(gambleBoss, RoundFloat(FF2_GetBossHealth(gambleBoss) + healthMultiBLU * FF2_GetBossMaxHealth(gambleBoss)));
					}
					skillCD[2] = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg16", 16, 0.0);
				}
				case 3:
				{
					minHealthMult = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg18", 18, 0.0);
					maxHealthMult = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg19", 19, 0.0);
					float minTargPercent = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg20", 20, 0.0);
					float maxTargPercent = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg21", 21, 0.0);
					int minTargets = RoundFloat(minTargPercent * GetLivingReds());
					int maxTargets = RoundFloat(maxTargPercent * GetLivingReds());
					
					if (minTargets < 1)
					{
						minTargets = 1;
					}
					
					numTargs = GetRandomInt(minTargets, maxTargets);
					
					if (rigged && FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg704", 704, 0) == 1)
					{
						while (numTargs < RoundFloat(0.5 * GetLivingReds()))
						{
							numTargs = GetRandomInt(minTargets, maxTargets);
						}
					}
					
					for (int count = 0; count < numTargs; )
					{
						int target = GetRandomInt(1, MaxClients);
						if (IsValidClient(target))
						{
							if (IsPlayerAlive(target) && TF2_GetClientTeam(target) != TF2_GetClientTeam(gamblerIDX) && IsClientConnected(target))
							{
								coinDMG[target] = GetRandomFloat(minHealthMult, maxHealthMult);
								count++;
								if (rigged && FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg704", 704, 0) == 1)
								{
									while (coinDMG[target] <= 0.0)
									{
										coinDMG[target] = GetRandomFloat(minHealthMult, maxHealthMult);
									}
								}
							}
						}
					}
					
					float sum = 0.0;
					float numHit = 0.0;
					
					for (int i = 1; i <= MaxClients; i++)
					{
						if (IsValidClient(i))
						{
							if (coinDMG[i] != 0.0)
							{
								sum += coinDMG[i];
								numHit += 1.0;
							}
						}
					}
					
					coin_AvgDMG = sum/numHit;
					
					if (rerolls > 0 && !rerollCD && !reRolling)
					{
						Menu reRollMenu = new Menu(rollMenu);
						if (coin_AvgDMG >= 0.0)
						{
							reRollMenu.SetTitle("你将对 %i 名玩家造成平均 %i 点伤害。你要重骰吗?", numTargs, RoundFloat(coin_AvgDMG));
						}
						else
						{
							reRollMenu.SetTitle("你将对 %i 名玩家治疗平均 %i 点HP。你要重骰吗?", numTargs, -1*RoundFloat(coin_AvgDMG));
						}
						reRollMenu.ExitButton = false;
						reRollMenu.AddItem("option1", "给爷骰!");
						reRollMenu.AddItem("option2", "不用了.");
						DisplayMenu(reRollMenu, gamblerIDX, RoundFloat(reRollTimeFrame));
						reRolling = true;
						damageFoesRando = CreateTimer(reRollTimeFrame + 0.1, cancelTargRoll, TIMER_FLAG_NO_MAPCHANGE);
					}
					else
					{
						//bool isHit[MAXPLAYERS+1]={false, ...};
						for (int target = 1; target <= MaxClients; target++)
						{
							if (IsValidClient(target))
							{
								if (IsPlayerAlive(target) && TF2_GetClientTeam(target) != TF2_GetClientTeam(gamblerIDX) && IsClientConnected(target))
								{
									if (coinDMG[target] > 0.0)
									{
										EmitSoundToAll("player/medic_charged_death.wav", target);
										SDKHooks_TakeDamage(target, gamblerIDX, gamblerIDX, coinDMG[target]);
										damageTracker += coinDMG[target] * FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg200", 200, 0.0);
										float dmgToGain = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg2", 2, 0.0);
										while (damageTracker >= dmgToGain)
										{
											damageTracker += -dmgToGain;
											rerolls++;
											if (rerolls >= FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg3", 3, 0))
											{
												rerolls = FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg3", 3, 0);
											}
										}
										CPrintToChat(target, "{orange}[赌狗] {red}你被赌狗的生死硬币击中了! {default}哎呀, 是{red}死{default}面向上，你受到了{red}%i 点伤害 {default}。 很痛吧哈哈!", RoundFloat(coinDMG[target]));
									}
									else if (coinDMG[target] < 0.0)
									{
										EmitSoundToAll("player/invuln_on_vaccinator.wav", target, _, _, _, _, SNDPITCH_HIGH);
										SetEntityHealth(target, RoundFloat(GetClientHealth(target) + -1.0*coinDMG[target]));
										CPrintToChat(target, "{orange}[赌狗] {red}你被赌狗的生死硬币击中了! {default}嗯？ 竟然是{green}生{default}，你受到{green} %i 点治疗 {default}。 焕然一新!", -1 * RoundFloat(coinDMG[target]));
									}
								}
							}
							coinDMG[target] = 0.0;
						}
						if (coin_AvgDMG >= 0.0)
						{
							CPrintToChat(gamblerIDX, "{orange}[赌狗] {default} 你击中了{yellow}%i 名玩家, 平均造成{green}%i 点伤害. {default}你这些硬币是用什么做的?", numTargs, RoundFloat(coin_AvgDMG));
							PlayGoodResult();
						}
						else
						{
							CPrintToChat(gamblerIDX, "{orange}[赌狗] {default} 你击中了{yellow}%i 名玩家, 平均造成{red}%i 点治疗. {default}哈哈!", numTargs, -1*RoundFloat(coin_AvgDMG));
							PlayBadResult();
						}
					}
					skillCD[3] = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg22", 22, 0.0);
				}
				case 4:
				{
					clubs = 0;
					spades = 0;
					diamonds = 0;
					hearts = 0;
					int maxtargets = GetLivingReds();
					for (int i = 1; i <= maxtargets; i++)
					{
						if (IsValidClient(i))
						{
							if (IsPlayerAlive(i) && TF2_GetClientTeam(i) != TF2_GetClientTeam(gamblerIDX) && IsClientConnected(i) && setSuit[i] == 0)
							{
								setSuit[i] = GetRandomInt(1, 4);
								switch (setSuit[i])
								{
									case 1:
									{
										clubs++;
									}
									case 2:
									{
										spades++;
									}
									case 3:
									{
										diamonds++;
									}
									case 4:
									{
										hearts++;
									}
								}
							}
						}
					}
					if (rerolls > 0 && !rerollCD && !reRolling)
					{
						Menu reRollMenu = new Menu(rollMenu);
						reRollMenu.SetTitle("结果统计: %i 梅花, %i 黑桃, %i 方块, %i 红心. 你要重骰吗?", clubs, spades, diamonds, hearts);
						reRollMenu.ExitButton = false;
						reRollMenu.AddItem("option1", "给爷骰!");
						reRollMenu.AddItem("option2", "不用了.");
						DisplayMenu(reRollMenu, gamblerIDX, RoundFloat(reRollTimeFrame));
						reRolling = true;
						cardsRando = CreateTimer(reRollTimeFrame + 0.1, cancelSuitRoll, TIMER_FLAG_NO_MAPCHANGE);
					}
					else
					{
						for (int g = 1; g <= MaxClients; g++)
						{
							if (IsValidClient(g))
							{
								if (IsPlayerAlive(g) && TF2_GetClientTeam(g) != TF2_GetClientTeam(gamblerIDX) && IsClientConnected(g))
								{
									suit[g] = setSuit[g];
									setSuit[g] = 0;
									switch (suit[g])
									{
										case 1:
										{
											CPrintToChat(g, "{orange}[赌狗] {default}你的花色是{purple}梅花! {default}效果: {red}死亡后你会爆炸，对周围造成 %i 点伤害.", RoundFloat(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg24", 24, 0.0)));
											attachParticle(g, CLUBS);
										}
										case 2:
										{
											CPrintToChat(g, "{orange}[赌狗] {default}你的花色是{purple}黑桃! {default}效果: {red}你受到的伤害增加 %i倍. {default}小心了!", RoundFloat(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg25", 25, 0.0)));
											attachParticle(g, SPADES);
										}
										case 3:
										{
											CPrintToChat(g, "{orange}[赌狗] {default}你的花色是{purple}方块! {default}效果: {red}赌狗在你存活时每秒获得 $%i , 在你死亡时获得 $%i . {default}至少你能产生价值...", RoundFloat(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg26", 26, 0.0)), RoundFloat(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg27", 27, 0.0)));
											attachParticle(g, DIAMONDS);
										}
										case 4:
										{
											CPrintToChat(g, "{orange}[赌狗] {default}你的花色是{purple}红心! {default}效果: {red}你死亡时, 赌狗将会获得随机百分于其最大生命值的治疗效果. {default}不惜代价存活下去!", RoundFloat(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg25", 25, 0.0)));
											attachParticle(g, HEARTS);
										}
									}
								}
							}
						}
						CPrintToChat(gamblerIDX, "{orange}[赌狗] {default}完成! 现存:{yellow} %i 梅花, %i 黑桃, %i 方块, 还有 %i 红心.", clubs, spades, diamonds, hearts);
						CreateTimer(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg30", 30, 0.0), endSuits, _, TIMER_FLAG_NO_MAPCHANGE);
						PlayGoodResult();
					}
					skillCD[4] = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg31", 31, 0.0);
				}
				case 5:
				{
					float minDur = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg33", 33, 0.0);
					float maxDur = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg34", 34, 0.0);
					float baseChance = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg35", 35, 0.0);
					float chanceDecrease = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg36", 36, 0.0);
					
					float a = baseChance;
					float b = GetRandomFloat(0.0, 1.0);
					enemyPowers = 0;
					
					while (b <= a && enemyPowers < GetLivingReds())
					{
						enemyPowers++;
						a += -chanceDecrease;
						if (a <= 0.0)
						{
							a = 0.0;
						}
						b = GetRandomFloat(0.0, 1.0);
					}
					
					if (rigged && FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg706", 706, 0) == 1)
					{
						enemyPowers = 0;
					}
					
					a = baseChance;
					b = GetRandomFloat(0.0, 1.0);
					allyPowers = 0;
					while (b <= a && allyPowers < GetLivingBlues() - 1)
					{
						allyPowers++;
						a += -chanceDecrease;
						if (a <= 0.0)
						{
							a = 0.0;
						}
						b = GetRandomFloat(0.0, 1.0);
					}
					
					perkDur = GetRandomFloat(minDur, maxDur);
					if (FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg706", 706, 0) == 1 && rigged)
					{
						while (perkDur < 0.5 * maxDur)
						{
							perkDur = GetRandomFloat(minDur, maxDur);
						}
					}
					
					
					switch (GetRandomInt(1, 9))
					{
						case 1:
						{
							Format(gamblePowerText, sizeof(gamblePowerText), "Strength");
							gamblePower = 1;
						}
						case 2:
						{
							Format(gamblePowerText, sizeof(gamblePowerText), "Haste");
							gamblePower = 2;
						}
						case 3:
						{
							Format(gamblePowerText, sizeof(gamblePowerText), "Regen");
							gamblePower = 3;
						}
						case 4:
						{
							Format(gamblePowerText, sizeof(gamblePowerText), "Resistance");
							gamblePower = 4;
						}
						case 5:
						{
							Format(gamblePowerText, sizeof(gamblePowerText), "Vampire");
							gamblePower = 5;
						}
						case 6:
						{
							Format(gamblePowerText, sizeof(gamblePowerText), "Reflect");
							someoneHasReflect = true;
							gamblePower = 6;
						}
						case 7:
						{
							Format(gamblePowerText, sizeof(gamblePowerText), "Precision");
							gamblePower = 7;
						}
						case 8:
						{
							Format(gamblePowerText, sizeof(gamblePowerText), "Agility");
							gamblePower = 8;
						}
						case 9:
						{
							Format(gamblePowerText, sizeof(gamblePowerText), "Knockout");
							gamblePower = 9;
						}
					}
					if (rerolls > 0 && !rerollCD && !reRolling)
					{
						Menu reRollMenu = new Menu(rollMenu);
						reRollMenu.SetTitle("你将获得: %s. 同时, %i 个队友和 %i 个敌人也会获得同样的BUFF %i 秒. 你要重骰吗?", gamblePowerText, allyPowers, enemyPowers, RoundFloat(perkDur));
						reRollMenu.ExitButton = false;
						reRollMenu.AddItem("option1", "给爷骰!");
						reRollMenu.AddItem("option2", "不用了.");
						DisplayMenu(reRollMenu, gamblerIDX, RoundFloat(reRollTimeFrame));
						reRolling = true;
						perkRando = CreateTimer(reRollTimeFrame + 0.1, cancelPowerRoll, TIMER_FLAG_NO_MAPCHANGE);
					}
					else
					{
						//CPrintToChatAll("{orange}[赌狗] {default}This... uh... it hasn't been coded yet. This is awkward.");
						switch(gamblePower)
						{
							case 1:
							{
								TF2_AddCondition(gamblerIDX, TFCond_RuneStrength, perkDur);
							}
							case 2:
							{
								TF2_AddCondition(gamblerIDX, TFCond_RuneHaste, perkDur);
							}
							case 3:
							{
								TF2_AddCondition(gamblerIDX, TFCond_RuneRegen, perkDur);
							}
							case 4:
							{
								TF2_AddCondition(gamblerIDX, TFCond_RuneResist, perkDur);
							}
							case 5:
							{
								TF2_AddCondition(gamblerIDX, TFCond_RuneVampire, perkDur);
							}
							case 6:
							{
								TF2_AddCondition(gamblerIDX, TFCond_RuneWarlock, perkDur);
								someoneHasReflect = true;
							}
							case 7:
							{
								TF2_AddCondition(gamblerIDX, TFCond_RunePrecision, perkDur);
								if (FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg304", 304, 0) == 1)
								{
									static char precGun[256];
									FF2_GetArgS(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg305", 305, precGun, sizeof(precGun));
									FF2_SpawnWeapon(gamblerIDX, "tf_weapon_revolver", 61, 77, 3, precGun, true);
									CreateTimer(perkDur + 0.1, removePrecGun, TIMER_FLAG_NO_MAPCHANGE);
								}
							}
							case 8:
							{
								TF2_AddCondition(gamblerIDX, TFCond_RuneAgility, perkDur);
							}
							case 9:
							{
								TF2_AddCondition(gamblerIDX, TFCond_RuneKnockout, perkDur);
							}
						}
						if (enemyPowers > GetLivingReds())
						{
							enemyPowers = GetLivingReds();
						}
						
						int i = 0;
						while(i < enemyPowers)
						{
							int powerA = GetRandomInt(1, MaxClients);
							{
								if (IsValidClient(powerA))
								{
									if (IsPlayerAlive(powerA) && TF2_GetClientTeam(powerA) != TF2_GetClientTeam(gamblerIDX) && IsClientConnected(powerA) && FF2_GetBossIndex(powerA) == -1)
									{
										GiveRandomMannpower(powerA, perkDur);
										EmitSoundToClient(powerA, "weapons/rescue_ranger_teleport_send_02.wav");
										CPrintToChat(powerA, "{orange}[赌狗] {default}你获得了增益效果!");
										i++;
									}
								}
							}
						}		
						i = 0;		
						if (allyPowers > GetLivingBlues() - 1)
						{
							allyPowers = GetLivingBlues() - 1;
						}	
						while(i < allyPowers)
						{
							int powerB = GetRandomInt(1, MaxClients);
							{
								if (IsValidClient(powerB))
								{
									if (IsPlayerAlive(powerB) && TF2_GetClientTeam(powerB) == TF2_GetClientTeam(gamblerIDX) && IsClientConnected(powerB) && FF2_GetBossIndex(powerB) == -1)
									{
										GiveRandomMannpower(powerB, perkDur);
										EmitSoundToClient(powerB, "weapons/rescue_ranger_teleport_send_02.wav");
										CPrintToChat(powerB, "{orange}[赌狗] {default}你获得了增益效果!");
										i++;
									}
								}
							}
						}	
						if (enemyPowers > allyPowers)
						{
							PlayBadResult();
						}
						else
						{
							PlayGoodResult();
						}
						CPrintToChat(gamblerIDX, "{orange}[赌狗] {green}好! {default}你获得了 {purple}%s, {default}同时 {green}%i 名队友 {default}和 {red}%i 名敌人 {default}也获取了增益. 增益将持续 %i 秒.", gamblePowerText, allyPowers, enemyPowers, RoundFloat(perkDur));
					}
					CreateTimer(perkDur, checkReflect, _, TIMER_FLAG_NO_MAPCHANGE);
					skillCD[5] = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg37", 37, 0.0);
					//GetRandomLivingNonBoss(7, TFTeam_Red);
				}
				case 6:
				{
					float minHacks = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg39", 39, 0.0);
					float maxHacks = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg40", 40, 0.0);
					float minHackTime = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg402", 402, 0.0);
					float maxHackTime = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg403", 403, 0.0);
					//float uberDur = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg41", 41, 0.0);
					
					finalPercent = GetRandomFloat(minHacks, maxHacks);
					finalHackTime = GetRandomFloat(minHackTime, maxHackTime);
					if (rigged && FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg707", 707, 0) == 1)
					{
						while (finalPercent < maxHacks * 0.5)
						{
							finalPercent = GetRandomFloat(minHacks, maxHacks);
						}
						while (finalHackTime < maxHackTime * 0.5)
						{
							finalHackTime = GetRandomFloat(minHackTime, maxHackTime);
						}
					}
					targets = RoundFloat(finalPercent * GetLivingReds());
					
					if (rerolls > 0 && !rerollCD && !reRolling)
					{
						Menu reRollMenu = new Menu(rollMenu);
						reRollMenu.SetTitle("百分之%i的敌方 (%i players) 将被转化为你的队友 %i 秒. 你要重骰吗?", RoundFloat(finalPercent * 100.0), targets, RoundFloat(finalHackTime));
						reRollMenu.ExitButton = false;
						reRollMenu.AddItem("option1", "给爷骰!");
						reRollMenu.AddItem("option2", "不用了.");
						DisplayMenu(reRollMenu, gamblerIDX, RoundFloat(reRollTimeFrame));
						reRolling = true;
						hackRando = CreateTimer(reRollTimeFrame + 0.1, cancelHackRoll, TIMER_FLAG_NO_MAPCHANGE);
					}
					else
					{
						if (targets >= GetLivingReds())
						{
							targets = GetLivingReds() - 1;
						}
						for (int hackCount = 0; hackCount < targets; )
						{
							int hackTarg = GetRandomInt(1, MaxClients);
							if (IsValidClient(hackTarg))
							{
								if (IsPlayerAlive(hackTarg) && TF2_GetClientTeam(hackTarg) != TF2_GetClientTeam(gamblerIDX))
								{
									hackPlayer(hackTarg, TF2_GetClientTeam(gamblerIDX));
									revertTimer[hackTarg] = CreateTimer(finalHackTime, revertHack, hackTarg, TIMER_FLAG_NO_MAPCHANGE);
									hackCount++;
								}
							}
						}
						CPrintToChat(gamblerIDX, "{orange}[赌狗] {green}好! {default}你雇佣了{green}%i 名玩家{default}为你而战{green}%i 秒.", targets, RoundFloat(finalHackTime));
						if (finalPercent < maxHacks * 0.5)
						{
							PlayBadResult();
						}
						else
						{
							PlayGoodResult();
						}
					}
					skillCD[6] = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg42", 42, 0.0);
				}
				case 7:
				{
					int minRTD = FF2_GetArgI(gambleBoss, PLUGIN_NAME, GAMBLER, "arg44", 44, 0);
					int maxRTD = FF2_GetArgI(gambleBoss, PLUGIN_NAME, GAMBLER, "arg45", 45, 0);
					RTDTime = GetRandomInt(minRTD, maxRTD);
					redGood = 0;
					redBad = 0;
					blueGood = 0;
					blueBad = 0;
					if (rigged && RTDTime < RoundFloat(maxRTD * 0.5))
					{
						RTDTime = RoundFloat(maxRTD * 0.5);
					}
					for (int client = 1; client <= MaxClients; client++)
					{
						if (IsValidClient(client))
						{
							if (IsPlayerAlive(client))
							{
								char perkID[64];
								int rtdPerk = GetRandomInt(0, 256);
								IntToString(rtdPerk, perkID, sizeof(perkID));
								rollItNow[client] = RTD2_FindPerk(perkID);
								while (!canHavePerk(client, rollItNow[client]))
								{
									rtdPerk = GetRandomInt(0, 256);
									IntToString(rtdPerk, perkID, sizeof(perkID));
									rollItNow[client] = RTD2_FindPerk(perkID);
								}
								if (client == gamblerIDX)
								{
									rollItNow[client].GetName(gambleRTD, sizeof(gambleRTD));
								}
								if (FF2_GetBossIndex(client) == -1)
								{
									switch (TF2_GetClientTeam(client))
									{
										case TFTeam_Red:
										{
											if (rollItNow[client].Good)
											{
												redGood++;
											}
											else
											{
												redBad++;
											}
										}
										case TFTeam_Blue:
										{
											if (rollItNow[client].Good)
											{
												blueGood++;
											}
											else
											{
												blueBad++;
											}
										}
									}
								}
							}
						}
					}
					
					/*Format(gambleRTD, sizeof(gambleRTD), */
					
					if (rerolls > 0 && !rerollCD && !reRolling)
					{
						Menu reRollMenu = new Menu(rollMenu);
						reRollMenu.SetTitle("你的增益效果是: %s. \n%i 名敌人和 %i 名队友也会获得增益. \n%i 名敌人和 %i 名队友会获得减益. \n这些效果将持续 %i秒. 你要重骰吗?", gambleRTD, redGood, blueGood, redBad, blueBad, RTDTime);
						reRollMenu.ExitButton = false;
						reRollMenu.AddItem("option1", "给爷骰!");
						reRollMenu.AddItem("option2", "不用了.");
						DisplayMenu(reRollMenu, gamblerIDX, RoundFloat(reRollTimeFrame));
						reRolling = true;
						diceRando = CreateTimer(reRollTimeFrame + 0.1, cancelRTDRoll, TIMER_FLAG_NO_MAPCHANGE);
					}
					else
					{
						for (int client = 1; client <= MaxClients; client++)
						{
							if (IsValidClient(client))
							{
								if (IsPlayerAlive(client))
								{
									char forcedPerk[256];
									rollItNow[client].GetToken(forcedPerk, sizeof(forcedPerk));
									if (FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg500", 500, 0) == 1)
									{
										RTD2_Remove(client, RTDRemove_Custom, "使用了混沌骰子");
									}
									RTD2_Force(client, forcedPerk, RTDTime);
									if (rollItNow[client].Good)
									{
										CPrintToChat(client, "{orange}[赌狗] {green}走运了! {default}这个{green}增益{default} 将持续 {green}%i 秒.", RTDTime);
										if (client == gamblerIDX)
										{
											PlayGoodResult();
										}
									}
									else
									{
										CPrintToChat(client, "{orange}[赌狗] {red}倒霉! {default}这个{red}减益{default} 将持续 {red}%i 秒.", RTDTime);
										if (client == gamblerIDX)
										{
											PlayBadResult();
										}
									}
								}
							}
						}
						//CPrintToChat(gamblerIDX, "{orange}[赌狗] {yellow}Done! %i allies and %i enemies obtained positive perks, while %i allies and %i enemies obtained negative perks, for %i seconds.", blueGood, redGood, blueBad, redGood);
					}
					skillCD[7] = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg47", 47, 0.0);
				}
				case 8:
				{
					rigged = true;
					CPrintToChat(gamblerIDX, "{orange}[赌狗] {default}真相是... 这场赌局一开始就是被操纵的. {purple}你的所有技能 (不包括ALL-IN) 现在都必定获得正面效果!");
					EmitSoundToAll("freak_fortress_2/gamblerv2/gamblerv2_rigged.mp3");
					for (int i = 1; i <= MaxClients; i++)
					{
						if (IsValidClient(i))
						{
							if (TF2_GetClientTeam(i) != TF2_GetClientTeam(gamblerIDX))
							{
								CPrintToChat(i, "{orange}[赌狗] {red} 注意: 现在赌狗的所有技能必定对他的队伍造成正面效果，对你造成负面效果! {default}很抱歉...");
							}
							else if (FF2_GetBossIndex(i) == -1)
							{
								CPrintToChat(i, "{orange}[赌狗] {green}现在赌狗的所有技能必定对你造成正面效果，对敌方造成负面效果!!");
							}
						}
					}
					if (allIn)
					{
						skill = 0;
					}
					else
					{
						skill = 9;
					}
				}
				case 9:
				{
					float PositiveBase = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg49", 49, 0.0);
					float NegativeBase = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg50", 50, 0.0);
					
					PositivePerkChance = PositiveBase * (cash/skillCost[9]);
					if (PositivePerkChance > 1.0)
					{
						PositivePerkChance = 1.0;
					}
					NegativePerkChance = NegativeBase / (cash/skillCost[9]);
					if (NegativePerkChance < 0.0)
					{
						NegativePerkChance = 0.0;
					}
					
					Menu reRollMenu = new Menu(rollMenu);
					reRollMenu.SetTitle("警告: 一旦你激活此技能就无法回头了! \n你的现金将被 永久 设为0. 你的机会: \n好效果: 百分之%i . \n烂效果: 百分之%i. \n你还要 ALL-IN 吗?", RoundFloat(100.0 * PositivePerkChance), RoundFloat(100.0 * NegativePerkChance));
					reRollMenu.ExitButton = false;
					reRollMenu.AddItem("option1", "ALL-IN！！！");
					reRollMenu.AddItem("option2", "我不要!");
					AllInMenu = true;
					DisplayMenu(reRollMenu, gamblerIDX, 30);
				}
			}
		}
	}
}

//KeyValues CFGKeys=null;

public void PlayBadResult()
{
	switch(GetRandomInt(1, 8))
	{
		case 1:
		{
			EmitSoundToAll("freak_fortress_2/gamblerv2/gamblerv2_badresult1.mp3", _, _, SNDLEVEL_RAIDSIREN);
		}
		case 2:
		{
			EmitSoundToAll("freak_fortress_2/gamblerv2/gamblerv2_badresult2.mp3", _, _, SNDLEVEL_RAIDSIREN);
		}
		case 3:
		{
			EmitSoundToAll("freak_fortress_2/gamblerv2/gamblerv2_badresult3.mp3", _, _, SNDLEVEL_RAIDSIREN);
		}
		case 4:
		{
			EmitSoundToAll("freak_fortress_2/gamblerv2/gamblerv2_badresult4.mp3", _, _, SNDLEVEL_RAIDSIREN);
		}
		case 5:
		{
			EmitSoundToAll("freak_fortress_2/gamblerv2/gamblerv2_badresult5.mp3", _, _, SNDLEVEL_RAIDSIREN);
		}
		case 6:
		{
			EmitSoundToAll("freak_fortress_2/gamblerv2/gamblerv2_badresult6.mp3", _, _, SNDLEVEL_RAIDSIREN);
		}
		case 7:
		{
			EmitSoundToAll("freak_fortress_2/gamblerv2/gamblerv2_badresult7.mp3", _, _, SNDLEVEL_RAIDSIREN);
		}
		case 8:
		{
			EmitSoundToAll("freak_fortress_2/gamblerv2/gamblerv2_badresult8.mp3", _, _, SNDLEVEL_RAIDSIREN);
		}
	}
}

public void PlayGoodResult()
{
	switch(GetRandomInt(1, 8))
	{
		case 1:
		{
			EmitSoundToAll("freak_fortress_2/gamblerv2/gamblerv2_goodresult1.mp3", _, _, SNDLEVEL_RAIDSIREN);
		}
		case 2:
		{
			EmitSoundToAll("freak_fortress_2/gamblerv2/gamblerv2_goodresult2.mp3", _, _, SNDLEVEL_RAIDSIREN);
		}
		case 3:
		{
			EmitSoundToAll("freak_fortress_2/gamblerv2/gamblerv2_goodresult3.mp3", _, _, SNDLEVEL_RAIDSIREN);
		}
		case 4:
		{
			EmitSoundToAll("freak_fortress_2/gamblerv2/gamblerv2_goodresult4.mp3", _, _, SNDLEVEL_RAIDSIREN);
		}
		case 5:
		{
			EmitSoundToAll("freak_fortress_2/gamblerv2/gamblerv2_goodresult5.mp3", _, _, SNDLEVEL_RAIDSIREN);
		}
		case 6:
		{
			EmitSoundToAll("freak_fortress_2/gamblerv2/gamblerv2_goodresult6.mp3", _, _, SNDLEVEL_RAIDSIREN);
		}
		case 7:
		{
			EmitSoundToAll("freak_fortress_2/gamblerv2/gamblerv2_goodresult7.mp3", _, _, SNDLEVEL_RAIDSIREN);
		}
		case 8:
		{
			EmitSoundToAll("freak_fortress_2/gamblerv2/gamblerv2_goodresult8.mp3", _, _, SNDLEVEL_RAIDSIREN);
		}
	}
}

stock bool canHavePerk(int client, RTDPerk dudeRoll)
{
	//bool valid = true;
	if (IsValidClient(gamblerIDX) && IsValidClient(client))
	{
		if (FF2_GetBossIndex(gamblerIDX) != -1 && FF2_HasAbility(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER))
		{
			char filepath[255];
			BuildPath(Path_SM, filepath, PLATFORM_MAX_PATH, "configs/chaosdice_blockedperks.cfg");
			KeyValues kv = new KeyValues("");
			FileToKeyValues(kv, filepath);
			if (!kv.GotoFirstSubKey())
			{
				delete kv;
       	 		//PrintToChatAll("Nope");
			}
			else
			{
				if (!dudeRoll.Valid)
				{
    				//CPrintToChatAll("{orange}Detected: invalid perk.");
					return false;
				}
				else if (rigged && TF2_GetClientTeam(client) == TF2_GetClientTeam(gamblerIDX) && !dudeRoll.Good && FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg708", 708, 0) == 1)
				{
    				//CPrintToChatAll("{purple}Detected: Rigged was used and the client on the Gambler's team returned negative.");
					return false;
				}
				else if (rigged && TF2_GetClientTeam(client) != TF2_GetClientTeam(gamblerIDX) && dudeRoll.Good && FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg708", 708, 0) == 1)
				{
    				//CPrintToChatAll("{purple}Detected: Rigged was used and the client on the enemy team returned positive.");
					return false;
				}
				else if (busted && client == gamblerIDX && dudeRoll.Good)
				{
					return false;
				}
				do
				{
					char buffer[255];
					kv.GetSectionName(buffer, sizeof(buffer));
               		//PrintToChatAll("Sub key %s", buffer);
					
					int keynumber = 1;
					for(keynumber=1; keynumber<=120; keynumber++)
					{
						char keynumberchar[128];
						IntToString(keynumber, keynumberchar, sizeof(keynumberchar));
						char value[64];
						kv.GetString(keynumberchar, value, sizeof(value));
                		//KvGetString(kv, keynumberchar, value, sizeof(value));
                		//PrintToChatAll("value %s from sub key %s", value, buffer);
						if (FF2_GetBossIndex(client) != -1 && StrEqual(buffer, "chaosdice_blocked_boss", true))
						{
							dudeRoll.GetName(gambleRTD, sizeof(gambleRTD));
							if (StrContains(gambleRTD, value, true) != -1 && !StrEqual(value, "", true))
							{
								//CPrintToChatAll("{green}DETECTED! Perk ''%s'' contains blocked key word ''%s''; forcing new perk.", gambleRTD, value);
								return false;
							}
						}
						else if (FF2_GetBossIndex(client) == -1)
						{
							switch (TF2_GetClientTeam(client))
							{
								case TFTeam_Red:
								{
									char redName[256];
									dudeRoll.GetName(redName, sizeof(redName));
									if (StrEqual(buffer, "chaosdice_blocked_red", true) && StrContains(redName, value, true) != -1 && !StrEqual(value, "", true))
									{
										//CPrintToChatAll("{green}DETECTED! Perk ''%s'' contains blocked key word ''%s''; forcing new perk.", redName, value);
										return false;
									}
								}
								case TFTeam_Blue:
								{
									char blueName[256];
									dudeRoll.GetName(blueName, sizeof(blueName));
									if (StrEqual(buffer, "chaosdice_blocked_blue", true) && StrContains(blueName, value, true) != -1 && !StrEqual(value, "", true))
									{
										//CPrintToChatAll("{green}DETECTED! Perk ''%s'' contains blocked key word ''%s''; forcing new perk.", blueName, value);
										return false;
									}
								}
							}
						}
						if (StrEqual(value, "", true))
						{
             				//PrintToChatAll("Value does not exist; quitting loop.");
							break; // if the value doesn't exist, quit the loop
						}
					}
				} while (kv.GotoNextKey());
			}
		}
	}
	return true;
}

public void hackPlayer(int hackTarg, TFTeam team)
{
	if (IsValidClient(gamblerIDX) && IsValidClient(hackTarg))
	{
		if (FF2_GetBossIndex(gamblerIDX) != -1 && FF2_HasAbility(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER))
		{
			SetEntProp(hackTarg, Prop_Send, "m_lifeState", 2);
			if (team == TF2_GetClientTeam(gamblerIDX))
			{
				FF2_SetFF2flags(hackTarg, FF2_GetFF2flags(hackTarg)|FF2FLAG_ALLOWSPAWNINBOSSTEAM);
				TF2_ChangeClientTeam(hackTarg, team);
				SetEntProp(hackTarg, Prop_Send, "m_lifeState", 0);
				TF2_AddCondition(hackTarg, TFCond_Ubercharged, FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg41", 41, 0.0));
				CPrintToChat(hackTarg, "{orange}[赌狗]{default} 赌狗花双倍雇佣了你，现在 为他而战 (至少在接下来的 %i 秒内). {red}赶快干活!", RoundFloat(finalHackTime));
				if (FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg400", 400, 0) != 0)
				{
					float bossPos[3];
					GetClientAbsOrigin(gamblerIDX, bossPos);
					TeleportEntity(hackTarg, bossPos, NULL_VECTOR, NULL_VECTOR);
				}
			}
			else
			{
				CPrintToChat(hackTarg, "{orange}[赌狗]{default} 赌狗和你的合同到期了! {green}该反水了!");
				TF2_ChangeClientTeam(hackTarg, team);
				SetEntProp(hackTarg, Prop_Send, "m_lifeState", 0);
			}
		}
	}
}

//Made this, then realized I didn't really need it. I'm keeping it just in case, though.
/*stock bool HasMannpower(int client)
{
	if (!IsValidClient(client))
		return false;
		
	return TF2_IsPlayerInCondition(client, TFCond_RuneStrength) ||
	TF2_IsPlayerInCondition(client, TFCond_RuneHaste) || 
	TF2_IsPlayerInCondition(client, TFCond_RuneRegen) || 
	TF2_IsPlayerInCondition(client, TFCond_RuneResist) || 
	TF2_IsPlayerInCondition(client, TFCond_RuneVampire) || 
	TF2_IsPlayerInCondition(client, TFCond_RuneWarlock) ||
	TF2_IsPlayerInCondition(client, TFCond_RunePrecision) || 
	TF2_IsPlayerInCondition(client, TFCond_RuneAgility) || 
	TF2_IsPlayerInCondition(client, TFCond_RuneKnockout);
}*/



/*stock int GetRandomLivingNonBoss(TFTeam team)
{
	int client = GetRandomInt(1, MaxClients);
	while (client <= 0 || client > MaxClients || !IsClientConnected(client) || !IsPlayerAlive(client) || TF2_GetClientTeam(client) != team || FF2_GetBossIndex(client) != -1)
	{
		client = GetRandomInt(1, MaxClients);
	}
	return client;
}*/

public rollMenu(Menu reRollMenu, MenuAction action, int client, int param) //Menu system. Determines what button the player has selected,
{	
	if (IsValidClient(gamblerIDX))
	{
		if (action == MenuAction_Select)
		{
			switch(param)
			{
				case 0:
				{
					if (!AllInMenu)
					{
						switch(GetRandomInt(1, 3))
						{
							case 1:
							{
								CPrintToChat(gamblerIDX, "{yellow}希望运气站在你这边. 重骰...");
							}
							case 2:
							{
								CPrintToChat(gamblerIDX, "{yellow}好的! 重骰...");
							}
							case 3:
							{
								CPrintToChat(gamblerIDX, "{yellow}不喜欢这个结果? 好吧，重骰...");
							}
						}
						if (skill == 4)
						{
							for (int clientB = 1; clientB <= MaxClients; clientB++)
							{
								if (IsValidClient(clientB))
								{
									setSuit[clientB] = 0;
								}
							}
						}
						activateSkill(skill);
						reRolling = false;
						rerollCD = true;
						CreateTimer(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg4", 4, 0.0), endRollCD, _, TIMER_FLAG_NO_MAPCHANGE);
						rerolls += -1;
					}
					else
					{
						AllInMenu = false;
						ActivateAllIn();
					}
				}
				case 1:
				{
					//CPrintToChat(gamblerIDX, "{orange}[赌狗] {default}你的重骰取消了.");
					rerollCD = false;
					//reRolling = false;
					switch(skill)
					{
						case 0:
						{
							cashRando = CreateTimer(0.1, cancelCashRoll, TIMER_FLAG_NO_MAPCHANGE);
						}
						case 1:
						{
							speedRando = CreateTimer(0.1, cancelSpeedRoll, TIMER_FLAG_NO_MAPCHANGE);
						}
						case 2:
						{
							healSelfRando = CreateTimer(0.1, cancelBlueHPRoll, TIMER_FLAG_NO_MAPCHANGE);
						}
						case 3:
						{
							damageFoesRando = CreateTimer(0.1, cancelTargRoll, TIMER_FLAG_NO_MAPCHANGE);
						}
						case 4:
						{
							cardsRando = CreateTimer(0.1, cancelSuitRoll, TIMER_FLAG_NO_MAPCHANGE);
						}
						case 5:
						{
							perkRando = CreateTimer(0.1, cancelPowerRoll, TIMER_FLAG_NO_MAPCHANGE);
						}
						case 6:
						{
							hackRando = CreateTimer(0.1, cancelHackRoll, TIMER_FLAG_NO_MAPCHANGE);
						}
						case 7:
						{
							diceRando = CreateTimer(0.1, cancelRTDRoll, TIMER_FLAG_NO_MAPCHANGE);
						}
						case 9:
						{
							AllInMenu = false;
						}
					}
				}
			}
		}
	}
}




public void ActivateAllIn()
{
	if (IsValidClient(gamblerIDX))
	{
		if (FF2_GetBossIndex(gamblerIDX) != -1 && FF2_HasAbility(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER))
		{
			cash = 0.0;
			skill = 0;
			allIn = true;
			rigged = false;
			
			int goodPerks = 0;
			int badPerks = 0;
			
			float chance = GetRandomFloat(0.0, 1.0);
			
			for (int a = 1; a <= 6; a++)
			{
				if (chance <= PositivePerkChance)
				{
					switch(a)
					{
						case 1:
						{
							ludicrous = true;
							CPrintToChatAll("{orange}[赌狗] {purple}赌狗获得了疾驰!");
							//SDKHook(gamblerIDX, SDKHook_PreThink, gambler_PreThink);
						}
						case 2:
						{
							wretched = true;
							CPrintToChatAll("{orange}[赌狗] {purple}赌狗获得了痛苦之刃!");
						}
						case 3:
						{
							TF2_AddCondition(gamblerIDX, TFCond_MegaHeal);
							CPrintToChatAll("{orange}[赌狗] {purple}赌狗获得了势不可挡!");
						}
						case 4:
						{
							shark = true;
							for (int g = 1; g <= MaxClients; g++)
							{
								if (IsValidClient(g))
								{
									if (IsPlayerAlive(g) && TF2_GetClientTeam(g) != TF2_GetClientTeam(gamblerIDX) && IsClientConnected(g))
									{
										DeleteParticle(g);
										suit[g] = GetRandomInt(1, 4);
										setSuit[g] = 0;
										switch (suit[g])
										{
											case 1:
											{
												CPrintToChat(g, "{orange}[赌狗] {default}你的花色是{purple}梅花! {default}效果: {red}死亡后你会爆炸，对周围造成 %i 点伤害.", RoundFloat(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg24", 24, 0.0)));
												attachParticle(g, CLUBS);
											}
											case 2:
											{
												CPrintToChat(g, "{orange}[赌狗] {default}你的花色是{purple}黑桃! {default}效果: {red}你受到的伤害增加 %i倍. {default}小心了!", RoundFloat(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg25", 25, 0.0)));
												attachParticle(g, SPADES);
											}
											case 3:
											{
												CPrintToChat(g, "{orange}[赌狗] {default}你的花色是{purple}方块! {default}效果: {red}赌狗在你存活时每秒获得 $%i , 在你死亡时获得 $%i . {default}至少你能产生价值...", RoundFloat(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg26", 26, 0.0)), RoundFloat(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg27", 27, 0.0)));
												attachParticle(g, DIAMONDS);
											}
											case 4:
											{
												CPrintToChat(g, "{orange}[赌狗] {default}你的花色是{purple}红心! {default}效果: {red}你死亡时, 赌狗将会获得随机百分于其最大生命值的治疗效果. {default}不惜代价存活下去！", RoundFloat(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg25", 25, 0.0)));
												attachParticle(g, HEARTS);
											}
										}
									}
								}
							}
							CPrintToChatAll("{orange}[赌狗] {purple}赌狗获得了纸牌好手!");
						}
						case 5:
						{
							nightmare = true;
							CPrintToChatAll("{orange}[赌狗] {purple}赌狗获得了惊世之力!");
						}
						case 6:
						{
							FF2_SetBossHealth(FF2_GetBossIndex(gamblerIDX), FF2_GetBossMaxHealth(FF2_GetBossIndex(gamblerIDX)));
							EmitSoundToAll("items/powerup_pickup_supernova.wav", gamblerIDX);
							CPrintToChatAll("{orange}[赌狗] {purple}赌狗获得了嗜钱如命!");
						}
					}
					goodPerks++;
				}
				chance = GetRandomFloat(0.0, 1.0);
			}
			chance = GetRandomFloat(0.0, 1.0);
			for (int b = 1; b <= 6; b++)
			{
				if (chance <= NegativePerkChance)
				{
					switch(b)
					{
						case 1:
						{
							wasting = true;
							CPrintToChatAll("{orange}[赌狗] {red}赌狗获得日渐消瘦诅咒!");
						}
						case 2:
						{
							for (int client = 1; client <= MaxClients; client++)
							{
								if (IsValidClient(client))
								{
									if (TF2_GetClientTeam(client) != TF2_GetClientTeam(gamblerIDX))
									{
										TF2_AddCondition(client, TFCond_SpeedBuffAlly);
									}
								}
							}
							CPrintToChatAll("{orange}[赌狗] {red}赌狗获得亢奋诅咒!");
						}
						case 3:
						{
							for (int clientB = 1; clientB <= MaxClients; clientB++)
							{
								if (IsValidClient(clientB))
								{
									if (TF2_GetClientTeam(clientB) == TF2_GetClientTeam(gamblerIDX) && clientB != gamblerIDX)
									{
										hackPlayer(clientB, TFTeam_Red);
									}
								}
							}
							CPrintToChatAll("{orange}[赌狗] {red}赌狗获得过期合同诅咒!");
						}
						case 4:
						{
							for (int clientC = 1; clientC <= MaxClients; clientC++)
							{
								if (IsValidClient(clientC))
								{
									if (TF2_GetClientTeam(clientC) != TF2_GetClientTeam(gamblerIDX))
									{
										GiveRandomMannpower(clientC, 999.0);
									}
								}
							}
							CPrintToChatAll("{orange}[赌狗] {red}赌狗获得戏弄神的代价!");
						}
						case 5:
						{
							frail = true;
							CPrintToChatAll("{orange}[赌狗] {red}赌狗获得玻璃娃娃诅咒!");
						}
						case 6:
						{
							busted = true;
							float min = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg605", 605, 0.0);
							float max = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg606", 606, 0.0);
							slotCurse = CreateTimer(GetRandomFloat(min, max), brokenSlots, TIMER_FLAG_NO_MAPCHANGE);
							CPrintToChatAll("{orange}[赌狗] {red}赌狗获得技能损坏诅咒!");
						}
					}
					badPerks++;
				}
				chance = GetRandomFloat(0.0, 1.0);
			}
			if (goodPerks >= badPerks)
			{
				PlayGoodResult();
			}
			else
			{
				PlayBadResult();
			}
		}
	}
}
public Action checkReflect(Handle reflectCheck)
{
	bool hasIt = false;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			if (TF2_IsPlayerInCondition(client, TFCond_RuneWarlock))
			{
				hasIt = true;
			}
		}
	}
	someoneHasReflect = hasIt;
	return Plugin_Continue;
}
public Action revertHack(Handle endHack, int client)
{
	if (IsValidClient(client))
	{
		if (IsPlayerAlive(client))
		{
			hackPlayer(client, TFTeam_Red);
		}
	}
	KillTimer(revertTimer[client]);
	revertTimer[client] = INVALID_HANDLE;
}
public Action endRollCD(Handle rollerCD)
{
	rerollCD = false;
}
public Action brokenSlots(Handle brokeSlots)
{
	if (IsValidClient(gamblerIDX))
	{
		if (FF2_GetBossIndex(gamblerIDX) != -1 && FF2_HasAbility(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER) && FF2_GetRoundState() == 1)
		{
			char perkID[64];
			int rtdPerk = GetRandomInt(0, 256);
			IntToString(rtdPerk, perkID, sizeof(perkID));
			rollItNow[gamblerIDX] = RTD2_FindPerk(perkID);
			while (!canHavePerk(gamblerIDX, rollItNow[gamblerIDX]))
			{
				rtdPerk = GetRandomInt(0, 256);
				IntToString(rtdPerk, perkID, sizeof(perkID));
				rollItNow[gamblerIDX] = RTD2_FindPerk(perkID);
			}
			RTD2_Remove(gamblerIDX, RTDRemove_Custom, "你的技能损坏了");
			PlayBadResult();
			RTD2_Force(gamblerIDX, perkID, FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg603", 603, 0));
			float min = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg605", 605, 0.0);
			float max = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg606", 606, 0.0);
			slotCurse = CreateTimer(GetRandomFloat(min, max), brokenSlots, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			KillTimer(slotCurse);
			slotCurse = INVALID_HANDLE;
		}
	}
	else
	{
		KillTimer(slotCurse);
		slotCurse = INVALID_HANDLE;
	}
}
public Action cancelCashRoll(Handle cashCancel)
{
	if (IsValidClient(gamblerIDX) && reRolling)
	{
		if (FF2_GetBossIndex(gamblerIDX) != -1 && FF2_HasAbility(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER))
		{
			CPrintToChat(gamblerIDX, "{orange}[赌狗] {default}你的重骰取消了.");
			reRolling = false;
			float result = cash * finalMultiplier;
			if (finalMultiplier >= 1.0)
			{
				CPrintToChat(gamblerIDX, "{orange}[赌狗] {green}好! 你获得了 $%i. {default}不要一下子就花光了哦......", RoundFloat(result - cash));
				EmitSoundToClient(gamblerIDX, "mvm/mvm_bought_upgrade.wav");
				PlayGoodResult();
			}
			else
			{
				CPrintToChat(gamblerIDX, "{orange}[赌狗] {red}倒霉! 你失去了 $%i. {default}祝你下次好运!", RoundFloat(cash - result));
				EmitSoundToClient(gamblerIDX, "mvm/mvm_player_died.wav");
				PlayBadResult();
			}
			cash = result;
			//cashRando = INVALID_HANDLE;
		}
	}
	if (cashRando != INVALID_HANDLE)
	{
		KillTimer(cashRando);
	}
	cashRando = INVALID_HANDLE;
}
public Action cancelSpeedRoll(Handle spdCancel)
{
	if (IsValidClient(gamblerIDX) && reRolling)
	{
		if (FF2_GetBossIndex(gamblerIDX) != -1 && FF2_HasAbility(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER))
		{
			CPrintToChat(gamblerIDX, "{orange}[赌狗] {default}你的重骰取消了.");
			reRolling = false;
			//SDKHook(gamblerIDX, SDKHook_PreThink, gambler_PreThink);
			speedRoll = true;
			CreateTimer(speedTime, endSpeed, _, TIMER_FLAG_NO_MAPCHANGE);
			float displaySpeed = chosenSpeed/GetEntPropFloat(gamblerIDX, Prop_Send, "m_flMaxspeed");
			if (chosenSpeed >= GetEntPropFloat(gamblerIDX, Prop_Send, "m_flMaxspeed"))
			{
				CPrintToChat(gamblerIDX, "{orange}[赌狗] {green}好! 你将获得百分之 %i的加速  %i 秒. {default}疾驰如风!", RoundFloat((displaySpeed - 1.0) * 100.0), RoundFloat(speedTime));
				EmitSoundToAll("mvm/mvm_tele_activate.wav", gamblerIDX);
				PlayGoodResult();
			}
			else
			{
				CPrintToChat(gamblerIDX, "{orange}[赌狗] {red}倒霉! 你将获得百分之 %i的减速  %i 秒. {default}好好享受吧!", RoundFloat((1.0 - displaySpeed) * 100.0), RoundFloat(speedTime));
				EmitSoundToAll("mvm/mvm_tank_start.wav", gamblerIDX);
				PlayBadResult();
			}
			//speedRando = INVALID_HANDLE;
		}
	}
	if (speedRando != INVALID_HANDLE)
	{
		KillTimer(speedRando);
	}
	speedRando = INVALID_HANDLE;
}
public Action cancelBlueHPRoll(Handle healCancel)
{
	if (IsValidClient(gamblerIDX) && reRolling)
	{
		if (FF2_GetBossIndex(gamblerIDX) != -1 && FF2_HasAbility(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER))
		{
			CPrintToChat(gamblerIDX, "{orange}[赌狗] {default}你的重骰取消了.");
			reRolling = false;
			FF2_SetBossHealth(FF2_GetBossIndex(gamblerIDX), FF2_GetBossHealth(FF2_GetBossIndex(gamblerIDX)) + RoundFloat(healthMultiBLU * FF2_GetBossMaxHealth(FF2_GetBossIndex(gamblerIDX))));
			if (healthMultiBLU >= 0.0)
			{
				CPrintToChat(gamblerIDX, "{orange}[赌狗] {green}好! 你获得了 %i HP. {default}笑一笑十年少!", RoundFloat(healthMultiBLU * FF2_GetBossMaxHealth(FF2_GetBossIndex(gamblerIDX))));
				EmitSoundToAll("items/powerup_pickup_supernova.wav", gamblerIDX);
				PlayGoodResult();
			}
			else
			{
				CPrintToChat(gamblerIDX, "{orange}[赌狗] {red}倒霉! 你失去了 %i HP. {default}逊欸，你很逊欸?", -1 * RoundFloat(healthMultiBLU * FF2_GetBossMaxHealth(FF2_GetBossIndex(gamblerIDX))));
				EmitSoundToAll("items/powerup_pickup_knockout_melee_hit.wav", gamblerIDX);
				PlayBadResult();
			}
			healSelfRando = INVALID_HANDLE;
		}
	}
	if (healSelfRando != INVALID_HANDLE)
	{
		KillTimer(healSelfRando);
	}
	healSelfRando = INVALID_HANDLE;
}
public Action cancelRTDRoll(Handle cashCancel)
{
	if (IsValidClient(gamblerIDX) && reRolling)
	{
		if (FF2_GetBossIndex(gamblerIDX) != -1 && FF2_HasAbility(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER))
		{
			CPrintToChat(gamblerIDX, "{orange}[赌狗] {default}你的重骰取消了.");
			for (int client = 1; client <= MaxClients; client++)
			{
				if (IsValidClient(client))
				{
					if (IsPlayerAlive(client))
					{
						char forcedPerk[256];
						rollItNow[client].GetToken(forcedPerk, sizeof(forcedPerk));
						if (FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg500", 500, 0) == 1)
						{
							RTD2_Remove(client, RTDRemove_Custom, "使用了混沌骰子");
						}
						RTD2_Force(client, forcedPerk, RTDTime);
						if (rollItNow[client].Good)
						{
							CPrintToChat(client, "{orange}[赌狗] {green}走运了! {default}这个{green}增益{default} 将持续 {green}%i 秒.", RTDTime);
							if (client == gamblerIDX)
							{
								PlayGoodResult();
							}
						}
						else
						{
							CPrintToChat(client, "{orange}[赌狗] {red}倒霉! {default}这个{red}减益{default} 将持续 {red}%i 秒.", RTDTime);
							if (client == gamblerIDX)
							{
								PlayBadResult();
							}
						}
					}
				}
			}
			//CPrintToChat(gamblerIDX, "{orange}[赌狗] {yellow}Done! %i allies and %i enemies obtained positive perks, while %i allies and %i enemies obtained negative perks, for %i seconds.", blueGood, redGood, blueBad, redGood);
			reRolling = false;
			//diceRando = INVALID_HANDLE;
		}
	}
	if (diceRando != INVALID_HANDLE)
	{
		KillTimer(diceRando);
	}
	diceRando = INVALID_HANDLE;
}
public Action cancelTargRoll(Handle cashCancel)
{
	if (IsValidClient(gamblerIDX) && reRolling)
	{
		if (FF2_GetBossIndex(gamblerIDX) != -1 && FF2_HasAbility(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER))
		{
			CPrintToChat(gamblerIDX, "{orange}[赌狗] {default}你的重骰取消了.");
			for (int target = 1; target <= MaxClients; target++)
			{
				if (IsValidClient(target))
				{
					if (IsPlayerAlive(target) && TF2_GetClientTeam(target) != TF2_GetClientTeam(gamblerIDX) && IsClientConnected(target))
					{
						if (coinDMG[target] > 0.0)
						{
							EmitSoundToAll("player/medic_charged_death.wav", target);
							SDKHooks_TakeDamage(target, gamblerIDX, gamblerIDX, coinDMG[target]);
							damageTracker += coinDMG[target] * FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg200", 200, 0.0);
							float dmgToGain = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg2", 2, 0.0);
							while (damageTracker >= dmgToGain)
							{
								damageTracker += -dmgToGain;
								rerolls++;
								if (rerolls >= FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg3", 3, 0))
								{
									rerolls = FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg3", 3, 0);
								}
							}
							CPrintToChat(target, "{orange}[赌狗] {red}你被赌狗的生死硬币击中了! {default}哎呀, 是{red}死{default}面向上，你受到了{red}%i 点伤害 {default}。 很痛吧哈哈！", RoundFloat(coinDMG[target]));
						}
						else if (coinDMG[target] < 0.0)
						{
							EmitSoundToAll("player/invuln_on_vaccinator.wav", target, _, _, _, _, SNDPITCH_HIGH);
							SetEntityHealth(target, RoundFloat(GetClientHealth(target) + -1.0*coinDMG[target]));
							CPrintToChat(target, "{orange}[赌狗] {red}你被赌狗的生死硬币击中了! {default}嗯？ 竟然是{green}生{default}，你受到{green} %i 点治疗 {default}。 焕然一新!", -1 * RoundFloat(coinDMG[target]));
						}
					}
				}
				coinDMG[target] = 0.0;
			}
			if (coin_AvgDMG >= 0.0)
			{
				CPrintToChat(gamblerIDX, "{orange}[赌狗] {default} 你击中了{yellow}%i 名玩家, 平均造成{green}%i 点伤害. {default}你这些硬币是用什么做的?", numTargs, RoundFloat(coin_AvgDMG));
				PlayGoodResult();
			}
			else
			{
				CPrintToChat(gamblerIDX, "{orange}[赌狗] {default} 你击中了{yellow}%i 名玩家, 平均造成{red}%i 点治疗. {default}哈哈!", numTargs, -1*RoundFloat(coin_AvgDMG));
				PlayBadResult();
			}
			reRolling = false;
			//damageFoesRando = INVALID_HANDLE;
		}
	}
	if (damageFoesRando != INVALID_HANDLE)
	{
		KillTimer(damageFoesRando);
	}
	damageFoesRando = INVALID_HANDLE;
}

public Action cancelSuitRoll(Handle suitCancel)
{
	if (IsValidClient(gamblerIDX) && reRolling)
	{
		if (FF2_GetBossIndex(gamblerIDX) != -1 && FF2_HasAbility(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER))
		{
			CPrintToChat(gamblerIDX, "{orange}[赌狗] {default}你的重骰取消了.");
			for (int g = 1; g <= MaxClients; g++)
			{
				if (IsValidClient(g))
				{
					if (IsPlayerAlive(g) && TF2_GetClientTeam(g) != TF2_GetClientTeam(gamblerIDX) && IsClientConnected(g))
					{
						suit[g] = setSuit[g];
						setSuit[g] = 0;
						switch (suit[g])
						{
							case 1:
							{
								CPrintToChat(g, "{orange}[赌狗] {default}你的花色是{purple}梅花! {default}效果: {red}死亡后你会爆炸，对周围造成 %i 点伤害.", RoundFloat(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg24", 24, 0.0)));
								attachParticle(g, CLUBS);
							}
							case 2:
							{
								CPrintToChat(g, "{orange}[赌狗] {default}你的花色是{purple}黑桃! {default}效果: {red}你受到的伤害增加 %i倍. {default}小心了!", RoundFloat(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg25", 25, 0.0)));
								attachParticle(g, SPADES);
							}
							case 3:
							{
								CPrintToChat(g, "{orange}[赌狗] {default}你的花色是{purple}方块! {default}效果: {red}赌狗在你存活时每秒获得 $%i , 在你死亡时获得 $%i . {default}至少你能产生价值...", RoundFloat(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg26", 26, 0.0)), RoundFloat(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg27", 27, 0.0)));
								attachParticle(g, DIAMONDS);
							}
							case 4:
							{
								CPrintToChat(g, "{orange}[赌狗] {default}你的花色是{purple}红心! {default}效果: {red}你死亡时, 赌狗将会获得随机百分于其最大生命值的治疗效果. {default}不惜代价存活下去!", RoundFloat(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg25", 25, 0.0)));
								attachParticle(g, HEARTS);
							}
						}
					}
				}
			}
			CPrintToChat(gamblerIDX, "{orange}[赌狗] {default}完成! 现存:{yellow} %i 梅花, %i 黑桃, %i 方块, 还有 %i 红心.", clubs, spades, diamonds, hearts);
			PlayGoodResult();
			CreateTimer(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg30", 30, 0.0), endSuits, _, TIMER_FLAG_NO_MAPCHANGE);
			reRolling = false;
			//cardsRando = INVALID_HANDLE;
		}
	}
	if (cardsRando != INVALID_HANDLE)
	{
		KillTimer(cardsRando);
	}
	cardsRando = INVALID_HANDLE;
}

public Action cancelPowerRoll(Handle powerCancel)
{
	if (IsValidClient(gamblerIDX) && reRolling)
	{
		if (FF2_GetBossIndex(gamblerIDX) != -1 && FF2_HasAbility(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER))
		{
			CPrintToChat(gamblerIDX, "{orange}[赌狗] {default}你的重骰取消了.");
			//CPrintToChatAll("{orange}[赌狗] {default}This... uh... it hasn't been coded yet. This is awkward.");
			//CPrintToChatAll("{orange}[赌狗] {default}This... uh... it hasn't been coded yet. This is awkward.");
			switch(gamblePower)
			{
				case 1:
				{
					TF2_AddCondition(gamblerIDX, TFCond_RuneStrength, perkDur);
				}
				case 2:
				{
					TF2_AddCondition(gamblerIDX, TFCond_RuneHaste, perkDur);
				}
				case 3:
				{
					TF2_AddCondition(gamblerIDX, TFCond_RuneRegen, perkDur);
				}
				case 4:
				{
					TF2_AddCondition(gamblerIDX, TFCond_RuneResist, perkDur);
				}
				case 5:
				{
					TF2_AddCondition(gamblerIDX, TFCond_RuneVampire, perkDur);
				}
				case 6:
				{
					TF2_AddCondition(gamblerIDX, TFCond_RuneWarlock, perkDur);
					someoneHasReflect = true;
				}
				case 7:
				{
					TF2_AddCondition(gamblerIDX, TFCond_RunePrecision, perkDur);
					if (FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg304", 304, 0) == 1)
					{
						static char precGun[256];
						FF2_GetArgS(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg305", 305, precGun, sizeof(precGun));
						FF2_SpawnWeapon(gamblerIDX, "tf_weapon_revolver", 61, 77, 3, precGun, true);
						CreateTimer(perkDur + 0.1, removePrecGun, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				case 8:
				{
					TF2_AddCondition(gamblerIDX, TFCond_RuneAgility, perkDur);
				}
				case 9:
				{
					TF2_AddCondition(gamblerIDX, TFCond_RuneKnockout, perkDur);
				}
			}
			if (enemyPowers > GetLivingReds())
			{
				enemyPowers = GetLivingReds();
			}
			
			int i = 0;
			while(i < enemyPowers)
			{
				int powerA = GetRandomInt(1, MaxClients);
				{
					if (IsValidClient(powerA))
					{
						if (IsPlayerAlive(powerA) && TF2_GetClientTeam(powerA) != TF2_GetClientTeam(gamblerIDX) && IsClientConnected(powerA) && FF2_GetBossIndex(powerA) == -1)
						{
							GiveRandomMannpower(powerA, perkDur);
							EmitSoundToClient(powerA, "weapons/rescue_ranger_teleport_send_02.wav");
							CPrintToChat(powerA, "{orange}[赌狗] {default}你获得了增益效果!");
							i++;
						}
					}
				}
			}		
			i = 0;		
			if (allyPowers > GetLivingBlues() - 1)
			{
				allyPowers = GetLivingBlues() - 1;
			}	
			while(i < allyPowers)
			{
				int powerB = GetRandomInt(1, MaxClients);
				{
					if (IsValidClient(powerB))
					{
						if (IsPlayerAlive(powerB) && TF2_GetClientTeam(powerB) == TF2_GetClientTeam(gamblerIDX) && IsClientConnected(powerB) && FF2_GetBossIndex(powerB) == -1)
						{
							GiveRandomMannpower(powerB, perkDur);
							EmitSoundToClient(powerB, "weapons/rescue_ranger_teleport_send_02.wav");
							CPrintToChat(powerB, "{orange}[赌狗] {default}你获得了增益效果!");
							i++;
						}
					}
				}
			}	
			if (enemyPowers > allyPowers)
			{
				PlayBadResult();
			}
			else
			{
				PlayGoodResult();
			}
			CPrintToChat(gamblerIDX, "{orange}[赌狗] {green}好! {default}你获得了 {purple}%s, {default}同时 {green}%i 名队友 {default}和 {red}%i 名敌人 {default}也获取了增益. 增益将持续 %i 秒.", gamblePowerText, allyPowers, enemyPowers, RoundFloat(perkDur));
			reRolling = false;
		}
	}
	if (perkRando != INVALID_HANDLE)
	{
		KillTimer(perkRando);
	}
	perkRando = INVALID_HANDLE;
}

public Action cancelHackRoll(Handle hackCancel)
{
	if (IsValidClient(gamblerIDX) && reRolling)
	{
		if (FF2_GetBossIndex(gamblerIDX) != -1 && FF2_HasAbility(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER))
		{
			CPrintToChat(gamblerIDX, "{orange}[赌狗] {default}你的重骰取消了.");
			if (targets >= GetLivingReds())
			{
				targets = GetLivingReds() - 1;
			}
			else if (targets < 1)
			{
				targets = 1;
			}
			for (int hackCount = 0; hackCount < targets; )
			{
				int hackTarg = GetRandomInt(1, MaxClients);
				if (IsValidClient(hackTarg))
				{
					if (IsPlayerAlive(hackTarg) && TF2_GetClientTeam(hackTarg) != TF2_GetClientTeam(gamblerIDX))
					{
						hackPlayer(hackTarg, TF2_GetClientTeam(gamblerIDX));
						revertTimer[hackTarg] = CreateTimer(finalHackTime, revertHack, hackTarg, TIMER_FLAG_NO_MAPCHANGE);
						hackCount++;
					}
				}
			}
			if (finalPercent < FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg40", 40, 0.0) * 0.5)
			{
				PlayBadResult();
			}
			else
			{
				PlayGoodResult();
			}
			CPrintToChat(gamblerIDX, "{orange}[赌狗] {green}好! {default}你雇佣了{green}%i 名玩家{default}为你而战{green}%i 秒.", targets, RoundFloat(finalHackTime));
			reRolling = false;
		}
	}
	if (hackRando != INVALID_HANDLE)
	{
		KillTimer(hackRando);
	}
	hackRando = INVALID_HANDLE;
}
public Action endSpeed(Handle speedEnd)
{
	if (IsValidClient(gamblerIDX))
	{
		speedRoll = false; //SDKUnhook(gamblerIDX, SDKHook_PreThink, gambler_PreThink);
	}
}
public Action removePrecGun(Handle tnw_error_logs_be_like)
{
	if (IsValidClient(gamblerIDX))
	{
		if (FF2_GetBossIndex(gamblerIDX) != -1 && FF2_HasAbility(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER) && !TF2_IsPlayerInCondition(gamblerIDX, TFCond_RunePrecision))
		{
			TF2_RemoveWeaponSlot(gamblerIDX, 0);
		}
	}
}
public Action endSuits(Handle suitEnd)
{
	if (!shark)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsValidClient(client))
			{
				suit[client] = 0;
				DeleteParticle(client);
			}
		}
	}
}

public Action DeleteParticle(int client)
{
	if (IsValidEdict(playerParticle[client]))
	{
		char classname[64];
		
		GetEdictClassname(playerParticle[client], classname, sizeof(classname));
		
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(playerParticle[client], "Stop");
			AcceptEntityInput(playerParticle[client], "Kill");
		}
	}
}

public Action:gambler_PreThink(gambleSpeed)
{		
	if (IsValidClient(gamblerIDX))
	{
		if (ludicrous)
		{
			SetEntPropFloat(gamblerIDX, Prop_Send, "m_flMaxspeed", FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg600", 600, 0.0));
		}
		else if (TF2_IsPlayerInCondition(gamblerIDX, TFCond_RuneHaste))
		{
			SetEntPropFloat(gamblerIDX, Prop_Send, "m_flMaxspeed", FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg302", 302, 0.0));
		}
		else if (TF2_IsPlayerInCondition(gamblerIDX, TFCond_RuneAgility))
		{
			SetEntPropFloat(gamblerIDX, Prop_Send, "m_flMaxspeed", FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg303", 303, 0.0));
		}
		else if (speedRoll)
		{
			SetEntPropFloat(gamblerIDX, Prop_Send, "m_flMaxspeed", chosenSpeed);
		}
	}
}
public Action FF2_OnLoseLife(int boss, int &lives, int maxLives)
{
	if (IsValidClient(gamblerIDX))
	{
		if (FF2_GetBossIndex(gamblerIDX) != -1 && FF2_HasAbility(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER) && IsPlayerAlive(gamblerIDX))
		{
			if (lives == 3)
			{
				CPrintToChat(gamblerIDX, "{purple}你失去了一条生命! 你的赌念更加坚定...");
				CPrintToChat(gamblerIDX, "{yellow}你获得4个新技能!");
			}
			if (lives == 2)
			{
				CPrintToChat(gamblerIDX, "{purple}你只剩最后一条命了... 是时候翻盘了!");
				CPrintToChat(gamblerIDX, "{yellow}你的3个究极技能已解锁!");
			}
		}
	}
	return Plugin_Continue;
}

public Action gamblerHUD(Handle gamblerHUD)
{
	if (IsValidClient(gamblerIDX))
	{
		if (FF2_GetBossIndex(gamblerIDX) != -1 && FF2_GetRoundState() == 1 && IsPlayerAlive(gamblerIDX))
		{
			int gambleBoss = FF2_GetBossIndex(gamblerIDX);
			
			float cashX = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg108", 108, 0.0);
			float cashY = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg109", 109, 0.0);
			float abilityX = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg106", 106, 0.0);
			float abilityY = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg107", 107, 0.0);
			
			int regenHPGain = RoundFloat(FF2_GetArgI(gambleBoss, PLUGIN_NAME, GAMBLER, "arg300", 300, 0) * 0.1);
			
			if (TF2_IsPlayerInCondition(gamblerIDX, TFCond_RuneRegen))
			{
				FF2_SetBossHealth(FF2_GetBossIndex(gamblerIDX), FF2_GetBossHealth(FF2_GetBossIndex(gamblerIDX)) + regenHPGain);
			}
			
			if (wasting)
			{
				FF2_SetBossHealth(FF2_GetBossIndex(gamblerIDX), FF2_GetBossHealth(FF2_GetBossIndex(gamblerIDX)) - RoundFloat(FF2_GetArgI(gambleBoss, PLUGIN_NAME, GAMBLER, "arg601", 601, 0) * 0.1));
			}
			
			SetHudTextParams(cashX, cashY, 0.1, 255, 255, 255, 255);
			ShowHudText(gamblerIDX, -1, "现金: $%i | 重骰机会: %i", RoundFloat(cash), rerolls);
			
			adjustCD();
			
			switch (skill)
			{
				case 0:
				{
					if (skillCD[0] > 0.0)
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 255, 0, 0, 255);
						ShowHudText(gamblerIDX, -1, "小赌一把 [%is] (R键切换)", RoundFloat(skillCD[0]));
					}
					else
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 0, 255, 0, 255);
						ShowHudText(gamblerIDX, -1, "小赌一把 (R键切换, 鼠标中键使用)");
					}
				}
				case 1:
				{
					float cost1 = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg13", 13, 0.0);
					if (skillCD[1] > 0.0)
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 255, 0, 0, 255);
						ShowHudText(gamblerIDX, -1, "($%i) 赌断狗腿 [%is] (R键切换)", RoundFloat(cost1), RoundFloat(skillCD[1]));
					}
					else if (cash < cost1)
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 255, 0, 0, 255);
						ShowHudText(gamblerIDX, -1, "($%i) 赌断狗腿 (R键切换, 鼠标中键使用)", RoundFloat(cost1));
					}
					else
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 0, 255, 0, 255);
						ShowHudText(gamblerIDX, -1, "($%i) 赌断狗腿 (R键切换, 鼠标中键使用)", RoundFloat(cost1));
					}
				}
				case 2:
				{
					float cost2 = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg17", 17, 0.0);
					if (skillCD[2] > 0.0)
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 255, 0, 0, 255);
						ShowHudText(gamblerIDX, -1, "($%i) 赌命 [%is] (R键切换)", RoundFloat(cost2), RoundFloat(skillCD[2]));
					}
					else if (cash < cost2)
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 255, 0, 0, 255);
						ShowHudText(gamblerIDX, -1, "($%i) 赌命 (R键切换)", RoundFloat(cost2));
					}
					else
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 0, 255, 0, 255);
						ShowHudText(gamblerIDX, -1, "($%i) 赌命 (R键切换, 鼠标中键使用)", RoundFloat(cost2));
					}
				}
				case 3:
				{
					float cost3 = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg23", 23, 0.0);
					if (skillCD[3] > 0.0)
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 255, 0, 0, 255);
						ShowHudText(gamblerIDX, -1, "($%i) 死或生 [%is] (R键切换)", RoundFloat(cost3), RoundFloat(skillCD[3]));
					}
					else if (cash < cost3)
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 255, 0, 0, 255);
						ShowHudText(gamblerIDX, -1, "($%i) 死或生 (R键切换)", RoundFloat(cost3));
					}
					else
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 0, 255, 0, 255);
						ShowHudText(gamblerIDX, -1, "($%i) 死或生 (R键切换, 鼠标中键使用)", RoundFloat(cost3));
					}
				}
				case 4:
				{
					float cost4 = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg32", 32, 0.0);
					if (skillCD[4] > 0.0)
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 255, 0, 0, 255);
						ShowHudText(gamblerIDX, -1, "($%i) 发牌 [%is] (R键切换)", RoundFloat(cost4), RoundFloat(skillCD[4]));
					}
					else if (cash < cost4)
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 255, 0, 0, 255);
						ShowHudText(gamblerIDX, -1, "($%i) 发牌 (R键切换)", RoundFloat(cost4));
					}
					else
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 0, 255, 0, 255);
						ShowHudText(gamblerIDX, -1, "($%i) 发牌 (R键切换, 鼠标中键使用)", RoundFloat(cost4));
					}
				}
				case 5:
				{
					float cost5 = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg38", 38, 0.0);
					if (skillCD[5] > 0.0)
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 255, 0, 0, 255);
						ShowHudText(gamblerIDX, -1, "($%i) 曼恩之力 [%is] (R键切换)", RoundFloat(cost5), RoundFloat(skillCD[5]));
					}
					else if (cash < cost5)
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 255, 0, 0, 255);
						ShowHudText(gamblerIDX, -1, "($%i) 曼恩之力 (R键切换)", RoundFloat(cost5));
					}
					else
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 0, 255, 0, 255);
						ShowHudText(gamblerIDX, -1, "($%i) 曼恩之力 (R键切换, 鼠标中键使用)", RoundFloat(cost5));
					}
				}
				case 6:
				{
					float cost6 = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg43", 43, 0.0);
					if (skillCD[6] > 0.0)
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 255, 0, 0, 255);
						ShowHudText(gamblerIDX, -1, "($%i) 我付双倍 [%is] (R键切换)", RoundFloat(cost6), RoundFloat(skillCD[6]));
					}
					else if (cash < cost6)
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 255, 0, 0, 255);
						ShowHudText(gamblerIDX, -1, "($%i) 我付双倍 (R键切换)", RoundFloat(cost6));
					}
					else
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 0, 255, 0, 255);
						ShowHudText(gamblerIDX, -1, "($%i) 我付双倍 (R键切换, 鼠标中键使用)", RoundFloat(cost6));
					}
				}
				case 7:
				{
					float cost7 = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg46", 46, 0.0);
					if (skillCD[7] > 0.0)
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 255, 0, 0, 255);
						ShowHudText(gamblerIDX, -1, "($%i) -={混沌之骰}=- [%is] (R键切换)", RoundFloat(cost7), RoundFloat(skillCD[7]));
					}
					else if (cash < cost7)
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 255, 0, 0, 255);
						ShowHudText(gamblerIDX, -1, "($%i) -={混沌之骰}=- (R键切换)", RoundFloat(cost7));
					}
					else
					{
						SetHudTextParams(abilityX, abilityY, 0.1, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), 255);
						ShowHudText(gamblerIDX, -1, "($%i) -={混沌之骰}=- (R键切换, 鼠标中键使用)", RoundFloat(cost7));
					}
				}
				case 8:
				{
					SetHudTextParams(abilityX, abilityY, 0.1, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), 255);
					ShowHudText(gamblerIDX, -1, "-={出千}=- (R键切换, 鼠标中键使用)");
				}
				case 9:
				{
					float cost9 = FF2_GetArgF(gambleBoss, PLUGIN_NAME, GAMBLER, "arg48", 48, 0.0);
					if (cash < cost9)
					{
						SetHudTextParams(abilityX, abilityY, 0.1, 255, 0, 0, 255);
						ShowHudText(gamblerIDX, -1, "(基础消耗: $%i) -={ALL-IN}=- (R键切换)", RoundFloat(cost9));
					}
					else
					{
						SetHudTextParams(abilityX, abilityY, 0.1, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), 255);
						ShowHudText(gamblerIDX, -1, "(基础消耗: $%i) -={ALL-IN}=- (R键切换, 鼠标中键使用)", RoundFloat(cost9));
					}
				}
			}
			incrementCash(FF2_GetArgF((FF2_GetBossIndex(gamblerIDX)), PLUGIN_NAME, GAMBLER, "arg101", 101, 0.0) * 0.1);
		}
		else if (FF2_GetBossIndex(gamblerIDX) == -1)
		{
			KillTimer(gamblerHUD);
		}
		else if (FF2_GetRoundState() == 2)
		{
			KillTimer(gamblerHUD);
		}
		else if (!IsPlayerAlive(gamblerIDX))
		{
			KillTimer(gamblerHUD);
		}
	}
	else
	{
		KillTimer(gamblerHUD);
	}
}

public Action player_killed(Event hEvent, const char[] sEvName, bool bDontBroadcast) //Controls what happens when a player dies. 
{
	int victim = GetClientOfUserId(hEvent.GetInt("userid"));
	if (IsValidClient(victim) && IsValidClient(gamblerIDX))
	{
		if (TF2_GetClientTeam(victim) != TF2_GetClientTeam(gamblerIDX))
		{
			incrementCash(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg102", 102, 0.0));
			switch(suit[victim])
			{
				case 1:
				{
					suit[victim] = 0;
					EmitSoundToAll("weapons/diamond_back_01_crit.wav", victim);
					EmitSoundToAll("items/pumpkin_explode3.wav", victim);
					float vicLoc[3];
					GetClientAbsOrigin(victim, vicLoc);
					particle = CreateEntityByName("info_particle_system");
					
					if (IsValidEdict(particle))
					{
						TeleportEntity(particle, vicLoc, NULL_VECTOR, NULL_VECTOR);
						DispatchKeyValue(particle, "effect_name", "mvm_tank_destroy");
						DispatchKeyValue(particle, "targetname", "present");
						DispatchSpawn(particle);
						ActivateEntity(particle);
						AcceptEntityInput(particle, "Start");
					}
					else
					{
						LogError("(CreateParticle): Could not create info_particle_system");
					}
					float expDmg = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg24", 24, 0.0);
					float expRadius = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg25", 25, 0.0);
					for (int client = 1; client <= MaxClients; client++)
					{
						if (IsValidClient(client) && FF2_GetRoundState() == 1)
						{
							if (TF2_GetClientTeam(client) == TFTeam_Red)
							{
								float targLoc[3];
								GetClientAbsOrigin(client, targLoc);
								if (GetVectorDistance(vicLoc, targLoc) <= expRadius)
								{
									SDKHooks_TakeDamage(client, gamblerIDX, gamblerIDX, expDmg, DMG_ALWAYSGIB, 20);
								}
							}
						}
					}
					/*for (int i = 1; i <= MaxClients; i++)
					{
						if (IsValidClient(i))
						{
							if (TF2_GetClientTeam(i) != TF2_GetClientTeam(gamblerIDX))
							{
								float otherLoc[3];
								GetClientAbsOrigin(i, vicLoc);
								if (GetVectorDistance(vicLoc, otherLoc) <= expRadius)
								{
									if (IsValidClient(i))
									{
										SDKHooks_TakeDamage(i, gamblerIDX, gamblerIDX, expDmg, DMG_ALWAYSGIB, 20);
									}
								}
							}
						}
					}*/
					EmitSoundToAll("weapons/airstrike_fire_crit.wav", victim, _, SNDLEVEL_GUNFIRE);
				}
				case 3:
				{
					if (!allIn)
					{
						cash += FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg27", 27, 0.0);
						EmitSoundToAll("mvm/mvm_bought_upgrade.wav", gamblerIDX);
						CPrintToChat(gamblerIDX, "{orange}[赌狗] {green}你通过击杀 方块 标记的玩家获得了 $%i.", RoundFloat(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg27", 27, 0.0)));
					}
					suit[victim] = 0;
				}
				case 4:
				{
					float minHeal = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg28", 28, 0.0);
					float maxHeal = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg29", 29, 0.0);
					EmitSoundToAll("items/powerup_pickup_supernova.wav", gamblerIDX);
					int finalHeal = RoundFloat(FF2_GetBossMaxHealth(FF2_GetBossIndex(gamblerIDX)) * GetRandomFloat(minHeal, maxHeal));
					CPrintToChat(gamblerIDX, "{orange}[赌狗] {green}你通过击杀 红心 标记的玩家获得了 %i HP.", finalHeal);
					FF2_SetBossHealth(FF2_GetBossIndex(gamblerIDX), FF2_GetBossHealth(FF2_GetBossIndex(gamblerIDX)) + finalHeal);
					suit[victim] = 0;
				}
			}
			if (nightmare)
			{
				for (int client = 1; client <= MaxClients; client++)
				{
					if (IsValidClient(client))
					{
						if (TF2_GetClientTeam(client) != TF2_GetClientTeam(gamblerIDX))
						{
							TF2_StunPlayer(client, FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg604", 604, 0.0), 0.5, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_GHOSTEFFECT|TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_THIRDPERSON);
						}
					}
				}
			}
			DeleteParticle(victim);
		}
		if (revertTimer[victim] != INVALID_HANDLE)
		{
			KillTimer(revertTimer[victim]);
		}
		revertTimer[victim] = INVALID_HANDLE;
		coinDMG[victim] = 0.0;
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon,
	Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsValidClient(victim) && IsValidClient(gamblerIDX))
	{
		if (FF2_GetBossIndex(victim) != -1)
		{
			if (FF2_HasAbility(FF2_GetBossIndex(victim), PLUGIN_NAME, GAMBLER) && damagetype != DMG_FALL)
			{
				if (damagetype == DMG_CRIT)
				{
					incrementCash(3.0 * (damage * FF2_GetArgF(FF2_GetBossIndex(victim), PLUGIN_NAME, GAMBLER, "arg103", 103, 0.0)));
				}
				else
				{
					incrementCash(damage * FF2_GetArgF(FF2_GetBossIndex(victim), PLUGIN_NAME, GAMBLER, "arg103", 103, 0.0));
				}
				if (frail)
				{
					damage *= FF2_GetArgF(FF2_GetBossIndex(victim), PLUGIN_NAME, GAMBLER, "arg602", 602, 0.0);
					return Plugin_Changed;
				}
			}
		}
		if (FF2_GetBossIndex(gamblerIDX) != -1 && TF2_GetClientTeam(victim) != TF2_GetClientTeam(gamblerIDX) && attacker == gamblerIDX)
		{
			damageTracker += damage;
			float dmgForRoll = FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg2", 2, 0.0);
			while (damageTracker >= dmgForRoll)
			{
				damageTracker += -dmgForRoll;
				rerolls++;
				if (rerolls >= FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg3", 3, 0))
				{
					rerolls = FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg3", 3, 0);
				}
			}
			int vampHPGain = RoundFloat(damage * FF2_GetArgI(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg301", 301, 0));
			
			if (TF2_IsPlayerInCondition(gamblerIDX, TFCond_RuneVampire))
			{
				FF2_SetBossHealth(FF2_GetBossIndex(gamblerIDX), FF2_GetBossHealth(FF2_GetBossIndex(gamblerIDX)) + vampHPGain);
			}
			if (wretched)
			{
				damage *= 9999.0;
				return Plugin_Changed;
			}
		}
		if (IsValidClient(victim))
		{
			if (suit[victim] == 2)
			{
				damage *= FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg201", 201, 0.0);
				EmitSoundToAll("weapons/airstrike_small_explosion_03.wav", victim);
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public void adjustCD()
{
	for (int i = 0; i <= 9; i++)
	{
		if (skillCD[i] > 0.0)
		{
			skillCD[i] = skillCD[i] - 0.1;
			if (skillCD[i] < 0.1)
			{
				skillCD[i] = 0.0;
			}
		}
	}
}

public void incrementCash(float amt)
{
	if (!allIn)
	{
		cash += amt;
		
		cash += (0.1*FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg26", 26, 0.0))*getDiamonds();
		
		if (cash > maxCash)
		{
			cash = maxCash;
			if (instaWin > 0.0 && !nukeCalled)
			{
				CPrintToChatAll("{red}警告! 赌狗的现金达到最大值准备召唤核打击! 你必须在 %i 秒内击杀他!", RoundFloat(instaWin));
				EmitSoundToAll("freak_fortress_2/gamblerv2/gamblerv2_nukesiren.mp3");
				EmitSoundToAll("mvm/ambient_mp3/mvm_siren.mp3");
				//CreateTimer(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg110", 110, 0.0), loopSiren, _, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(instaWin, killEverything, TIMER_FLAG_NO_MAPCHANGE);
				nukeCalled = true;
			}
		}
		else if (cash < 0.0)
		{
			cash = 0.0;
		}
	}
}

stock int getDiamonds()
{
	int diamondCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (suit[i] == 3)
			{
				diamondCount++;
			}
		}
	}
	return diamondCount;
}

/*public Action loopSiren(Handle loopSiren)
{
	if (IsValidClient(gamblerIDX))
	{
		if (FF2_HasAbility(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER) && FF2_GetRoundState() == 1 && FF2_GetBossIndex(gamblerIDX) != -1 && IsPlayerAlive(gamblerIDX))
		{
			EmitSoundToAll("mvm/mvm_bomb_warning.wav", _, _, SNDLEVEL_TRAFFIC);
			CreateTimer(FF2_GetArgF(FF2_GetBossIndex(gamblerIDX), PLUGIN_NAME, GAMBLER, "arg110", 110, 0.0), loopSiren, _, TIMER_FLAG_NO_MAPCHANGE));
		}
	}
}*/

stock Handle attachParticle(int client, char type[256])
{
	if (IsValidClient(client))
	{
		playerParticle[client] = CreateEntityByName("info_particle_system");
		
		if (IsValidEdict(playerParticle[client]))
		{
			decl Float:pos[3];
			GetClientAbsOrigin(client, pos);
			TeleportEntity(playerParticle[client], pos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(playerParticle[client], "effect_name", type);
			SetVariantString("!activator");
			AcceptEntityInput(playerParticle[client], "SetParent", client, playerParticle[client], 0);
			SetVariantString("root");
			AcceptEntityInput(playerParticle[client], "SetParentAttachmentMaintainOffset", playerParticle[client], playerParticle[client], 0);
			DispatchKeyValue(playerParticle[client], "targetname", "present");
			DispatchSpawn(playerParticle[client]);
			ActivateEntity(playerParticle[client]);
			AcceptEntityInput(playerParticle[client], "Start");
		}
		else
		{
			LogError("(CreateParticle): Could not create info_particle_system");
		}
	}
	return INVALID_HANDLE;
}

public Action killEverything(Handle gambler_instaWin)
{
	if (IsValidClient(gamblerIDX))
	{
		if (FF2_GetRoundState() == 1 && FF2_GetBossIndex(gamblerIDX) != -1 && IsPlayerAlive(gamblerIDX))
		{
			EmitSoundToAll("mvm/mvm_bomb_explode.wav");
			for (int client = 0; client <= MaxClients; client++)
			{
				if (IsValidClient(client))
				{
					if (TF2_GetClientTeam(client) != TF2_GetClientTeam(gamblerIDX))
					{
						particle = CreateEntityByName("info_particle_system");
						
						if (IsValidEdict(particle))
						{
							float pos[3];
							GetClientAbsOrigin(client, pos);
       							//pos[0] += xOffs;
        					//pos[1] += yOffs;
        						//pos[2] += zOffs;
							TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
							DispatchKeyValue(particle, "effect_name", "fireSmoke_collumn_mvmAcres");
							DispatchKeyValue(particle, "targetname", "present");
							DispatchSpawn(particle);
							ActivateEntity(particle);
							AcceptEntityInput(particle, "Start");
						}
						else
						{
							LogError("(CreateParticle): Could not create info_particle_system");
						}
						SDKHooks_TakeDamage(client, gamblerIDX, gamblerIDX, 9999.0, DMG_ALWAYSGIB, -1);
					}
				}
			}
		}
	}
}

stock int GetLivingReds()
{
	int liveReds = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (TF2_GetClientTeam(i) == TFTeam_Red && IsPlayerAlive(i))
			{
				liveReds++;
			}
		}
	}
	return liveReds;
}

//Below was borrowed from Batfoxkid, credit goes to him
public void OnEntityCreated(int entity, const char[] classname)
{
	if(!StrContains(classname, POWERUP))
	SDKHook(entity, SDKHook_Spawn, KillOnSpawn); 
}
public Action KillOnSpawn(int entity) //Prevent powerups from simply being dropped when the boost ends (removing this means players can pick them up when the boost ends for a permanent buff)
{
	if(IsValidEdict(entity) && entity>MaxClients)
	{
		TeleportEntity(entity, OFF_THE_MAP, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "Kill");
	}
}
//Above was made by Batfox

stock int GetLivingBlues()
{
	int liveBlues = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (TF2_GetClientTeam(i) == TFTeam_Blue && IsPlayerAlive(i))
			{
				liveBlues++;
			}
		}
	}
	return liveBlues;
}
/*stock int GetRandomLivingRed()
{
	int client = GetRandomInt(1, MaxClients);
	
	
	while (!IsValidClient(client))
	
	while (!IsClientConnected(client) || TF2_GetClientTeam(client) != TFTeam_Red)
	{
		client = GetRandomInt(1, MaxClients);
	}
}*/
public void GiveRandomMannpower(int client, float duration)
{
	if (IsValidClient(client))
	{
		switch(GetRandomInt(1, 9))
		{
			case 1:
			{
				TF2_AddCondition(client, TFCond_RuneStrength, duration);
			}
			case 2:
			{
				TF2_AddCondition(client, TFCond_RuneHaste, duration);
			}
			case 3:
			{
				TF2_AddCondition(client, TFCond_RuneRegen, duration);
			}
			case 4:
			{
				TF2_AddCondition(client, TFCond_RuneResist, duration);
			}
			case 5:
			{
				TF2_AddCondition(client, TFCond_RuneVampire, duration);
			}
			case 6:
			{
				if (someoneHasReflect)
				{
					GiveRandomMannpower(client, perkDur);
				}
				else
				{
					TF2_AddCondition(client, TFCond_RuneWarlock, duration);
					someoneHasReflect = true;
				}
			}
			case 7:
			{
				TF2_AddCondition(client, TFCond_RunePrecision, duration);
			}
			case 8:
			{
				TF2_AddCondition(client, TFCond_RuneAgility, duration);
			}
			case 9:
			{
				TF2_AddCondition(client, TFCond_RuneKnockout, duration);
			}
		}
	}
}
stock bool IsValidClient(int client, bool replaycheck=true, bool onlyrealclients=true) //Function borrowed from Nolo001, credit goes to him.
{
	if(client<=0 || client>MaxClients)
	{
		return false;
	}
	
	if(!IsClientInGame(client))
	{
		return false;
	}
	
	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}
	
	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	//if(onlyrealclients)                    Commented out for testing purposes
	//{
	//	if(IsFakeClient(client))
	//		return false;
	//}
	
	return true;
}

stock bool IsInvuln(int client) //Borrowed from Batfoxkid
{
	if(!IsValidClient(client))
	return true;
	
	return (TF2_IsPlayerInCondition(client, TFCond_Ubercharged) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage) ||
		TF2_IsPlayerInCondition(client, TFCond_Bonked) ||
		TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode) ||
		//TF2_IsPlayerInCondition(client, TFCond_MegaHeal) ||
		!GetEntProp(client, Prop_Data, "m_takedamage"));
}