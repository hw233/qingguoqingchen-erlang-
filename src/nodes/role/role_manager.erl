%%% -------------------------------------------------------------------
%%% 9秒社团全球首次开源发布
%%% http://www.9miao.com
%%% -------------------------------------------------------------------
%%% -------------------------------------------------------------------
%%% Author  : adrian
%%% Description :
%%%
%%% Created : 2010-4-11
%%% -------------------------------------------------------------------
-module(role_manager).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
 -define(ROLE_MANAGER,local_role_manager).
%% --------------------------------------------------------------------
%% External exports
-export([start_link/1,
	 start_one_role/4,
	 stop_role_processor/4
	]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-compile(export_all).

-include("data_struct.hrl").
-include("role_struct.hrl").
-include("map_info_struct.hrl").
-include("common_define.hrl").
-include("error_msg.hrl").

-record(state, {roles_db}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 鑷畾涔夋暟鎹粨鏋�
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% ====================================================================
%% External functions
%% ====================================================================
start_link(RoleDB)->
	gen_server:start_link({local,?ROLE_MANAGER},?MODULE,[RoleDB],[]).

init([RoleDB]) ->
	timer_center:start_at_process(),
	ets:new(role_profile, [set, public, named_table]),
	{ok, #state{roles_db=RoleDB}}.

%% ====================================================================
%% Server functions
%% ====================================================================

%% start_one_role(MapNode,MapProc,RoleId,IsAdult,Coord,GateNode,GateProc)->
%%     %%to build a new connection to db when the role starts.
%%     %%mysql_intf:new_pool(RoleId),
%%     gs_rpc:cast(MapNode, ?ROLE_MANAGER,{start_one_role,
%% 					MapProc,
%% 					RoleId,Coord,GateNode,GateProc}).

%% 鍚姩涓�涓鑹茶繘绋�:
%%     鍦板浘淇℃伅(GS_system_map_info): 瑙掕壊杩涚▼鍜屾寚瀹氬湴鍥捐繘琛岀粦瀹�
%%     瑙掕壊淇℃伅(GS_system_role_info): 鍒涘缓瑙掕壊杩涚▼闇�瑕佷簡瑙ｇ殑鍩烘湰淇℃伅
%%     缃戝叧淇℃伅(GS_system_gate_info): 灏嗚鑹茶繘绋嬪拰缃戝叧杩涚▼杩涜缁戝畾
start_one_role(GS_system_map_info, GS_system_role_info, GS_system_gate_info,OtherInfo)->
	#gs_system_role_info{role_node=Role_node} = GS_system_role_info,
	gs_rpc:cast(Role_node, ?ROLE_MANAGER, {start_one_role, {GS_system_map_info, GS_system_role_info, GS_system_gate_info,OtherInfo}}).
                
start_copy_role(GS_map_info, GS_role_info, GS_gate_info,X,Y,AllInfo)->	
	MapMgr_Node = get_node_from_mapinfo(GS_map_info),
	try
		gen_server:call({?ROLE_MANAGER,MapMgr_Node}, {start_copy_role, {GS_map_info, GS_role_info, GS_gate_info,X,Y,AllInfo}},50000)
	catch
		E:R->
			slogger:msg("start_copy_role ~p ~p  ~p ~n",[E,R,erlang:get_stacktrace()]),
			error
	end.        

stop_role_processor(RoleNode, RoleId, RolePid,Tag) when is_pid(RolePid) ->
	slogger:msg("role_manager:stop_role_processor:~p,~p,~p~n", [RoleNode, RoleId, RolePid]),
	case role_processor:stop_role_processor(RolePid,Tag,RoleId) of
		{error,Reason}->
			{error,Reason};
		_->	
			role_sup:stop_role(RoleNode, RoleId)
	end;
	
stop_role_processor(RoleNode, RoleId, RoleProc,Tag) ->
	slogger:msg("role_manager:stop_role_processor:~p,~p,~p~n", [RoleNode, RoleId, RoleProc]),
	case role_processor:stop_role_processor(RoleNode, RoleProc,Tag,RoleId) of
		{error,Reason}->
			{error,Reason};
		_->	
			role_sup:stop_role(RoleNode, RoleId)
	end.
	
%%渚涚粰role process鑷繁缁撴潫鑷繁
stop_self_process(GS_map_info,RoleNode,RoleId)->
	gs_rpc:cast(RoleNode, ?ROLE_MANAGER, {stop_role, {RoleNode,RoleId}}).
	

%% 鑾峰彇鍜岃皟鐢ㄨ�呭浜庡悓涓�Node鐨凴ole淇℃伅
get_role_info(undefined) ->
	slogger:msg("undefined role info~n");

get_role_info(RoleId) ->
	try
		Role = ets:lookup(local_roles_datatbase, RoleId),
		case Role  of
			[] ->
				undefined;
			[{_, RoleInfo}] ->
				RoleInfo
		end
	catch
		_:_->
		slogger:msg("get_role_info ets:lookup RoleId error:~p~n",[RoleId]),
		undefined
	end.

get_role_remote_info(RoleId)->
	try
		Role = ets:lookup(local_roles_datatbase, RoleId),
		case Role  of
			[] ->
				undefined;
			[{_, RoleInfo}] ->
				make_roleinfo_for_othernode(RoleInfo)
		end
	catch
		_:_->
		slogger:msg("get_role_info ets:lookup RoleId error:~p~n",[RoleId]),
		undefined
	end.
	
%%閫氳繃鑺傜偣鑾峰彇role淇℃伅
get_role_remoteinfo_by_node(Node,RoleId)->
	if
		Node =:= node()->
			get_role_remote_info(RoleId);
		true->
			try			 
				rpc:call(Node,?MODULE,get_role_remote_info,[RoleId])
			catch
				E:R-> slogger:msg("get_role_info_by_node"),undefined
			end
	end.
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 鍚戣鑺傜偣鐨凴oleManager,娉ㄥ唽Role淇℃伅
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
regist_role_info(RoleId, RoleInfo) ->
	ets:insert(local_roles_datatbase, {RoleId, RoleInfo}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 鍙嶆敞鍐岃鑹蹭俊鎭疶ODO:鏃堕棿
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
unregist_role_info(RoleId) ->
	erlang:send_after(0, ?ROLE_MANAGER, {unregist_role_info,RoleId}).
	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 澶勭悊鍚屾璋冪敤
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%{GS_map_info, GS_role_info, GS_gate_info,X,Y,AllInfo}
handle_call({start_copy_role,{_, GS_role_info,_,_,_,_}=AllCopyInfo},_From,State)->
	Role_id = get_id_from_roleinfo(GS_role_info),
	%% 妫�鏌ュ睘浜庤RoleId鐨刾rocessor鏄惁瀛樺湪
	case role_processor:whereis_role(Role_id) of
			undefined->
				nothing;
			_DeadProc->	%%鍦ㄦ湰鑺傜偣涓婂凡缁忔湁璇ヨ繘绋�,搴旇鏄兊姝昏繘绋�.鐩存帴鍏虫帀杩涚▼.
				role_sup:stop_role(node(), Role_id)
	end,
	Reply =			
	case role_sup:start_role({start_copy_role,AllCopyInfo}, Role_id) of
		{ok,_Role_pid} -> 					
			ok;
		AnyInfo ->
			slogger:msg("role_manager:handle_info:start_copy_role:error:~p~n",[AnyInfo]),
			error		    
	end,
	{reply, Reply, State};

handle_call(Request, From, State) ->
	Reply = ok,
	{reply, Reply, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 澶勭悊寮傛璋冪敤
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
handle_cast({regist_role_info, {Pid, RoleInfo}}, State) ->
	put(Pid, RoleInfo),	
	{noreply, State};

handle_cast(Msg, State) ->
	{noreply, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 澶勭悊娑堟伅
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
handle_info({unregist_role_info,RoleId},State)->
	slogger:msg("role_manager:unregist_role_info:~p~n",[RoleId]),
	ets:delete(local_roles_datatbase, RoleId),
	{noreply, State};

%%GS_system_map_info, GS_system_role_info, GS_system_gate_info,OtherInfo
handle_info({start_one_role, {_, GS_system_role_info, GS_system_gate_info,_} = StartInfo},State)->
	%% 鎻愬彇鎵�闇�淇℃伅
	#gs_system_gate_info{gate_proc=Gate_proc}         = GS_system_gate_info,
	#gs_system_role_info{role_id=Role_id}                                  = GS_system_role_info,
	%%妫�鏌ュ笎鍙锋槸鍚﹁灏佺
	case gm_block_db:get_block_info(Role_id,login) of
		[]->
			BlockTime = -1;
		BlockInfo->
			StartTime = gm_block_db:get_start_time(BlockInfo),
			DurationTime = gm_block_db:get_duration_time(BlockInfo),
			LeftTime = erlang:trunc(DurationTime - (timer:now_diff(timer_center:get_correct_now(),StartTime) )/(1000*1000)),
			if
				DurationTime =:= 0->
					BlockTime = 0;
				LeftTime <0->
					BlockTime = -1,
					gm_block_db:delete_user(Role_id,login);
				true->
					BlockTime = LeftTime
			end
	end,				 
	if
		BlockTime =:= -1->											
			case role_processor:whereis_role(Role_id) of
				undefined->
					nothing;
				_DeadProc->	%%鍦ㄦ湰鑺傜偣涓婂凡缁忔湁璇ヨ繘绋�,搴旇鏄兊姝昏繘绋�.鐩存帴鍏虫帀杩涚▼.
					slogger:msg("start_one_role but has a processor,stop it ~n"),
					role_sup:stop_role(node(), Role_id)
			end,					
			case role_sup:start_role({start_one_role,StartInfo}, Role_id) of
				{ok,_Role_pid} ->
					ok;
				AnyInfo ->
					Message = role_packet:encode_map_change_failed_s2c(?ERRNO_JOIN_MAP_ERROR_UNKNOWN),
					tcp_client:send_data(Gate_proc, Message),											
					slogger:msg("role_manager:handle_info:start_one_role:error:~p~n",[AnyInfo])		    
			end;
		true->	%%鍙戦�佽鑹插皝绂�			
			Message = role_packet:encode_block_s2c(?GM_BLOCK_TYPE_LOGIN,BlockTime),
			tcp_client:send_data(Gate_proc, Message)
	end,	
	{noreply, State};
	
handle_info({stop_role, {RoleNode,RoleId}},#state{roles_db = Role_db} = State)-> 	
	role_sup:stop_role(RoleNode, RoleId),	
	{noreply, State};
	
handle_info(Info, State) ->
	{noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, State) ->
	ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(OldVsn, State, Extra) ->
	{ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
