%%% -------------------------------------------------------------------
%%% 9秒社团全球首次开源发布
%%% http://www.9miao.com
%%% -------------------------------------------------------------------
%%% -------------------------------------------------------------------
%%% Author  : PCWS06
%%% Description :
%%%
%%% Created : 2010-7-8
%%% -------------------------------------------------------------------
-module(chat_process_sup).

-behaviour(supervisor).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([start/1]).

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

%% ====================================================================
%% Server functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Func: start/1
%% --------------------------------------------------------------------
start(Args) ->
	slogger:msg("chat_process_sup start~p~n",[Args]),
    supervisor:start_link({local,?MODULE},?MODULE, Args).

%% ====================================================================
%% Server functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Func: init/1
%% Returns: {ok,  {SupFlags,  [ChildSpec]}} |
%%          ignore                          |
%%          {error, Reason}
%% --------------------------------------------------------------------
init(Args) ->
    AChild = {chat_process,{chat_process,start_link,[Args]},
	      permanent,2000,worker,[chat_process]},
    {ok,{{simple_one_for_one ,10,10}, [AChild]}}.

%% ====================================================================
%% Internal functions
%% ====================================================================

