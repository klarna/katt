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
%%% @doc API for recording blueprint files.
%%% @end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%_* Module declaration ===============================================
-module(katt_blueprint_record).

%%%_* Exports ==========================================================
%% API
-export([ record/5
        ]).

%%%_* Includes =========================================================
-include("katt.hrl").

%%%_* API ==============================================================

%% @doc Record a HTTP request and its response and output the result
%% in the KATT Blueprint format.
%% @end
-spec record(URL::string(), Method::string(), Headers::[http_header()],
             Body::binary(), Timeout::(integer() | infinity)) ->
             {ok, iolist()} | {error, _}.
record(URL, Method, Headers, Body, Timeout) ->
  Req = {URL, Method, Headers, Body},
  case make_request(URL, Method, Headers, Body, Timeout) of
    {error, _}=Error -> Error;
    {ok, Resp}       -> {ok, make_blueprint(Req, Resp)}
  end.

%%%_* Internal =========================================================

make_request(URL, Method, Headers, Body, Timeout) ->
  lhttpc:request(URL
                , Method
                , Headers
                , Body
                , Timeout
                , []
                ).

make_blueprint(Req, Resp) ->
  [make_req_blueprint(Req), make_resp_blueprint(Resp)].

make_req_blueprint({URL, Method, Headers, Body}) ->
  [ make_req_line(URL, Method)
  , make_header_lines("> ", Headers)
  , Body
  , newline_unless_empty(Body)
  ].

newline_unless_empty(<<>>) -> "";
newline_unless_empty(_)    -> "\n".

make_resp_blueprint({{Code, _}, Headers, Body}) ->
  [ make_resp_code_line(Code)
  , make_header_lines("< ", Headers),
  Body
  ].

make_req_line(URL, Method) ->
  [Method, " ", URL, "\n"].

make_resp_code_line(Code) ->
  ["< ", integer_to_list(Code), "\n"].

make_header_lines(Prefix, Headers) ->
  [ make_header_line(Prefix, H) || H <- Headers].

make_header_line(Prefix, {Header, Value}) ->
  [Prefix, Header, ": ", Value, "\n"].
