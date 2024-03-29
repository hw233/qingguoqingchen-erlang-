%%% -------------------------------------------------------------------
%%% 9秒社团全球首次开源发布
%%% http://www.9miao.com
%%% -------------------------------------------------------------------
%%% -------------------------------------------------------------------
%%% Author  : yanzengyan
%%% Description :
%%%
%%% Created : 2012-9-5
%%% -------------------------------------------------------------------
-module(statistics_sup).

-behaviour(supervisor).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([start_link/0,start_snapshot/0]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([
	 init/1
        ]).

%% --------------------------------------------------------------------
%% Macros
%% --------------------------------------------------------------------
-define(SERVER, ?MODULE).

%% --------------------------------------------------------------------
%% Records
%% --------------------------------------------------------------------

%% ====================================================================
%% External functions
%% ====================================================================

start_link() ->
	supervisor:start_link({local,?SERVER}, ?MODULE, []).

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
    Stattool = {'stattool',{'stattool',start_link,[]},
	      permanent,2000,worker,['stattool']},
    {ok,{{one_for_all,2,60}, [Stattool]}}.

start_snapshot() ->
	Snapshot = {'snapshot',{'snapshot',start_link,[]},
	      permanent,2000,worker,['snapshot']},
	supervisor:start_child(?SERVER, Snapshot).

%% ====================================================================
%% Internal functions
%% ====================================================================

