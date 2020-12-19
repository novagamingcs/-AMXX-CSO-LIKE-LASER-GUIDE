/* 
*
* 		The Plugin is Made by N.O.V.A , if Anybugs or Crash reports contact below
* 	
*		Contacts:-
*
* 		Fb:- facebook.com/nova.gaming.cs
* 		Insta :-  instagram.com/_n_o_v_a_g_a_m_i_n_g
* 		Discord :- N.O.V.A#1790
* 		Youtube :- NOVA GAMING
*		GitHub :- https://github.com/novagamingcs
*
*
*/


/*----------------------------------*/
/*           INCLUDES               */
/*----------------------------------*/

#include <amxmodx>
//#include <amxmisc>
#include <engine>
#include <fun>
#include <cstrike>
//#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>


/*----------------------------------*/
/*            DEFINES               */
/*----------------------------------*/

#define PLUGIN "[N:V] Laser Guide"
#define VERSION "V 1.0 | 01/12/20"
#define AUTHOR "N.O.V.A"

#define TASK_SKY 69874126


// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

#define weapon_laser_guide	"weapon_aug"
#define CSW_LASER	CSW_AUG
#define OLD_W_MODEL "models/w_aug.mdl"
#define WEAPON_SECRETCODE 56783298

/*----------------------------------*/
/*           MODE-SUPPORTS          */
/*----------------------------------*/

// Uncomment the Mod you are using and Comment the Others by "///"

#define NORMAL_MOD
//#define ZOMBIE_ESCAPE_MOD		
//#define ZOMBIE_PLAUGE


#if defined ZOMBIE_ESCAPE_MOD

	// Forwards 
	forward ze_select_item_pre(id, itemid);
	forward ze_select_item_post(id, itemid);
	forward ze_user_infected(id, itemid);
	
	// Natives
	native ze_register_item(const szItemName[], iCost, iLimit);
	native ze_is_user_zombie(id);
	
	//#include <zombie_escape> // Why Not Including it ? i also Don't know gotting some error in REAPI  "" undefine Symbol.
#endif

#if defined ZOMBIE_PLAUGE

	#include <zombieplague>
	
#endif

/*----------------------------------*/
/*        MODE-SUPPORTS-END         */
/*----------------------------------*/


/*----------------------------------*/
/*              NEWS                */
/*----------------------------------*/

new const Ground_Sprite_ClassName[] = "nv_class_laser_guide"
new const Mdl_Ground_Sprite[] = "sprites/laserguide_explosion.spr"
new const Mdl_Sky_Sprite[] = "sprites/laserguide_sky.spr"
new const V_MODEL[] = "models/bynova/v_laserguide.mdl"
new const P_MODEL[] = "models/bynova/p_laserguide.mdl"
new const W_MODEL[] = "models/bynova/w_laserguide.mdl"

new const szSounds[][] =
{
	"weapons/laserguide_complete.wav",
	"weapons/laserguide_draw.wav",
	"weapons/laserguide_failed.wav",
	"weapons/laserguide_exp.wav",
	"weapons/laserguide_shoot.wav"
};

new g_spr_sky,g_max_players,g_has_laser,g_has_used,g_sprite,g_iCvars[10],g_Used[33],g_itemid;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	Register_Cvars();
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1");
	register_event("ResetHUD", "newRound", "b"); 
	register_logevent("logevent_round_end", 2, "1=Round_End") 
	
	// Forwards
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	
	// Ham
	RegisterHam(Ham_Item_AddToPlayer, weapon_laser_guide, "fw_Item_AddToPlayer_Post", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack,weapon_laser_guide,"fw_Primary_Attack");
	register_think(Ground_Sprite_ClassName,"think_sprite");
	
	register_clcmd("weapon_laser_guide","weapon_hook");
	
	//g_Msg_CurWeapon = get_user_msgid("CurWeapon");
	
	g_max_players = get_maxplayers();
	
	#if defined NORMAL_MOD
		register_clcmd("say /laser","clcmd");
	#endif
	
	#if defined ZOMBIE_ESCAPE_MOD
		g_itemid = ze_register_item("[CSO] Laser Guide", 30, 0);
	#endif

	#if defined ZOMBIE_PLAUGE
		g_itemid = zp_register_extra_item("[CSO] Laser Guide", 30 ,ZP_TEAM_HUMAN);
	#endif
	
}

