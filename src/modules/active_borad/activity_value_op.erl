%%% -------------------------------------------------------------------
%%% 9秒社团全球首次开源发布
%%% http://www.9miao.com
%%% -------------------------------------------------------------------
%% Author: Administrator
%% Created: 2011-7-11
%% Description: TODO: Add description to activity_value_op
-module(activity_value_op).

%%
%% Include files
%%
-include("activity_value_define.hrl").
-include("error_msg.hrl").
-include("common_define.hrl").
-include("data_struct.hrl").
-include("role_struct.hrl").
-include("string_define.hrl").
%%
%% Exported Functions
%%
-compile(export_all).

%%
%% dictionary define
%%

%% av_activity_msg [{id,{type,target}}]
%% av_activity_state {timestamp,[{id,onestep,times}]} %% 浠诲姟id  褰撳墠姝ラ瀹屾垚鐨勮繘搴�   鎬昏繘搴�
%% av_activity_info {value,reward}		%%娲昏穬搴� 鏄惁棰嗗彇杩囧鍔�

%%
%% API Functions
%%

init()->
	put(av_activity_msg,activity_value_db:create_av_msg()),
	Now = now(),			
	case activity_value_db:get_activity_value_info(get(roleid)) of
		[]->
			NewValue = 0,
			NewRewardFlag = false,
			put(av_activity_state,{Now,activity_value_db:create_av_state()});
		AVInfo->
			Value = activity_value_db:get_activity_value(AVInfo),
			RewardFlag = activity_value_db:get_activity_rewardflag(AVInfo),
			%%put(av_activity_info,{Value,RewardFlag}),
			StateInfo = activity_value_db:get_activity_value_state(AVInfo),
			{TimeStamp,State} =  StateInfo,
			case timer_util:check_same_day(TimeStamp,Now) of
				true->
					NewState = 
						lists:filter(fun({Id,OneStep,TotalTimes})->
									case lists:keyfind(Id,1,State) of
										false->
											true;
										_->
											false
									end
							end,activity_value_db:create_av_state()),
					put(av_activity_state,{TimeStamp,State ++ NewState}),
					NewValue = Value,
					NewRewardFlag = RewardFlag;
				_->
					put(av_activity_state,{Now,activity_value_db:create_av_state()}),
					if
						RewardFlag-> %%reward
							nothing;
						true->	%%
							RoleInfo = get(creature_info),
							RoleName = get_name_from_roleinfo(RoleInfo),
							RoleLevel = get_level_from_roleinfo(RoleInfo),
							send_remain_reward_delay(RoleName,RoleLevel,Value,TimeStamp)		
					end,
					NewValue = 0,
					NewRewardFlag = false,
					activity_value_db:update_activity_value(get(roleid),get(av_activity_state),NewValue,NewRewardFlag)
			end
	end,
	put(av_activity_info,{NewValue,NewRewardFlag}),
	{_,NewAVInfo} = get(av_activity_state),
	AvList = lists:map(fun({Id,_,Times})->
						activity_value_packet:make_av(Id,Times)
						end,NewAVInfo),
	%%{NewValue} = get(av_activity_info),
	if
		NewRewardFlag->
			Status = ?COMPLETE;
		true->
			Status = ?UNCOMPLETED
	end,
	MsgBin = activity_value_packet:encode_activity_value_init_s2c(AvList,NewValue,Status),
	role_op:send_data_to_gate(MsgBin).

export_for_copy()->
	{get(av_activity_msg),get(av_activity_state),get(av_activity_info)}.

load_by_copy(AVInfo)->
	{Msg,State,Info} = AVInfo,
	put(av_activity_msg,Msg),
	put(av_activity_state,State),
	put(av_activity_info,Info).

%%
%%鍒濆鍖�
%%
process_message({activity_value_init_c2s,_})->
	{TimeStamp,AVInfo} = get(av_activity_state),
	{Value,RewardFlag} = get(av_activity_info),
	Now = now(),
	case timer_util:check_same_day(TimeStamp,Now) of
		true->
			nothing;
		_->
			NewAVInfo = activity_value_db:create_av_state(),
			put(av_activity_state,{Now,NewAVInfo}),
			put(av_activity_info,{0,false}),
			if
				RewardFlag->
					nothing;
				true->
					RoleInfo = get(creature_info),
					RoleName = get_name_from_roleinfo(RoleInfo),
					RoleLevel = get_level_from_roleinfo(RoleInfo),
					send_remain_reward(RoleName,RoleLevel,Value,TimeStamp)
			end,
			%% update db
			activity_value_db:update_activity_value(get(roleid),get(av_activity_state),0,false),
			AvList = lists:map(fun({Id,_,Times})->
						activity_value_packet:make_av(Id,Times)
						end,NewAVInfo),
			MsgBin = activity_value_packet:encode_activity_value_init_s2c(AvList,0,?UNCOMPLETED),
			role_op:send_data_to_gate(MsgBin)
	end;
	

