%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Copyright 2013 Klarna AB
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%
%%% @copyright 2013 Klarna AB
%%%
%%% KATT Blueprint record tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-module(katt_blueprint_record_tests).


-include_lib("eunit/include/eunit.hrl").

%%% Suite

katt_blueprint_record_test_() ->
  { setup
  , spawn
  , fun() ->
    meck:new(lhttpc),
    meck:expect( lhttpc
               , request
               , fun mock_lhttpc_request/6
               )
    end
  , fun(_) -> meck:unload(lhttpc) end
  , [ record_error(),
      record_empty(),
      record_with_headers_and_body()
    ]
  }.

%%% Tests

record_error() ->
  Expected = {error, test},
  [ ?_assertEqual(Expected,
                  katt_blueprint_record:record(
                    "http://127.0.0.1/error",
                    "GET",
                    [],
                    <<>>,
                    1))
  ].

record_empty() ->
  Expected = <<"GET http://127.0.0.1/empty\n"
               "< 204\n">>,
  [ ?_assertEqual(Expected,
                  begin
                    {ok, BP} = katt_blueprint_record:record(
                      "http://127.0.0.1/empty",
                      "GET",
                      [],
                      <<>>,
                      1),
                    iolist_to_binary(BP)
                  end)
  ].

record_with_headers_and_body() ->
  Expected = <<"POST http://127.0.0.1/headers\n"
               "> Content-Type: application/json\n"
               "> Authorization: Basic dXNlcjpwYXNzd29yZA==\n"
               "{ \"test\": true }\n"
               "< 401\n"
               "< Content-Type: application/json\n"
               "{ \"error\": \"unauthorized\" }">>,
  [ ?_assertEqual(Expected,
                  begin
                    {ok, BP} = katt_blueprint_record:record(
                      "http://127.0.0.1/headers"
                      , "POST"
                      , [ {"Content-Type", "application/json"}
                        , {"Authorization", "Basic dXNlcjpwYXNzd29yZA=="}
                        ]
                      , <<"{ \"test\": true }">>
                      , 1),
                    iolist_to_binary(BP)
                  end)
  ].

%%% Helpers

mock_lhttpc_request( "http://127.0.0.1/error"
                   , _Method
                   , _Headers
                   , _Body
                   , _Timeout
                   , _Options
                   ) ->
  {error, test};
mock_lhttpc_request( "http://127.0.0.1/empty"
                   , _Method
                   , _Headers
                   , _Body
                   , _Timeout
                   , _Options
                   ) ->
  {ok, {{204, []}, [], <<>>}};
mock_lhttpc_request( "http://127.0.0.1/headers"
                   , _method
                   , _headers
                   , _body
                   , _timeout
                   , _options
                   ) ->
  {ok, {{401, []}, [{"Content-Type", "application/json"}],
       <<"{ \"error\": \"unauthorized\" }"/utf8>>}}.
