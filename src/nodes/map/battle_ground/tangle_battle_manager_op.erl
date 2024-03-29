%%% -------------------------------------------------------------------
%%% 9秒社团全球首次开源发布
%%% http://www.9miao.com
%%% -------------------------------------------------------------------
%% Author: Administrator
%% Created: 2011-3-8
%% Description: TODO: Add description to tangle_battle_manager_op
-module(tangle_battle_manager_op).
%%
%% Exported Functions
%%
-compile(export_all).
%%
%% Include files
%%
-include("common_define.hrl").
-include("activity_define.hrl").
-include("error_msg.hrl").

%%
%%Define
%%
-define(BATTLE_INIT,1).
-define(BATTLE_START,2).

-define(BATTLE_STATE_START,1).
-define(BATTLE_STATE_STOP,2).
-define(BATTLE_STATE_REWARD,3).
-define(BATTLE_STATE_INIT,4).

-define(MAXPLAYERSINBATTLE,150).		%%姣忎釜鎴樺満浜烘暟涓婄嚎
-define(INITBATTLETIME_S,2).		%%鍚姩鎴樺満鏃堕棿(绉�)	
-define(RECORD_SAVE_DATE,7).		%%鎴樻姤淇濆瓨鏃堕棿(澶�)

%%
%% API Functions
%%

%%
%%tangle_battle_info	
%%battle_xx_xx_info 	{waitinglist,battlelist,initbattlenum}
%%	waitinglist [roleid,...]
%%	battlelist [id,state,node,proc,mapproc,num]
%%	tangle_battle_kill_info:[{tangle_battle_kill_info,{Date,Class,Index},KillInfo}]
%%battle_start
%%
%% initbattlelist 姝ｅ湪鍒濆鍖栦腑鐨勬垬鍦哄垪琛� [{battleid,info},...]
%%

init()->
	put(tangle_battle_info,[]),
	put(tangle_battle_records,[]),
	put(battle_state,?BATTLE_STATE_STOP),
	put(battle_50_100_info,{[],[]}),
	put(tangle_battle_kill_info,[]),		%%鎴樺満瑙掕壊鍑绘潃淇℃伅
	put(tangle_battle_time,{0,0,0}).		%%璁板綍鎴樺満寮�鍚椂闂�	
	

%%
%%灏唅nit鐘舵�佷笅鐨刡attle鍒囨崲涓簊tart
%%骞跺皢鎺掗槦涓殑浜哄憳鍔犲叆鎴樺満涓�
%%
%%check_init_battle()->
%%	case get(battle_start) of
%%		true->
%%			change_init_to_start(?STARTBATTLEPRETIME),
%%			erlang:send_after(?INITBATTLETIME_S*1000,self(),{check_init_battle,?TANGLE_BATTLE});
%%		_->
%%			nothing
%%	end.	

on_check()->
	ProtoInfo = battlefield_proto_db:get_info(?TANGLE_BATTLE),
	Duration = battlefield_proto_db:get_duration(ProtoInfo),
	AnswerInfoList = answer_db:get_activity_info(?TANGLE_BATTLE_ACTIVITY),
	CheckFun = fun(AnswerInfo)->
				{Type,TimeLines} = answer_db:get_activity_start(AnswerInfo),
				case timer_util:check_is_time_line(Type,TimeLines,?BUFFER_TIME_S) of
					true->
						on_start_battle(),
						true;
					_->
						false
				end
	end,
	States = lists:map(CheckFun, AnswerInfoList),
	case lists:member(true,States) of
		true->
			nothing;
		_->
			on_stop_battle()
	end.

on_start_battle()->
	case get(battle_state) of
		?BATTLE_STATE_STOP->
			put(battle_state,?BATTLE_STATE_INIT),
			Info = battlefield_proto_db:get_info(?TANGLE_BATTLE),
			Duration = battlefield_proto_db:get_duration(Info),	
			erlang:send_after(?BUFFER_TIME_S*1000,self(),{battle_start_notify,{?TANGLE_BATTLE,Duration}}),
			erlang:send_after(Duration + ?BUFFER_TIME_S*1000,self(),{on_battle_end,?TANGLE_BATTLE}),
			put(tangle_battle_kill_info,[]),
			put(tangle_battle_records,[]);
		_->
			noting			
	end.
 