%%
%%棰嗗彇濂栧姳
%%TODO
process_message({activity_value_reward_c2s,_,Id})->
	%%check value
	{TimeStamp,_} = get(av_activity_state),
	{MyValue,RewardFlag} = get(av_activity_info),
	if
		RewardFlag->
			nothing;
		true->
			MyLevel = get_level_from_roleinfo(get(creature_info)),
			MyRewardId = active_board_util:get_reward_type(MyLevel),%%濂栧姳鐗╁搧鎸夌瓑绾ф閰嶇疆  闇�瑕佽浆鎹㈢瓑绾�
			case activity_value_db:get_reward_info(Id) of
				[]->
					slogger:msg("~p activity_value_db:get_reward_info error id ~p",[get(roleid),Id]);
				TableInfo->
					Rewards = activity_value_db:get_reward(TableInfo),
					case get_my_reward(MyRewardId,Rewards) of
						[]->
							OptCode = ?ACTIVITY_VALUE_ITEM_NOT_EXIST,
							OptMsgBin = activity_value_packet:encode_activity_value_opt_s2c(OptCode),
							role_op:send_data_to_gate(OptMsgBin);
						{ItemId,ValueNeed}->
							if
								ValueNeed > MyValue->
									OptCode = ?ACTIVITY_VALUE_NOT_ENOUGH,
									OptMsgBin = activity_value_packet:encode_activity_value_opt_s2c(OptCode),
									role_op:send_data_to_gate(OptMsgBin);
								true->
									case role_op:auto_create_and_put(ItemId,1,got_activity_reward) of
										{ok,_} ->
											Exp = get_reward_exp(MyLevel,MyValue),
											role_op:obtain_exp(Exp),
											put(av_activity_info,{0,true}),
											gm_logger_role:role_activity_value_reward(get(roleid),ValueNeed,Id,0,get(level)),		
											OptCode = ?ACTIVITY_VALUE_REWARD_SUCCESS,
											OptMsgBin = activity_value_packet:encode_activity_value_opt_s2c(OptCode),
											role_op:send_data_to_gate(OptMsgBin),											
											UpdateMsgBin = activity_value_packet:encode_activity_value_update_s2c([],0,?COMPLETE),
											role_op:send_data_to_gate(UpdateMsgBin),
											%%update db
											activity_value_db:update_activity_value(get(roleid),get(av_activity_state),0,true);
										_->
											nothing
									end
							end
					end
			end
	end;
	
process_message({send_remain_reward,{RoleName,RoleLevel,Value,TimeStamp}})->
	send_remain_reward(RoleName,RoleLevel,Value,TimeStamp);	

process_message(_)->
	nothing.


	
%%
%%{monster_kill,ProtoId}鏉�鎬�
%%{instance,InstanceId}杩涘叆鍓湰
%%{join_activity,ActivityId}鍙傚姞娲诲姩
%%{complete_quest,QuestId}瀹屾垚鏌愪釜鏅�氫换鍔�
%%{complete_everquest_by_section,EverQuestId}	瀹屾垚鏃ュ父浠诲姟鎸夋璁＄畻
%%{complete_everquest_by_round,EverQuestId}		瀹屾垚鏃ュ父浠诲姟鎸夎疆璁＄畻
%%{complete_everquest,EverQuestId}		瀹屾垚鏃ュ父浠诲姟鎸変换鍔℃暟璁＄畻

update(Msg)->
	update(Msg,1).
	
%%
%% Local Functions
%%

%%
%%鐗╁搧鐨勬牸寮�  [[itemid1,value],[itemid2,value],[itemid3,value],[itemid4,value]]
%%
get_my_reward(LevelId,Rewards)->
	Result = lists:nth(LevelId,Rewards),
%%	io:format("get_my_reward ~p ~n",[Result]),
	case Result of
		[]->
			[];
		[ItemId,Value]->
			{ItemId,Value};
		_->
			[]
	end.
update(Msg,MsgValue)->
	update_public(Msg,MsgValue,1).

