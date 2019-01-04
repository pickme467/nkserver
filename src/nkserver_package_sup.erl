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

%% @doc Supervisor for the packages
-module(nkserver_package_sup).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').
-behaviour(supervisor).

-export([start_link/3, stop/1, init/1, get_pid/1, get_all/0]).


%% @doc
-spec start_link(nkserver:class(), nkserver:id(), nkserver:spec()) ->
    {ok, pid()} | {error, term()}.

start_link(PkgClass, PkgId, Opts) ->
    case get_pid(PkgId) of
        undefined ->
            case nkserver_util:get_spec(PkgId, PkgClass, Opts) of
                {ok, Spec} ->
                    case nkserver_config:config(Spec, #{}) of
                        {ok, Package} ->
                            ChildSpec = {{one_for_one, 10, 60}, get_childs(Package)},
                            supervisor:start_link(?MODULE, {PkgId, ChildSpec});
                        {error, Error} ->
                            {error, Error}
                    end;
                {error, Error} ->
                    {error, Error}
            end;
        Pid ->
            {error, {already_started, Pid}}
    end.


stop(PkgId) ->
    case get_pid(PkgId) of
        undefined ->
            {error, not_started};
        Pid ->
            sys:terminate(Pid, normal)
    end.


%% @private
get_childs(Package) ->
    [
        #{
            id => supervisor,
            type => supervisor,
            start => {nkserver_workers_sup, start_link, [Package]},
            restart => permanent,
            shutdown => 15000
        },
        #{
            id => server,
            type => worker,
            start => {nkserver_srv, start_link, [Package]},
            restart => permanent,
            shutdown => 15000
        }
    ].



%% @private
%% Shared for main supervisor and package supervisor
init({Id, ChildsSpec}) ->
    ets:new(Id, [named_table, public]),
    yes = nklib_proc:register_name({?MODULE, Id}, self()),
    nklib_proc:put(?MODULE, Id),
    {ok, ChildsSpec}.


%% @private Get pid() of master supervisor for all packages
get_pid(Pid) when is_pid(Pid) ->
    Pid;
get_pid(PkgId) ->
    nklib_proc:whereis_name({?MODULE, PkgId}).


get_all() ->
    nklib_proc:values(?MODULE).