public weapon_hook(id)
{
	engclient_cmd(id, weapon_laser_guide); 
	return PLUGIN_HANDLED;
}

public Register_Cvars()
{	
	register_cvar("nv_zp_cso_laser_guide", VERSION, FCVAR_SERVER | FCVAR_SPONLY);
	g_iCvars[0] = register_cvar("nv_lg_dmg_per_second","5.0");
	g_iCvars[1] = register_cvar("nv_lg_reload_time","20.0");
	g_iCvars[2] = register_cvar("nv_lg_max_use","5");
	g_iCvars[3] = register_cvar("nv_lg_cost","3000");
	g_iCvars[4] = register_cvar("nv_lg_time_attack","20.0");
	
}

public plugin_natives()
{
	register_native("nv_give_laser_guide","Give_Laser",1);
	register_native("nv_remove_laser_guide","Remove_Laser",1);
}
public plugin_precache()
{
	for(new i=0;i<sizeof(szSounds);i++)
	{
		precache_sound(szSounds[i]);
	}
	
	precache_model(Mdl_Ground_Sprite);
	precache_model(V_MODEL);
	precache_model(P_MODEL);
	precache_model(W_MODEL);
	
	g_spr_sky = precache_model(Mdl_Sky_Sprite);
	g_sprite = precache_model("sprites/white.spr");
	precache_generic( "sprites/weapon_laser_guide.txt" );
	precache_generic( "sprites/640_hud_laser_guide.spr" );
}

#if AMXX_VERSION_NUM >= 183

public client_disconnected(id) Remove_Laser(id);

#else

public client_disconnect(id) Remove_Laser(id);

#endif

#if defined ZOMBIE_PLAUGE

public zp_extra_item_selected(id, itemid)
{
	if (itemid == g_itemid)
	{
		Give_Laser(id);
	}
}

public zp_user_infected_pre(id)
{
	Remove_Laser(id);

}
public zp_user_humanized_pre(id)
{
	Remove_Laser(id);
}

#endif

#if defined ZOMBIE_ESCAPE_MOD

public ze_select_item_pre(id, itemid)
{
    if (itemid != g_itemid)
        return 0;	// xD
   
    if (ze_is_user_zombie(id))
        return 2;	// Double xD
   
    return 0;		// xD
}


public ze_select_item_post(id, itemid)
{
	if (itemid == g_itemid)
	{
		Give_Laser(id);
	}

}

public ze_user_infected(id, infector)
{
	if(Get_BitVar(g_has_laser,id)) Remove_Laser(id);
}

#endif

public newRound()
{
	for(new i=1;i<= g_max_players;i++)
	{
		Remove_Laser(i);
	}
	
	remove_entity_name(Ground_Sprite_ClassName);
}

public logevent_round_end()
{
	for(new i=1;i<= g_max_players;i++)
	{
		fm_strip_user_gun(i,CSW_LASER);
		Remove_Laser(i);
	}
	remove_entity_name(Ground_Sprite_ClassName);
	
}

public Event_CurWeapon(id)
{
	if(is_user_alive(id))
	{
		static CSWID; CSWID = read_data(2);
		if(CSWID == CSW_LASER && Get_BitVar(g_has_laser,id))
		{
			set_pev(id, pev_viewmodel2, V_MODEL);
			set_pev(id, pev_weaponmodel2, P_MODEL);
		}
	}
}


public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED;	
	if(get_user_weapon(id) == CSW_LASER && Get_BitVar(g_has_laser, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001);
	
	return FMRES_HANDLED;
}

