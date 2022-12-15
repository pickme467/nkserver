%% -------------------------------------------------------------------
%%
%% Copyright (c) 2019 Carlos Gonzalez Florido.  All Rights Reserved.
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

%% @doc Main supervisor
%% This main supervisor, starts a single supervisor registered as
%% 'nkserver_all_srvs_sup'
%% Each started service will start a supervisor under it (see nkserver_srv_sup)

-module(nkserver_sup).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').
-behaviour(supervisor).

-export([init/1, start_link/0, start_services_sup/0]).

-include("nkserver.hrl").

%% @private
start_link() ->
    ChildsSpec = [
          #{ id => pg,
             start => {pg, start_link, []},
             restart => permanent,
             type => worker,
             modules => [pg]
           }
%%        #{
%%            id => nkserver_node,
%%            start => {nkserver_node, start_link, []}
%%        }
    ],
    supervisor:start_link({local, ?MODULE}, ?MODULE,
                            {{one_for_one, 10, 60}, ChildsSpec}).

%% @private
start_services_sup() ->
    supervisor:start_link({local, nkserver_all_srvs_sup},
                            ?MODULE, {{one_for_one, 10, 60}, []}).


%% @private
init(ChildSpecs) ->
    {ok, ChildSpecs}.