update_public(Msg,MsgValue,Times_param)->
	case get_msg_info(Msg) of
		[]->
			nothing;
		MsgInfo->
			{_,Op,MaxValue,Id} = MsgInfo,
			case activity_value_db:get_info(Id) of
				[]->
					slogger:msg("activity_value_db:get_info error id ~p",[Id]);
				Info->	
					update_av_state(),
					{CurValue,RewardFlag} = get(av_activity_info),
					MaxTimes = activity_value_db:get_maxtimes(Info),
					TimeLines = activity_value_db:get_time(Info),
					{TimeStamp,AVInfo} = get(av_activity_state),
					{_,CurTimes,TotalTimes} = lists:keyfind(Id,1,AVInfo), 				
					Add_Value = activity_value_db:get_value(Info),
					if
						MaxTimes =< TotalTimes,MaxTimes =/= 0 ->		%%宸插畬鎴� 锛堟帓闄や笉闄愭鏁扮殑锛�
							nothing;
						true ->%%
							CanContinue = 
								case check_time(TimeLines) of
									false->					%%鏃堕棿涓嶇
										false;
									_->
										true
								end,
							if
								CanContinue->
									case check_complete(Op,MsgValue,CurTimes,MaxValue) of
										true->									%%瀹屾垚Times_param娆�
											NewTotalTimes = TotalTimes + Times_param,
											if
												RewardFlag->			%%宸查鍙栬繃濂栧姳  涓嶅啀澧炲姞
													NeedAddValue = false;
												MaxTimes =:= 0->		%%涓嶉檺娆℃暟
													NeedAddValue = true;
												true->
													NeedAddValue = (NewTotalTimes >= MaxTimes)
											end,
											if	
												NeedAddValue->											
													NewValue = erlang:min(CurValue + Add_Value,?MAX_ACTIVITY_VALUE),
													gm_logger_role:role_activity_value(get(roleid),Add_Value,NewValue,Id,get(level));
												true->
													NewValue = CurValue
											end,
											gm_logger_role:role_activity_value_change(get(roleid),Id,get(level),NewTotalTimes,MaxTimes),
											NewCurTimes = 0,
											%%send update msg
											AVMsg = activity_value_packet:make_av(Id,NewTotalTimes), 
											MsgBin = activity_value_packet:encode_activity_value_update_s2c([AVMsg],NewValue,?UNCOMPLETED),
											role_op:send_data_to_gate(MsgBin);				
										false->										
											NewTotalTimes = TotalTimes,
											NewCurTimes =  CurTimes,
											NewValue = CurValue;
										NewCompleteValue->
											if
												NewCompleteValue>=MaxValue->	%%绱姞瀹屾垚
													NewTotalTimes = TotalTimes + Times_param,	
													if
														RewardFlag->				%%宸查鍙栬繃濂栧姳  涓嶅啀澧炲姞
															NeedAddValue = false;
														MaxTimes =:= 0->		%%涓嶉檺娆℃暟
															NeedAddValue = true;
														true->
															NeedAddValue = (NewTotalTimes >= MaxTimes)
													end,
													if	
														NeedAddValue->											
															NewValue = erlang:min(CurValue + Add_Value,?MAX_ACTIVITY_VALUE),
															gm_logger_role:role_activity_value(get(roleid),Add_Value,NewValue,Id,get(level));
														true->
															NewValue = CurValue
													end,
													gm_logger_role:role_activity_value_change(get(roleid),Id,get(level),NewTotalTimes,MaxTimes),										
													NewCurTimes = NewCompleteValue - MaxValue,		%%澶氫綑鐨勯儴鍒嗙疮鍔犲埌涓嬩竴娆�
													%%send update msg
													AVMsg = activity_value_packet:make_av(Id,NewTotalTimes), 
													MsgBin = activity_value_packet:encode_activity_value_update_s2c([AVMsg],NewValue,?UNCOMPLETED),
													role_op:send_data_to_gate(MsgBin);
												true->
													NewTotalTimes = TotalTimes,
													NewCurTimes =  NewCompleteValue,
													NewValue = CurValue
											end
									end,
									NewAVInfo = lists:keyreplace(Id,1,AVInfo,{Id,NewCurTimes,NewTotalTimes}),
									put(av_activity_state,{TimeStamp,NewAVInfo}),
									put(av_activity_info,{NewValue,RewardFlag}),
									%%update db
									activity_value_db:update_activity_value(get(roleid),get(av_activity_state),NewValue,RewardFlag);
								true->
									nothing
							end
					end
			 end
	end.	


