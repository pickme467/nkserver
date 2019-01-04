%% -------------------------------------------------------------------
%%
%% Copyright (c) 2018 Carlos Gonzalez Florido.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

-module(nkserver_util).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').

-export([register_package_class/2, register_package_class/3,
         get_package_class_module/1, get_package_class_meta/1]).
-export([name/1]).
-export([register_for_changes/1, notify_updated_service/1]).
-export([get_net_ticktime/0, set_net_ticktime/2]).
-export([get_spec/3]).

-include("nkserver.hrl").


%% ===================================================================
%% Types
%% ===================================================================

-type register_opts() ::
    #{
    }.



%% ===================================================================
%% Public
%% ===================================================================


%% @doc
-spec register_package_class(nkserver:package_class(), module()) ->
    ok.

register_package_class(Class, Module) ->
    register_package_class(Class, Module, #{}).


%% @doc
-spec register_package_class(nkserver:package_class(), module(), register_opts()) ->
    ok.

register_package_class(Class, Module, Opts) when is_atom(Module), is_map(Opts) ->
    nklib_types:register_type(nkserver_package_class, to_bin(Class), Module, Opts).


%% @doc
-spec get_package_class_module(nkserver:package_class()) ->
    module() | undefined.

get_package_class_module(Class) ->
    nklib_types:get_module(nkserver_package_class, to_bin(Class)).


%% @doc
-spec get_package_class_meta(nkserver:package_class()) ->
    module() | undefined.

get_package_class_meta(Class) ->
    nklib_types:get_meta(nkserver_package_class, to_bin(Class)).


%% @doc Registers a pid to receive changes in service config
-spec register_for_changes(nkserver:id()) ->
    ok.

register_for_changes(PkgId) ->
    nklib_proc:put({notify_updated_service, PkgId}).


%% @doc
-spec notify_updated_service(nkserver:id()) ->
    ok.

notify_updated_service(PkgId) ->
    lists:foreach(
        fun({_, Pid}) -> Pid ! {nkserver_updated, PkgId} end,
        nklib_proc:values({notify_updated_service, PkgId})).

%% @private
name(Name) ->
    nklib_parse:normalize(Name, #{space=>$_, allowed=>[$+, $-, $., $_]}).


%%%% @doc
%%luerl_api(SrvId, PackageId, Mod, Fun, Args, St) ->
%%    try
%%        Res = case apply(Mod, Fun, [SrvId, PackageId, Args]) of
%%            {error, Error} ->
%%                {Code, Txt} = nkserver_msg:msg(SrvId, Error),
%%                [nil, Code, Txt];
%%            Other when is_list(Other) ->
%%                Other
%%        end,
%%        {Res, St}
%%    catch
%%        Class:CError:Trace ->
%%            lager:notice("NkSERVER LUERL ~s (~s, ~s:~s(~p)) API Error ~p:~p ~p",
%%                [SrvId, PackageId, Mod, Fun, Args, Class, CError, Trace]),
%%            {[nil], St}
%%    end.


-spec get_spec(nkserver:id(), nkserver:class(), nkserver:spec()) ->
    {ok, nkserver:package()} | {error, term()}.

get_spec(PkgId, PkgClass, Opts) ->
    Opts2 = case erlang:function_exported(PkgId, config, 1) of
        true ->
            PkgId:config(Opts);
        false ->
            Opts
    end,
    Syntax = #{
        uuid => binary,
        plugins => {list, atom},
        '__allow_unknown' => true
    },
    case nklib_syntax:parse(Opts2, Syntax) of
        {ok, Opts3, _} ->
            CoreOpts = [uuid, plugins],
            Opts4 = maps:with(CoreOpts, Opts3),
            Config = maps:without(CoreOpts, Opts3),
            Spec = Opts4#{
                id => PkgId,
                class => PkgClass,
                config => Config
            },
            {ok, Spec};
        {error, Error} ->
            {error, Error}
    end.


%% @private
get_net_ticktime() ->
    rpc:multicall(net_kernel, get_net_ticktime, []).


%% @private
set_net_ticktime(Time, Period) ->
    rpc:multicall(net_kernel, set_net_ticktime, [Time, Period]).



%% @private
to_bin(Term) when is_binary(Term) -> Term;
to_bin(Term) -> nklib_util:to_binary(Term).


