%%% -------------------------------------------------------------------
%%% 9秒社团全球首次开源发布
%%% http://www.9miao.com
%%% -------------------------------------------------------------------
%%
%% Autogenerated by Thrift
%%
%% DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING
%%

-module(scribe_thrift).
-behaviour(thrift_service).


-include("scribe_thrift.hrl").

-export([struct_info/1, function_info/2]).

struct_info('i am a dummy struct') -> undefined.
%%% interface
% Log(This, Messages)
function_info('Log', params_type) ->
  {struct, [{1, {list, {struct, {'scribe_types', 'logEntry'}}}}]}
;
function_info('Log', reply_type) ->
  i32;
function_info('Log', exceptions) ->
  {struct, []}
;
function_info(Function, InfoType) ->
  facebookService_thrift:function_info(Function, InfoType).