on_battle_end()->
	put(battle_state,?BATTLE_STATE_REWARD),
	case get(battle_50_100_info) of
		{[],[]}->
			nothing;
		{Battle,BattleList1}->		
			lists:foreach(fun({Id,State,Node,ProcName,MapProc,_})->
							{ProcName,Node}!{on_destroy},
							put(battle_50_100_info,{Battle,lists:keyreplace(Id,1,BattleList1,{Id,State,Node,ProcName,MapProc,0})})  
							end, BattleList1)
	end.
	
%%
%% kill all battle processor
%%
on_stop_battle()->
%%	io:format("~p on_stop_battle ~p ~n",[?MODULE,get(battle_start)]),
	case get(battle_state) of
		?BATTLE_STATE_STOP->
			nothing;
		_->
			put(battle_state,?BATTLE_STATE_STOP),
			case get(battle_50_100_info) of
				{[],[]}->
					nothing;
				{_,BattleList1}->		
					lists:foreach(fun({_,_,Node,ProcName,MapProc,_})->
							rpc:call(Node,battle_ground_sup,stop_child, [ProcName])	  
							end, BattleList1)
			end,
			init(),
			update_tangle_battle_records(),
			update_tangle_battle_kill_info()
	end.

%%
%% 鐢宠鍔犲叆鎴樺満
%%
apply_for_battle({RoleId,RoleLevel})->
	case get(battle_state) of
		?BATTLE_STATE_START->
%%			io:format("apply_for_battle ~p ~n",[RoleId]),
			BattleInfo = get_adapt_battle_ground_info(RoleLevel),
			BattleType = get_adapt_battle_ground_type(RoleLevel),
			case get(BattleInfo) of
				{[],[]}-> %% 绗竴涓汉
					%%寮�鍚竴涓垬鍦�
					{BattleId,Node,Proc,MapProc} = start_new_battle(BattleType,get_battle_index(BattleType)),
					%%鍔犲叆绛夊緟鍒楄〃
					NewWaitingList = [RoleId],
					BattleList = [{BattleId,?BATTLE_INIT,Node,Proc,MapProc,0}],
					put(BattleInfo,{NewWaitingList,BattleList});
				{[],BattleList}-> %%娌′汉鍦ㄦ帓闃�
					%%妫�鏌ユ槸鍚﹀瓨鍦ㄥ凡寮�鍚殑鎴樺満
					case find_best_battle(BattleList) of
						{start,BattleTerm}->
							{BattleId,State,Node,Proc,MapProc,Num} = BattleTerm,
							NewBattleList = [{BattleId,State,Node,Proc,MapProc,Num+1}],
							put(BattleInfo,{[],NewBattleList}),
							%% notify Header join battle
							notify_role_join_battle(RoleId,BattleId,Node,Proc,MapProc);
						{init,BattleTerm}->
							NewWaitingList = [RoleId],
							put(BattleInfo,{NewWaitingList,BattleList}),
							%% 閫氱煡瀹㈡埛绔帓闃熸垚鍔�
							notify_client_apply_success(RoleId,?INITBATTLETIME_S);
						_->
							Message = battle_ground_packet:encode_join_battle_error_s2c(?ERRNO_BATTLE_FULL),
							role_pos_util:send_to_role_client(Message)
					end;
				{WaitingList,BattleList}->		%%鏈変汉鍦ㄦ帓闃�
					WaitingNum = length(WaitingList),
					if
						WaitingNum < ?MAXPLAYERSINBATTLE ->	%% 澶熺敤
							NewWaitingList = WaitingList ++ [RoleId],
							put(BattleInfo,{NewWaitingList,BattleList}),
							%%閫氱煡瀹㈡埛绔帓闃熸垚鍔�
							notify_client_apply_success(RoleId,trunc(?INITBATTLETIME_S));
						true->	
							Message = battle_ground_packet:encode_join_battle_error_s2c(?ERRNO_BATTLE_FULL),
							role_pos_util:send_to_role_client(Message)
					end;
				Other->
					slogger:msg("~p apply_for_battle faild ~p ~n",[RoleId,Other]),
					nothing
			end;
		_->
			Msg = battle_ground_packet:encode_battlefield_info_error_s2c(?ERRNO_BATTLE_NOT_START),
			role_pos_util:send_to_role_clinet(Msg)
	end.

