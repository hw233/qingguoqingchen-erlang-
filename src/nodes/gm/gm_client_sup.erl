%%% -------------------------------------------------------------------
%%% 9秒社团全球首次开源发布
%%% http://www.9miao.com
%%% -------------------------------------------------------------------
%%% -------------------------------------------------------------------
%%% Author  : adrian
%%% Description :
%%%
%%% Created : 2010-4-2
%%% -------------------------------------------------------------------
-module(gm_client_sup).

-behaviour(supervisor).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([start_link/0,
	 get_client_count/0]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([
	 init/1
        ]).

%% --------------------------------------------------------------------
%% Macros
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Records
%% --------------------------------------------------------------------

get_client_count()->
	not_implement.

%% ====================================================================
%% External functions
%% ====================================================================
start_link()->
	supervisor:start_link({local, ?MODULE},?MODULE, []).

%% ====================================================================
%% Server functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Func: init/1
%% Returns: {ok,  {SupFlags,  [ChildSpec]}} |
%%          ignore                          |
%%          {error, Reason}
%% --------------------------------------------------------------------
init([]) ->
	{ok,{{simple_one_for_one,5, 60}, 
	     [{gm_client, 				%% target process noname
	       {gm_client,start_link,[]},
	       temporary, 				%% target process is temporary
	       brutal_kill,worker,[]}]}}.

%% ====================================================================
%% Internal functions
%% ====================================================================