update_av_state()->
	{TimeStamp,AVInfo} = get(av_activity_state),
	Now = now(),
	case timer_util:check_same_day(TimeStamp,Now) of
		true->
			nothing;
		_->
			{CurValue,RewardFlag} = get(av_activity_info),
			if
				not RewardFlag ->
					RoleInfo = get(creature_info),
					RoleName = get_name_from_roleinfo(RoleInfo),
					RoleLevel = get_level_from_roleinfo(RoleInfo),
					send_remain_reward(RoleName,RoleLevel,CurValue,TimeStamp),
					put(av_activity_state,{now(),activity_value_db:create_av_state()}),
					activity_value_db:update_activity_value(get(roleid),get(av_activity_state),0,false),
					UpateMsgBin = activity_value_packet:encode_activity_value_update_s2c([],0,?UNCOMPLETED),
					role_op:send_data_to_gate(UpateMsgBin);
				true->
					nothing
			end,
			put(av_activity_info,{0,false}),
			put(av_activity_state,{Now,activity_value_db:create_av_state()})
	end.


gm_add_av_value(Add_Value)->
	{CurValue,_} = get(av_activity_info),
	if
		CurValue >= ?MAX_ACTIVITY_VALUE->
			nothing;
		Add_Value =:= 0->
			nothing;	
		true->
			MinValue = erlang:min(CurValue + Add_Value,?MAX_ACTIVITY_VALUE),
			NewValue = erlang:max(MinValue,0),
			put(av_activity_info,{NewValue,false}),
			UpdateMsgBin = activity_value_packet:encode_activity_value_update_s2c([],NewValue,?UNCOMPLETED),
			role_op:send_data_to_gate(UpdateMsgBin),
			%%update db
			activity_value_db:update_activity_value(get(roleid),get(av_activity_state),NewValue,false)
	end.
	
%%
%%
%%return [] | MsgInfo
%%

get_msg_info(Msg)->
	case lists:keyfind(Msg,1,get(av_activity_msg)) of
		false->
			[];
		Info->
			Info
	end.

%%
%%妫�鏌ユ椂闂�
%% return true | false
%%
check_time(TimeRange)->
	case TimeRange of
		[]->
			true;
		{?DUE_TYPE_DAY,TimeLines}->
			NowTime = calendar:now_to_local_time(timer_center:get_correct_now()),
			lists:foldl(fun(TimeLine,Acc)->
						if
							Acc->
								true;
							true->
								timer_util:check_sec_is_in_timeline_by_day(NowTime,TimeLine)
						end	
					end,false,TimeLines);
		_->
			false
	end.

%%
%%妫�鏌ュ畬鎴愭潯浠�
%%return true|false|newvalue
%%
check_complete(Op,MsgValue,CurValue,MaxValue)->
	case Op of
		add_to->
			CurValue + MsgValue;
		eq->
			MsgValue =:= MaxValue;
		ge -> 
			MsgValue > MaxValue; 
		le ->
			MsgValue < MaxValue
	end.

%%
%%璁＄畻濂栧姳缁忛獙
%%
get_reward_exp(Level,Value)->
	120*Level*Value.

%%
%%鑾峰彇鍚堥�傜殑濂栧姳鐗╁搧
%%
get_adapt_reward_item(Level,Value)->
	MyRewardId = active_board_util:get_reward_type(Level),%%濂栧姳鐗╁搧鎸夌瓑绾ф閰嶇疆  闇�瑕佽浆鎹㈢瓑绾�
	AllRewards = activity_value_db:get_all_reward(),
	lists:foldl(fun(RewardList,{NeedValueAcc,ItemIdAcc})->
					case get_my_reward(MyRewardId,RewardList) of
						[]->
							{NeedValueAcc,ItemIdAcc};
						{ItemId,RewardValue}->
							if
								RewardValue > NeedValueAcc,RewardValue =< Value->
									{RewardValue,ItemId};	
								true->
									{NeedValueAcc,ItemIdAcc}
							end
					end
				end, {0,0}, AllRewards).
%%
%%鍙戦�佹湭棰嗗彇濂栧姳
%%
send_remain_reward(Name,Level,Value,TimeStamp)->
	Exp = get_reward_exp(Level,Value),
	if
		Exp > 0->
			role_op:obtain_exp(Exp);
		true->
			nothing
	end,
	case get_adapt_reward_item(Level,Value) of
		{0,0}->
			nothing;
		{_,ItemProtoId}->
			MailTitle = language:get_string(?STR_ACTIVITY_VALUE_REWARD_TITLE),
			MailContent = language:get_string(?STR_ACTIVITY_VALUE_REWARD_CONTENT),
			MailSign = language:get_string(?STR_SYSTEM),
			gm_op:gm_send_rpc(MailSign,Name,MailTitle,MailContent,ItemProtoId,1,0)
	end.
	
	
send_remain_reward_delay(Name,Level,Value,TimeStamp)->
	erlang:send_after(1, self(),{activity_value,{send_remain_reward,{Name,Level,Value,TimeStamp}}}).
	