%%
%%鍙栨秷鐢宠鎴樺満
%%
cancel_apply_battle({RoleId,RoleLevel})->
	case get(battle_state) of
		?BATTLE_STATE_STOP->
			nothing;
		_->
			BattleInfo = get_adapt_battle_ground_info(RoleLevel),
			BattleType = get_adapt_battle_ground_type(RoleLevel),
			{WaitingList,BattleList} = get(BattleInfo),
			case lists:member(RoleId,WaitingList) of
				true->	
					NewWaitingList = lists:keydelete(RoleId,1,WaitingList),
					put(BattleInfo,{NewWaitingList,BattleList});%%@@wb20130416{WaitingList,BattleList}
				false->
					nothing
			end
	end.
%%
%%涓�旂寮�鎴樺満  鐣欎笅涓�涓┖浣�
%%
role_leave_battle({BattleType,BattleId})->
	BattleInfo = get_adapt_battle_ground_info_for_type(BattleType),
	case get(BattleInfo) of
		{[],BattleList}->
			BattleTerm = lists:keyfind(BattleId,1,BattleList),
			{_,State,Node,Proc,MapProc,Num} = BattleTerm,
			NewBattleList = [{BattleId,State,Node,Proc,MapProc,Num-1}],
			put(BattleInfo,{[],NewBattleList});
		{WaitingList,BattleList}->
			BattleTerm = lists:keyfind(BattleId,1,BattleList),
			{_,State,Node,Proc,MapProc,Num} = BattleTerm,
			[Header|Last] = WaitingList,
			%% notify Header join battle
			notify_role_join_battle(Header,BattleId,Node,Proc,MapProc),
			NewWaitingList = Last,
			put(BattleInfo,{NewWaitingList,BattleList})
	end.			

battle_start_notify(Duration)->
	put(battle_state,?BATTLE_STATE_START),
	put(tangle_battle_time,timer_center:get_correct_now()),
	Message = battle_ground_packet:encode_battle_start_s2c(?TANGLE_BATTLE,trunc(Duration/1000)),
	role_pos_util:send_to_all_online_clinet(Message).
		
	
%%start_tangle_battle(ProtoInfo,Duration)->
%%	BattleClasses = battlefield_proto_db:get_args(ProtoInfo),
%%	Nodes = get_low_load_node(erlang:length(BattleClasses)),
%%	lists:foreach(fun(N)->
%%		rpc:call(lists:nth(N,Nodes),battle_ground_sup,start_child, [tangle_battle,{N,1}])
%%	end,BattleClasses),
%%	InitInfo = lists:map(fun(N)->{N,1,lists:nth(N,Nodes),battle_ground_sup:make_battle_proc_name(tangle_battle,{N,1})} end, BattleClasses),
%%	erlang:send_after(?BUFFER_TIME_S*1000,self(),{battle_start_notify,tangle_battle,Duration}),
%%	erlang:send_after(Duration + ?BUFFER_TIME_S*1000,self(),{on_battle_end,tangle_battle}),
%%	slogger:msg("on_battle_end after ~p ~n",[Duration + ?BUFFER_TIME_S*1000]),
%%	put(tangle_battle_info,InitInfo).
	
%%
%% Local Functions
%%

%%
%%浠庡垪琛ㄤ腑鏌ユ壘涓�涓悎閫傜殑鎴樺満
%%浼樺厛鏌ユ壘宸插紑鍚垬鍦�
%%鍏跺疄鏌ユ壘姝ｅ湪鍒濆鍖栫殑鎴樺満
%%杩斿洖 {start,battleinfo}|
%%		{init,battleinfo}|
%%		{false,[]}
find_best_battle(BattleList)->
	lists:foldl(fun(BattleTerm,{Check,TempInfo})->
				case Check of
					false->
						{_,State,_,_,_,Num} = BattleTerm,
						case State of
							?BATTLE_START->
								if
									Num >= ?MAXPLAYERSINBATTLE ->
										{Check,TempInfo};
									true->
										{start,BattleTerm}
								end;
							?BATTLE_INIT->
								{init,BattleTerm};
							_->
								{Check,TempInfo}
						end;
					init->
						{_,State,_,_,_,Num} = BattleTerm,
						case State of
							?BATTLE_START->
								if
									Num >= ?MAXPLAYERSINBATTLE ->
										{Check,TempInfo};
									true->
										{start,BattleTerm}
								end;
							_->
								{Check,TempInfo}
						end;
					start->
						{Check,TempInfo}
				end
			end,{false,[]},BattleList).