public fw_CmdStart(id, uc_handle, seed)
{
	
	if(!is_user_alive(id)) return FMRES_IGNORED;
	
	if(cs_get_user_weapon(id) == CSW_LASER && Get_BitVar(g_has_laser,id))
	{
		if(g_Used[id] != 0)
		{
			Set_Clip(id,0);
			cs_set_user_bpammo(id,CSW_LASER,0);
	
			static PressButton; PressButton = get_uc(uc_handle, UC_Buttons);
			static OldButton; OldButton = pev(id, pev_oldbuttons);
			if(!(OldButton & IN_ATTACK) && PressButton & IN_ATTACK)
			{
				if(Get_BitVar(g_has_used,id))
				{
					UnSet_BitVar(g_has_used,id);
					Send_BarTime(id,2.0);
			
					set_task(2.0,"Call_Attack",id);
					set_task(get_pcvar_float(g_iCvars[1]),"CanShoot",id);
					set_weapon_anim(id,1);
			
					emit_sound(id, CHAN_WEAPON, szSounds[4], 1.0, ATTN_NORM, 0, PITCH_NORM);
				}
				else
				{
					client_print(id,print_center,"Reloading....");
					emit_sound(id, CHAN_WEAPON, szSounds[2], 1.0, ATTN_NORM, 0, PITCH_NORM);
				}
		
			}
		}
	}
	else
		ammo_hud(id,0);
	return FMRES_IGNORED;
}

public fw_Primary_Attack(ent)
{
	if(pev_valid(ent))
	{
		new id = pev(ent,pev_owner);
		
		if(Get_BitVar(g_has_laser,id))
		{
			return HAM_SUPERCEDE;
		}
	}	
	return HAM_IGNORED;	
}

