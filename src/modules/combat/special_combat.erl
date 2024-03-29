%%% -------------------------------------------------------------------
%%% 9秒社团全球首次开源发布
%%% http://www.9miao.com
%%% -------------------------------------------------------------------
-module(special_combat).

-compile(export_all).

-include("data_struct.hrl").

-include("common_define.hrl").
-include("skill_define.hrl").
-include("little_garden.hrl").

-include("role_struct.hrl").
-include("npc_struct.hrl").
-include("pet_struct.hrl").

%%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%%   涓�浜涚壒娈婂啓鐨勬妧鑳�
%%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


%浼ゅ鍙嶅脊鐩存帴鏍规嵁bufferid鍐欐鍦ㄤ簡绋嬪簭閲�,娉ㄦ剰
proc_reflect_destory(TargetInfo,DamageInfo)->
	BufferList = creature_op:get_buffer_from_creature_info(TargetInfo),
	case lists:keyfind(?COMBAT_RELECT_BUFF,1,BufferList) of
		{_,BuffLevel}->										%%鏈夊弽寮�
			case DamageInfo of
				missing->
					Damage = 0;
				{critical,CRD}->
					Damage = CRD; 				
				{normal,Dmg}->
					Damage = Dmg
			end,  
			BufferInfo = buffer_db:get_buffer_info(?COMBAT_RELECT_BUFF,BuffLevel),					
			[RefectValue] = buffer_db:get_buffer_effect_arguments(BufferInfo),
			
			erlang:trunc((Damage*RefectValue)/100);
		_->
			0
	end.
	
%%   %鎶�鑳戒笉鑰楄摑	鐩存帴鏍规嵁bufferid鍐欐鍦ㄤ簡绋嬪簭閲�,娉ㄦ剰	
proc_mp_resume(CreatureInfo,SkillInfo)->
	BufferList = creature_op:get_buffer_from_creature_info(CreatureInfo),
	MP = skill_db:get_cost(SkillInfo),	
	case ((MP =:= 0) or lists:keymember(?COMBAT_MP_BUFF,1,BufferList )) of 	
		true->			
			[];
		_ -> 			
			%%io:format("MP~p~n",[MP]),	
			MaxMp = creature_op:get_mpmax_from_creature_info(CreatureInfo),
			NewMp = erlang:min(creature_op:get_mana_from_creature_info(CreatureInfo) + MP,MaxMp),
			[{mp,NewMp}]		
	end.