%%
%% 寮�鍚竴涓柊鎴樺満
%%
start_new_battle(BattleType,BattleId)->
	%%閫夊彇鍊欓�夎妭鐐�
	Nodes = node_util:get_low_load_node(?CANDIDATE_NODES_NUM),
	%%浠庡�欓�夎妭鐐逛腑闅忔満閫夋嫨涓�涓妭鐐�
	%%閬垮厤鎵�鏈夋垬鍦洪兘鎸ゅ湪涓�涓妭鐐圭殑灏村艾
	Node = lists:nth(random:uniform(length(Nodes)),Nodes),
	rpc:call(Node,battle_ground_sup,start_child, [tangle_battle,{BattleType,BattleId}]),
	Proc = battle_ground_sup:make_battle_proc_name(tangle_battle,{BattleType,BattleId}),
	MapProc = battle_ground_processor:make_map_proc_name(Proc),
	{BattleId,Node,Proc,MapProc}.
	

get_adapt_battle_ground_info(RoleLevel)->
	if
		(RoleLevel>=50) and (RoleLevel=<100)->
			battle_50_100_info;
		true->
			nothing
	end.

get_adapt_battle_ground_info_for_type(BattleType)->
	case BattleType of
		?TANGLE_BATTLE_50_100->
			battle_50_100_info;
		_->
			nothing
	end.

get_adapt_battle_ground_type(RoleLevel)->
	if
		(RoleLevel>=50) and (RoleLevel=<100)->
			?TANGLE_BATTLE_50_100;
		true->
			0
	end.

%%
%%鏌愭垬鍦哄凡寮�鍚�
%%
notify_manager_battle_start({BattleType,BattleId})->
	BattleInfo = get_adapt_battle_ground_info_for_type(BattleType),
	{WaitingList,BattleList} = get(BattleInfo),
	BattleTerm = lists:keyfind(BattleId,1,BattleList),
	{_,_,Node,Proc,MapProc,_} = BattleTerm,
	WaitingNum = length(WaitingList),
	if
		WaitingNum > ?MAXPLAYERSINBATTLE->
			RoleList = lists:sublist(WaitingList,?MAXPLAYERSINBATTLE),
			NewWaitingList = lists:sublist(WaitingList,?MAXPLAYERSINBATTLE+1,min(?MAXPLAYERSINBATTLE,WaitingNum - ?MAXPLAYERSINBATTLE)),
			notify_new_battle_start(RoleList,BattleId,Node,Proc,MapProc),
			NewBattleList = [{BattleId,?BATTLE_START,Node,Proc,MapProc,?MAXPLAYERSINBATTLE}],
			put(BattleInfo,{NewWaitingList,NewBattleList});
		true->
			notify_new_battle_start(WaitingList,BattleId,Node,Proc,MapProc),
			NewBattleList = [{BattleId,?BATTLE_START,Node,Proc,MapProc,WaitingNum}],
			put(BattleInfo,{[],NewBattleList})
	end.

%%
%%閫氱煡瀹㈡埛绔帓闃熸垚鍔� 
%%Time_s 浼扮畻绛夊緟鏃堕棿(绉�)
%%
notify_client_apply_success(RoleId,Time_s)->
	nothing.
	

%%
%%鑾峰彇鏌愬ぉ鎴樺満淇℃伅
%%杩斿洖缁欏鎴风 鏃ュ織 鎴樺満绫诲瀷 璇ョ被鍨嬫�绘垬鍦烘暟 role浣嶄簬鍝釜鎴樺満(娌″弬鍔犱负0)
%%
get_role_battle_info({RoleId,Date,BattleType})->
	{TotalBattle,MyBattle} = lists:foldl(fun(Term,{TempTotal,TempBattleId})->
						%%io:format("Term ~p ~n",[Term]),
						{Type,{TempDate,TempType,BattleId},List,_} = Term,
						case (TempDate =:= Date) and (TempType =:= BattleType) and (Type =:= tangle_battle) of
							true->
								NewTempTotal = TempTotal + 1,	
								case tangle_battle:get_role_score(RoleId,List) of
									-1->
										NewTempBattleList = TempBattleId;
									_->
										NewTempBattleList = TempBattleId ++ [BattleId]
								end,
								{NewTempTotal,NewTempBattleList};								
							_->
								{TempTotal,TempBattleId}
						end
			end,{0,[]},get(tangle_battle_records)),
	Message = battle_ground_packet:encode_tangle_records_s2c(Date,BattleType,TotalBattle,MyBattle),
	role_pos_util:send_to_role_clinet(RoleId,Message);