public CanShoot(id)
{
	if(Get_BitVar(g_has_laser,id))
		Set_BitVar(g_has_used,id);
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED;
	
	static szClassName[33];
	pev(entity, pev_classname, szClassName, charsmax(szClassName));
	
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED;
	
	static id;
	id = pev(entity, pev_owner);
	
	if(equal(model, OLD_W_MODEL))
	{
		static weapon; weapon = fm_find_ent_by_owner(-1, weapon_laser_guide, entity);
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(Get_BitVar(g_has_laser, id))
		{
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE);
			engfunc(EngFunc_SetModel, entity, W_MODEL);
			set_pev(weapon,pev_iuser1,g_Used[id]);
			Remove_Laser(id);
			ammo_hud(id,0);
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED;
		
	if(pev(Ent, pev_impulse) == WEAPON_SECRETCODE)
	{
		Set_BitVar(g_has_laser, id);
		Set_BitVar(g_has_used,id);
		
		ammo_hud(id,0);
		g_Used[id] = pev(Ent,pev_iuser1);
		ammo_hud(id,1);
		set_pev(Ent, pev_impulse, 0);
		Set_Clip(id,0); // :-D
		cs_set_user_bpammo(id,CSW_LASER,0);
		Wpnlist(id,1);
		
	}
	else
		Wpnlist(id,0);
	
	return HAM_HANDLED;
}

public clcmd(id)
{
	if(is_user_alive(id))
	{
		if(cs_get_user_money(id) >= get_pcvar_num(g_iCvars[3]))
		{
			Give_Laser(id);
			cs_set_user_money(id,cs_get_user_money(id) - get_pcvar_num(g_iCvars[3]));
		}
		else
			ChatColor(id,"^3[^4LASER-GUIDE^3]^4 You Didn't Have Enough Money.");
	}
}

public Give_Laser(id)
{
	if(is_user_alive(id))
	{
		if(!Get_BitVar(g_has_laser,id))
		{
			Stock_DropSlot(id,1);
			Set_BitVar(g_has_laser,id);
			Set_BitVar(g_has_used,id);
			give_item(id,weapon_laser_guide);
			Set_Clip(id,0); // :-D
			cs_set_user_bpammo(id,CSW_LASER,0);
			Wpnlist(id,1);
			ammo_hud(id,0);
			g_Used[id] = get_pcvar_num(g_iCvars[2]);
			ammo_hud(id,1);
		}
		else
		{
			// Refil Player Ammo
			
			ammo_hud(id,0);
			g_Used[id] += 1; 
			ammo_hud(id,1);
		}
	}
}

public Remove_Laser(id)
{
	UnSet_BitVar(g_has_laser,id);
	UnSet_BitVar(g_has_used,id);
	g_Used[id] = 0;
	Wpnlist(id,0);
}

public Call_Attack(id)
{
	if(is_user_alive(id))
	{
		new Float:Origin[3];
		get_user_hitpoint(id,Origin);
		
		if(is_origin_in_free_space(Origin,300.0) && !is_aiming_at_sky(id))
		{
			Origin[0] += 70.0;
			Origin[2] += 5.0;
			
			// Just Show this in Sentry Gun Code , And it works xD
			ammo_hud(id,0);
			g_Used[id] -= 1;
			ammo_hud(id,1);
			
			Create_Ground_Sprite(id,Origin);
			Create_Beam(id,0,128,0);
			emit_sound(id, CHAN_WEAPON, szSounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
		else
		{
			Create_Beam(id,255,0,0);
			Set_BitVar(g_has_used,id);
			emit_sound(id, CHAN_WEAPON, szSounds[2], 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
		
	}
}

public Create_Ground_Sprite(id,Float:origin[3])
{
	new Float:Angle[3];
	new ent = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "env_sprite" ) );
	engfunc( EngFunc_SetOrigin, ent, origin );
	engfunc( EngFunc_SetModel, ent, Mdl_Ground_Sprite );
	
	set_pev( ent, pev_classname, Ground_Sprite_ClassName);
	set_pev( ent, pev_rendermode, kRenderTransAdd );
	set_pev( ent, pev_movetype, MOVETYPE_TOSS);
	set_pev( ent, pev_renderamt, 255.0 );
	set_pev( ent, pev_animtime,get_gametime());
	set_pev( ent, pev_frame,0.0);
	set_pev( ent, pev_scale , 7.0);
	set_pev( ent, pev_spawnflags, SF_SPRITE_STARTON );
	set_pev( ent, pev_iuser3, id);
	
	Angle[0] += 90.0;
	
	set_pev( ent, pev_angles, Angle);
	dllfunc( DLLFunc_Spawn, ent );
	
	set_task(1.5,"Show_Sky_Sprite",ent+TASK_SKY,_,_,"b");
	set_task(get_pcvar_float(g_iCvars[4]),"remove_valid_entity",ent);
	set_pev(ent,pev_nextthink,get_gametime() + 1.5);
	
}

public Show_Sky_Sprite(taskid)
{
	new ent = taskid-TASK_SKY;
	if(pev_valid(ent))
	{
		new Float:origin[3];
		pev(ent,pev_origin,origin);
		message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
		write_byte(TE_SPRITE);
		write_coord_f(origin[0]);
		write_coord_f(origin[1]);
		write_coord_f(origin[2] + 100.0);
		write_short(g_spr_sky);
		write_byte(60);
		write_byte(200);
		message_end();
		
		new Float:fOrigin[3];
		new iVictim = -1;
		new iOwner = pev(ent,pev_iuser3);
		
		pev(ent,pev_origin,fOrigin);
		
		while((iVictim = find_ent_in_sphere(iVictim, fOrigin, 500.0)))
		{
			if(is_target_capable(iOwner,iVictim))
			{
				if(cs_get_user_team(iVictim) != cs_get_user_team(iOwner))
				{
					ExecuteHam(Ham_TakeDamage, iVictim, ent, iOwner, get_pcvar_float(g_iCvars[0]), DMG_BURN);
				}
			}
		}
		
		for(new i=1;i<= g_max_players;i++)
		{
			Util_ScreenShake(i);
			emit_sound(i, CHAN_WEAPON, szSounds[3], 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
	}
	else
		remove_task(taskid);
}

public think_sprite(ent)
{
	if(pev_valid(ent))
	{
		// Why Using this ? The Framerate was too Slow 1 Frames seconds so i use this :-)
		
		if(pev(ent,pev_frame) <= 30.0)
		{
			set_pev(ent,pev_frame,pev(ent,pev_frame) + 1.0);
		}
		else
		{
			set_pev(ent,pev_frame,0.0);
		}
		set_pev(ent,pev_nextthink,get_gametime() + 0.1);
	}
}

public Create_Beam(id,red,green,blue)
{
	new e[3];
	get_user_origin(id, e, 3);
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte (TE_BEAMENTPOINT);
	write_short(id | 0x1000);
	write_coord (e[0]);
	write_coord (e[1]);
	write_coord (e[2]);
	write_short(g_sprite);		// Sprite
		
	write_byte (1);   		// Start frame				
	write_byte (10);     		// Frame rate					
	write_byte (20);			// Life
	write_byte (7);   		// Line width				
	write_byte (0);    		// Noise
	write_byte (red); 		// Red
	write_byte (green);		// Green
	write_byte (blue);		// Blue
	write_byte (250);     		// Brightness					
	write_byte (25);      		// Scroll speed					
	message_end();
	
}

public is_target_capable(owner,target)
{
	if(is_user_alive(owner) && is_user_alive(target))
	{
		#if defined NORMAL_MOD
		
		if(cs_get_user_team(owner) != cs_get_user_team(target) && owner != target)
			return true;
		
		#endif
		
		#if defined ZOMBIE_ESCAPE_MOD
		if(ze_is_user_zombie(target) && owner != target)
			return true;
		
		#endif
		
		#if defined ZOMBIE_PLAUGE
		
		if(zp_get_user_zombie(target) && owner != target)
			return true;
			
		#endif
		
	}
	return false;
}

public remove_valid_entity(ent) 
{
	if(pev_valid(ent))
	{
		remove_task(ent+TASK_SKY);
		remove_entity(ent);
	}
}


stock get_user_hitpoint(id, Float:hOrigin[3])  
{ 
	if (!is_user_alive( id )) 
	return 0; 
	
	new Float:fOrigin[3], Float:fvAngle[3], Float:fvOffset[3], Float:fvOrigin[3], Float:feOrigin[3]; 
	new Float:fTemp[3]; 
	
	pev(id, pev_origin, fOrigin); 
	pev(id, pev_v_angle, fvAngle); 
	pev(id, pev_view_ofs, fvOffset); 
	
	xs_vec_add(fOrigin, fvOffset, fvOrigin); 
	
	engfunc(EngFunc_AngleVectors, fvAngle, feOrigin, fTemp, fTemp); 
	
	xs_vec_mul_scalar(feOrigin, 9999.0, feOrigin); 
	xs_vec_add(fvOrigin, feOrigin, feOrigin); 
	
	engfunc(EngFunc_TraceLine, fvOrigin, feOrigin, 0, id); 
	global_get(glb_trace_endpos, hOrigin); 
	
	return 1; 
}  


stock Util_ScreenShake(id)
{
	static ScreenShake = 0;
	if( !ScreenShake )
	{
		ScreenShake = get_user_msgid("ScreenShake");
	}
	if(is_user_connected(id))
	{
		message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, ScreenShake, _, id);
		write_short(255<<14); //ammount 
		write_short(10 << 14); //lasts this long 
		write_short(255<< 14); //frequency 
		message_end();
	}
}

stock bool:is_origin_in_free_space(Float:Origin[3],Float:Radius)
{
	new ent,classname[32]; 
	ent = -1;
	while((ent = engfunc ( EngFunc_FindEntityInSphere, ent, Origin,Radius ) ) != 0)
	{
		pev(ent, pev_classname, classname, 31);
		if(equali(classname, "func_wall") || equali(classname, "func_breakable"))
		{
			return false;
		}
	}
	
	return true;
}

 
stock bool:is_aiming_at_sky(index)
{
    static iOrigin[3];
    get_user_origin(index, iOrigin, 3);
    
    static Float:vOrigin[3];
    IVecFVec(iOrigin, vOrigin);
    return (engfunc(EngFunc_PointContents, vOrigin) == CONTENTS_SKY);
}

Send_BarTime(player,Float:duration)
{	
	if(is_user_alive(player))
	{
	
		message_begin(MSG_ONE,get_user_msgid("BarTime"),.player = player);
		write_short(floatround(duration));
		message_end();
	}
}


ammo_hud(id, sw)
{
	if(is_user_bot(id)||!is_user_alive(id)||!is_user_connected(id)) 
			return;

	new s_sprite[33];
	format(s_sprite, 32, "number_%d", g_Used[id]);
	if(sw)
	{
		message_begin( MSG_ONE, get_user_msgid("StatusIcon"), {0,0,0}, id );
		write_byte( 1 ); // status
		write_string( s_sprite ); // sprite name
		write_byte( 255 ); // red
		write_byte( 0 ); // green
		write_byte( 0 ); // blue
		message_end();
	}
	else 
	{
		message_begin( MSG_ONE, get_user_msgid("StatusIcon"), {0,0,0}, id );
		write_byte( 0 ); // status
		write_string( s_sprite ); // sprite name
		write_byte( 255 ); // red
		write_byte( 0 ); // green
		write_byte( 0 ); // blue
		message_end();
	}
	
	if(g_Used[id] <= 0 || g_Used[id] > 9 )
	{
		message_begin( MSG_ONE, get_user_msgid("StatusIcon"), {0,0,0}, id );
		write_byte( 0 ); // status
		write_string( s_sprite ); // sprite name
		write_byte( 255); // red
		write_byte( 0 ); // green
		write_byte( 0 ); // blue
		message_end();
	}    
}


public Set_Clip(id,CLIPS)
{
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_LASER);
	if(pev_valid(Ent)) cs_set_weapon_ammo(Ent, CLIPS);
	
	/*engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, g_Msg_CurWeapon, {0, 0, 0}, id);
	write_byte(1);
	write_byte(CSW_LASER);
	write_byte(CLIPS);
	message_end();*/
}

public Wpnlist(id,type)
{
    if(is_user_connected(id))
    {
	engfunc(EngFunc_MessageBegin,MSG_ONE, get_user_msgid("WeaponList"), {0,0,0}, id);
	write_string(type?"weapon_laser_guide":"weapon_aug");
	write_byte(type? -1:3); // not Sure about it
	write_byte(-1);
	write_byte(-1);
	write_byte(-1);
	write_byte(0);
	write_byte(1);
	write_byte(CSW_LASER);
	write_byte(0);
	message_end();
   }

}


stock Stock_DropSlot(iPlayer, Slot)
{
	new item = get_pdata_cbase(iPlayer, 367+Slot, 4);
	while(item > 0)
	{
		static classname[24];
		pev(item, pev_classname, classname, charsmax(classname));
		engclient_cmd(iPlayer, "drop", classname);
		item = get_pdata_cbase(item, 42, 5);
	}
	set_pdata_cbase(iPlayer, 367, -1, 4);
}

stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return;
	
	set_pev(id, pev_weaponanim, anim);
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id);
	write_byte(anim);
	write_byte(pev(id, pev_body));
	message_end();
}

stock ChatColor(const id, const input[], any:...)
{
	new count = 1, players[32];
	static msg[191];
	vformat(msg, 190, input, 3);
       
	replace_all(msg, 190, "!g", "^4"); // Green Color
	replace_all(msg, 190, "!y", "^1"); // Default Color
	replace_all(msg, 190, "!team", "^3"); // Team Color
	replace_all(msg, 190, "!team2", "^0"); // Team2 Color
       
        if (id) players[0] = id; else get_players(players, count, "ch");
        {
                for (new i = 0; i < count; i++)
                {
                        if (is_user_connected(players[i]))
                        {
                                message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);
                                write_byte(players[i]);
                                write_string(msg);
                                message_end();
                        }
                }
        }
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2057\\ f0\\ fs16 \n\\ par }
*/