%%
%%鑾峰彇鏌愬ぉ鎴樺満璇︾粏淇℃伅
%%杩斿洖鎸囧畾鎴樺満鐨勬帓鍚� 浠ュ強role鍦ㄨ鎴樺満涓殑鎺掑悕
%%RankInfos,{Year,Month,Day},Class,BattleId,Myrank
get_role_battle_info({RoleId})->
	case get(tangle_battle_records) of
		[{_,_,AllInfo,Has_Reward}] ->
			case tangle_battle:get_role_score(RoleId,AllInfo) of
				-1->
					CanReward = 0,
					MyRank = 0;
				Scroe->
					MyRank = tangle_battle:get_my_rank_by_score(Scroe,AllInfo),
					case lists:member(RoleId, Has_Reward) of
						false->
							CanReward = 1;
						_->
							CanReward = 0
					end
			end,    
			Info = lists:sublist(AllInfo, 10),
			NewInfo = lists:filter(fun({_,_,ScoreTmp,_,_})-> ScoreTmp =/= -1 end,Info),
			FullInfo = lists:map(fun({RoleIdTmp,RoleNameTmp,ScoreTmp,KillsTmp,{ClassTmp,GenderTmp,LevelTmp}})-> battle_ground_packet:make_tangle_battle_role(RoleIdTmp,RoleNameTmp,KillsTmp,ScoreTmp,GenderTmp,ClassTmp,LevelTmp) end,NewInfo),
			Message = battle_ground_packet:encode_tangle_more_records_s2c(FullInfo,MyRank,CanReward);
		_->
			Message = battle_ground_packet:encode_tangle_more_records_s2c([],0,0)
	end,
	role_pos_util:send_to_role_clinet(RoleId,Message).


%%鑾峰彇鑷繁鍦ㄦ煇澶╂垬鍦虹殑鍑绘潃鏁版嵁
get_role_battle_kill_info({RoleId,Date,BattleType,BattleId})->
	case get(tangle_battle_records) of
		[{_,_,RankInfo,Has_Reward}] ->
			case get(tangle_battle_kill_info) of
				[{_,_,AllKillInfo}] ->
					case lists:keyfind(RoleId,1,AllKillInfo) of
						false-> 
							Msg = battle_ground_packet:encode_tangle_kill_info_request_s2c(Date,BattleType,BattleId,[],[]);
						{RoleId,{KillInfo,BeKillInfo}}->
							CKillInfo = battle_ground_packet:make_ki(KillInfo,RankInfo),
							CBeKillInfo = battle_ground_packet:make_ki(BeKillInfo,RankInfo),
							Msg = battle_ground_packet:encode_tangle_kill_info_request_s2c(Date,BattleType,BattleId,CKillInfo,CBeKillInfo)
					end;
				_->
					Msg = battle_ground_packet:encode_tangle_kill_info_request_s2c(Date,BattleType,BattleId,[],[])
			end;
		_->
			Msg = battle_ground_packet:encode_tangle_kill_info_request_s2c(Date,BattleType,BattleId,[],[])
	end,
	role_pos_util:send_to_role_clinet(RoleId,Msg).


%%
%%鑾峰彇鎸囧畾鎴樺満鐨勫鍔�
%%
get_role_battle_reward(RoleId)->
	case get(tangle_battle_records) of
		[{_,{Date,BattleType,BattleId},AllInfo,Has_Reward}] ->
			case lists:member(RoleId,Has_Reward) of
				false->
					Rewards = tangle_battle:get_reward_by_rankinfo(RoleId,AllInfo),
					NewRewardRecord = Has_Reward ++ [RoleId],
					NewTerm = {tangle_battle,{Date,BattleType,BattleId},AllInfo,NewRewardRecord},
					put(tangle_battle_records,lists:keyreplace({Date,BattleType,BattleId},2,get(tangle_battle_records),NewTerm)),
					tangle_battle_db:sync_add_battle_info(Date,BattleType,BattleId,AllInfo,NewRewardRecord),
					notify_role_tangle_battle_reward(RoleId,Rewards);
				_->
					nothing
			end;
		_->
			nothing
	end.
	
get_reward_error(RoleId)->
	case get(tangle_battle_records) of
		[{_,{Date,BattleType,BattleId},AllInfo,Has_Reward}] ->
			case lists:member(RoleId,Has_Reward) of
				false->
					ignor;
				_->
					Has_Reward -- [RoleId]
			end;
		_->
			ignor
	end.

%%
%%閫氱煡role棰嗗彇濂栧姳
%%
notify_role_tangle_battle_reward(RoleId,Reward)->
	role_pos_util:send_to_role(RoleId,{battle_reward_from_manager,{?TANGLE_BATTLE,Reward}}).

notify_new_battle_start(RoleList,BattleId,Node,Proc,MapProc)->
	lists:foreach(fun(RoleId)->
				notify_role_join_battle(RoleId,BattleId,Node,Proc,MapProc)
				end,RoleList).	


notify_role_join_battle(Role,BattleId,Node,Proc,MapProc)->
	%%io:format("notify_role_join_battle ~n"),
	role_pos_util:send_to_role(Role,{battle_intive_to_join,{?TANGLE_BATTLE,BattleId,Node,Proc,MapProc}}).		
			
update_tangle_battle_records()->
	case tangle_battle_db:load_tangle_battle_info() of
		[]->
			nothing;
		Infos->
			NowDate = calendar:now_to_local_time(timer_center:get_correct_now()),
			write_tangle_to_log(NowDate,Infos),
			put(tangle_battle_records,Infos)
	end.

update_tangle_battle_kill_info()->
	case tangle_battle_db:load_tangle_battle_kill_info() of
		[]->
			noting;
		Infos->
			put(tangle_battle_kill_info,Infos)
	end.

write_tangle_to_log(NowDate,Infos)->
	{Today,_} = NowDate,
	TodayKillersList = lists:foldl(fun(Term,KillerList)->
										{Type,{Date,Battletype,BattleId},Info,Has_Reward} = Term,
										case Type of
											tangle_battle->
												if
													Date =:= Today->
														NewInfo = lists:filter(fun({_,_,ScoreTmp,_,_})-> ScoreTmp =/= -1 end,Info),
														KillsInfo = lists:map(fun({RoleIdTmp,_,_,KillsTmp,_})->{RoleIdTmp,KillsTmp} end, NewInfo),
														KillerList ++ KillsInfo;
													true->
														KillerList
												end;
											_->
												KillerList			
										end
									end,[],Infos),
	LogLists = 	lists:sublist(lists:reverse(lists:keysort(2, TodayKillersList)), 100 ),
	role_game_rank:hook_on_tangle_kill_log(LogLists),
	gm_logger_role:role_ranks_info(LogLists).

check_battle_time()->
	case get(battle_state) of
		?BATTLE_STATE_START->
			get(tangle_battle_time);
		_->
			{0,0,0}
	end.	

%%
%%鑾峰彇涓�涓悎閫傜殑鎴樺満缂栧彿
%%
get_battle_index(Type)->
	DicKey = 
		case Type of
			?TANGLE_BATTLE_50_100->
				last_index_50100;
			_->
				nothing
		end,
	{NowDate,_} = calendar:now_to_local_time(timer_center:get_correct_now()), 
	case get(DicKey) of
		undefined->
			NewIndex = 1,
			put(DicKey,{NowDate,NewIndex}),
			NewIndex;	
		{Date,Index}->
			if
				NowDate =:= Date ->
					NewIndex = Index+1,
					put(DicKey,{NowDate,NewIndex}),
					NewIndex;	
				true->
					NewIndex = 1,
					put(DicKey,{NowDate,NewIndex}),
					NewIndex
			end
	end.
	
get_tangle_battle_curenum()->
	Func = fun(BattleInfo,{BattleId,Acc})->
			case get(BattleInfo) of
				{[],[]}->
					{BattleId+1,Acc};
				{_,BattleList}->
					[{_,State,_,_,_,Num}] = BattleList,
					case State of
						?BATTLE_START->
								{BattleId+1,[{BattleId+1,Num,?MAXPLAYERSINBATTLE}|Acc]}; 
						_->
							{BattleId+1,[{BattleId+1,0,?MAXPLAYERSINBATTLE}|Acc]}
					end
			end
		end,
	lists:foldl(Func,{0,[]},[battle_50_100_info]).
	
	
			
	
	
	
	
	
	
	
	
	
	
	
	
	
