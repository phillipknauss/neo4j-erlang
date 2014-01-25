%%%-------------------------------------------------------------------
%%% @doc This is a very thin wrapper Neo4j REST API
%%%
%%%      Documentation: http://docs.neo4j.org/chunked/stable/rest-api.html
%%%
%%% @author Dmitrii Dimandt
%%% @copyright (C) 2013 Dmitrii Dimandt
%%%-------------------------------------------------------------------
-module(neo4j).
-author("dmitrii.dimandt").


%%_* Exports ===================================================================
-export([
        %% General
          connect/1
        , get_relationship_types/1
        , get_nodes_by_label/2
        , get_nodes_by_label/3
        , get_labels/1
        , get_properties/1
        %% Transactions
        , transaction_begin/2
        , transaction_execute/2
        , transaction_commit/1
        , transaction_commit/2
        , transaction_execute_commit/2
        , transaction_rollback/1
        %% Cypher
        %, cypher/2
        %, cypher/3
        %% Nodes
        , create_node/1
        , create_node/2
        , get_node/2
        , delete_node/1
        , get_node_properties/1
        , set_node_properties/2
        , get_node_property/2
        , set_node_property/3
        , delete_node_properties/1
        , delete_node_property/2
        , get_relationships/2
        , get_typed_relationships/2
        , get_typed_relationships/3
        , add_node_labels/2
        , set_node_labels/2
        , delete_node_label/2
        , get_node_labels/1
        %% Relationships
        , get_relationship/2
        , create_relationship/3
        , create_relationship/4
        , delete_relationship/1
        , get_relationship_properties/1
        , set_relationship_properties/2
        , get_relationship_property/2
        , set_relationship_property/3
        , delete_relationship_properties/1
        , delete_relationship_property/2
        %% Indices
        , create_index/3
        , list_indexes/2
        , drop_index/3
        %% Constraints
        , create_constraint/3
        , get_constraint/3
        , get_uniqueness_constraints/2
        , get_label_constraints/2
        , get_constraints/1
        , drop_constraint/3
        %% Traverse
        , traverse/2
        , traverse/3
        %% Paged traverse
        , paged_traverse/1
        , paged_traverse/2
        , paged_traverse/3
        %% Graph algorithms
        , path/4
        , paths/4
        , graph_algorithm/5
        %% Batch operations
        , batch/2
        %% Legacy node indices
        , create_node_index/2
        , create_node_index/3
        , delete_node_index/2
        , node_indices/1
        , add_node_to_index/5
        , add_node_to_index/6
        , remove_from_node_index/3
        , remove_from_node_index/4
        , remove_from_node_index/5
        , find_node_exact/4
        , find_node_query/3
        , find_node_query/4
        %% Legacy relationship indices
        , create_relationship_index/2
        , create_relationship_index/3
        , delete_relationship_index/2
        , relationship_indices/1
        , add_relationship_to_index/5
        , add_relationship_to_index/6
        , remove_from_relationship_index/3
        , remove_from_relationship_index/4
        , remove_from_relationship_index/5
        , find_relationship_exact/4
        , find_relationship_query/3
        , find_relationship_query/4
        %% Uniqueness (legacy)
        , unique_create_node/6
        , unique_create_relationship/8
        %% Legacy automatic indices
        , find_node_auto_exact/3
        , find_node_auto_query/2
        , find_relationship_auto_exact/3
        , find_relationship_auto_query/2
        , create_node_auto_index/2
        , create_relationship_auto_index/2
        , get_node_auto_index_status/1
        , get_relationship_auto_index_status/1
        , set_node_auto_index_status/2
        , set_relationship_auto_index_status/2
        , get_node_auto_index_properties/1
        , get_relationship_auto_index_properties/1
        , add_node_auto_index_property/2
        , add_relationship_auto_index_property/2
        , remove_node_auto_index_property/2
        , remove_relationship_auto_index_property/2
        ]).

%%_* Defines ===================================================================

-type neo4j_root() :: proplists:proplist().
-type neo4j_node() :: proplists:proplist().
-type neo4j_relationship() :: proplists:proplist().
%-type cypher_result() :: proplists:proplist().
-type neo4j_id() :: proplists:proplist().
-type neo4j_index() :: proplists:proplist().
-type neo4j_transaction() :: proplists:proplist().
-type neo4j_transaction_query() :: [ Query::binary()
                                   | {Query::binary(), Parameters::binary()}
                                   | {Query :: binary(), Parameters :: binary(), DataFormats::[binary()]}
                                   ].

-type neo4j_type() :: proplists:proplist().


%%_* API =======================================================================

%%_* General -------------------------------------------------------------------

-spec connect(proplists:proplist()) -> neo4j_root() | {error, base_uri_not_specified}.
connect([]) ->
  {error, base_uri_not_specified};
connect(Options) ->
  _ = start_app(hackney),
  case lists:keyfind(base_uri, 1, Options) of
    {_, BaseURI} -> get_root(BaseURI);
    _            -> {error, base_uri_not_specified}
  end.


%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-relationship-types.html
%%
-spec get_relationship_types(neo4j_root()) -> [binary()] | {error, term()}.
get_relationship_types(Neo) ->
  {_, URI} = lists:keyfind(<<"relationship_types">>, 1, Neo),
  retrieve(URI).

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-node-labels.html#rest-api-get-all-nodes-with-a-label
%%
-spec get_nodes_by_label(neo4j_root(), binary()) -> [neo4j_node()] | {error, term()}.
get_nodes_by_label(Neo, Label) ->
  {_, URI} = lists:keyfind(<<"label">>, 1, Neo),
  retrieve(<<URI/binary, "/", Label/binary, "/nodes">>).

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-node-labels.html#rest-api-get-nodes-by-label-and-property
%%
-spec get_nodes_by_label(neo4j_root(), binary(), proplists:proplist()) -> [neo4j_node()] | {error, term()}.
get_nodes_by_label(Neo, Label, Properties) ->
  {_, URI} = lists:keyfind(<<"label">>, 1, Neo),
  Props = encode_query_string(Properties),
  retrieve(<<URI/binary, "/", Label/binary, "/nodes", "?", Props/binary>>).


%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-node-labels.html#rest-api-list-all-labels
%%
-spec get_labels(neo4j_root()) -> [binary()] | {error, term()}.
get_labels(Neo) ->
  {_, URI} = lists:keyfind(<<"labels">>, 1, Neo),
  retrieve(URI).

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-property-values.html#rest-api-list-all-property-keys
%%
-spec get_properties(neo4j_root()) -> [binary()] | {error, term()}.
get_properties(Neo) ->
  {_, URI} = lists:keyfind(<<"base_uri">>, 1, Neo),
  retrieve(<<URI/binary, "propertykeys">>).


%%_* Transactions --------------------------------------------------------------

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-transactional.html#rest-api-begin-a-transaction
%%      http://docs.neo4j.org/chunked/stable/rest-api-transactional.html#rest-api-execute-statements-in-an-open-transaction-in-rest-format-for-the-return
%%      http://docs.neo4j.org/chunked/stable/rest-api-transactional.html#rest-api-return-results-in-graph-format
%%
%%      Neo = neo4j:connect([{base_uri, BaseUri}]),
%%      neo4j:transaction_begin( Neo
%%                             , [ { <<"CREATE (n {props}) RETURN n">>
%%                                 , [{<<"props">>, <<"My Node">>}]
%%                                 , [<<"REST>>"] %% optional parameter for data format
%%                                 }
%%                               ]
%%                             )...
%%
-spec transaction_begin(neo4j_root(), neo4j_transaction_query()) -> proplists:proplist() | {error, term()}.
transaction_begin(Neo, Query) ->
  {_, URI} = lists:keyfind(<<"transaction">>, 1, Neo),
  Payload = encode_transaction_query(Query),
  create(URI, Payload).

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-transactional.html#rest-api-execute-statements-in-an-open-transaction
%%      http://docs.neo4j.org/chunked/stable/rest-api-transactional.html#rest-api-execute-statements-in-an-open-transaction-in-rest-format-for-the-return
%%      http://docs.neo4j.org/chunked/stable/rest-api-transactional.html#rest-api-return-results-in-graph-format
%%
%%      Neo = neo4j:connect([{base_uri, BaseUri}]),
%%      T = neo4j:transaction_begin( Neo
%%                                 , [ { <<"CREATE (n {props}) RETURN n">>
%%                                     , [{<<"props">>, <<"My Node">>}]
%%                                     , [<<"REST>>"] %% optional parameter for data format
%%                                     }
%%                                   ]
%%                                 , [<<"REST>>"] %% optional parameter for data format
%%                                 ),
%%      T1 = neo4j:transaction_execute(T, Query)...
%%
%%
%%      http://docs.neo4j.org/chunked/stable/rest-api-transactional.html#rest-api-reset-transaction-timeout-of-an-open-transaction
%%
%%      To reset transaction timeout, send in an emtpy query:
%%
%%      neo4j:transaction_execute(T1, <<"">>).
%%
-spec transaction_execute(neo4j_transaction(), neo4j_transaction_query()) -> proplists:proplist() | {error, term()}.
transaction_execute(T, Query) ->
  {_, URI0} = lists:keyfind(<<"commit">>, 1, T),
  URI = binary:part(URI0, {0, byte_size(URI0) - 7}),
  Payload = encode_transaction_query(Query),
  create(URI, Payload).

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-transactional.html#rest-api-commit-an-open-transaction
%%      http://docs.neo4j.org/chunked/stable/rest-api-transactional.html#rest-api-execute-statements-in-an-open-transaction-in-rest-format-for-the-return
%%      http://docs.neo4j.org/chunked/stable/rest-api-transactional.html#rest-api-return-results-in-graph-format
%%
-spec transaction_commit(neo4j_transaction()) -> proplists:proplist() | {error, term()}.
transaction_commit(T) ->
  {_, URI} = lists:keyfind(<<"commit">>, 1, T),
  create(URI).

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-transactional.html#rest-api-commit-an-open-transaction
%%      http://docs.neo4j.org/chunked/stable/rest-api-transactional.html#rest-api-execute-statements-in-an-open-transaction-in-rest-format-for-the-return
%%      http://docs.neo4j.org/chunked/stable/rest-api-transactional.html#rest-api-return-results-in-graph-format
%%
-spec transaction_commit(neo4j_transaction(), neo4j_transaction_query()) -> proplists:proplist() | {error, term()}.
transaction_commit(T, Query) ->
  {_, URI} = lists:keyfind(<<"commit">>, 1, T),
  Payload = encode_transaction_query(Query),
  create(URI, Payload).

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-transactional.html#rest-api-rollback-an-open-transaction
%%
-spec transaction_rollback(neo4j_transaction()) -> proplists:proplist() | {error, term()}.
transaction_rollback(T) ->
  {_, URI0} = lists:keyfind(<<"commit">>, 1, T),
  URI = binary:part(URI0, {0, byte_size(URI0) - 7}),
  delete(URI).

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-transactional.html#rest-api-begin-and-commit-a-transaction-in-one-request
%%      http://docs.neo4j.org/chunked/stable/rest-api-transactional.html#rest-api-execute-statements-in-an-open-transaction-in-rest-format-for-the-return
%%      http://docs.neo4j.org/chunked/stable/rest-api-transactional.html#rest-api-return-results-in-graph-format
%%
%%      Neo = neo4j:connect([{base_uri, BaseUri}]),
%%      neo4j:transaction_execute_commit( Neo
%%                                      , [ { <<"CREATE (n {props}) RETURN n">>
%%                                          , [{<<"props">>, <<"My Node">>}]
%%                                          , [<<"REST>>"] %% optional parameter for data format
%%                                          }
%%                                        ]
%%                                      )...
%%
-spec transaction_execute_commit(neo4j_root(), neo4j_transaction_query()) -> proplists:proplist() | {error, term()}.
transaction_execute_commit(Neo, Query) ->
  {_, URI} = lists:keyfind(<<"transaction">>, 1, Neo),
  Payload = encode_transaction_query(Query),
  create(<<URI/binary, "/commit">>, Payload).

%%_* Cypher --------------------------------------------------------------------

%%
%% http://docs.neo4j.org/chunked/stable/rest-api-cypher.html#rest-api-send-a-query
%%
%-spec cypher(neo4j_root(), binary()) -> cypher_result().
%cypher(Neo, Query) ->
%  cypher(Neo, Query, [{<<>>, <<>>}]).

%%
%% http://docs.neo4j.org/chunked/stable/rest-api-cypher.html#rest-api-send-queries-with-parameters
%%
%-spec cypher(neo4j_root(), binary(), proplists:proplist()) -> cypher_result() | {error, term()}.
%cypher(Neo, Query, Params) ->
%  {_, URI} = lists:keyfind(<<"cypher">>, 1, Neo),
%	Payload = jsonx:encode([{query, Query}, {params, Params}]),
%  create(URI, Payload).

%%_* Nodes ---------------------------------------------------------------------

%%
%% http://docs.neo4j.org/chunked/stable/rest-api-nodes.html#rest-api-create-node
%%
-spec create_node(neo4j_root()) -> neo4j_node() | {error, term()}.
create_node(Neo) ->
  {_, URI} = lists:keyfind(<<"node">>, 1, Neo),
  create(URI).

%%
%% http://docs.neo4j.org/chunked/stable/rest-api-nodes.html#rest-api-create-node-with-properties
%%
-spec create_node(neo4j_root(), proplists:proplist()) -> neo4j_node() | {error, term()}.
create_node(Neo, Props) ->
  {_, URI} = lists:keyfind(<<"node">>, 1, Neo),
  Payload = jsonx:encode(Props),
  create(URI, Payload).

%%
%% http://docs.neo4j.org/chunked/stable/rest-api-nodes.html#rest-api-get-node
%%
-spec get_node( neo4j_root()
              , neo4j_id()
              ) -> neo4j_node() | {error, term()}.
get_node(_Neo, [{_,_}|_] = Node) ->
  Node;
get_node(Neo, Id) when is_binary(Id) ->
  case is_uri(Id) of
    true  ->
      retrieve(Id);
    false ->
      {_, URI} = lists:keyfind(<<"node">>, 1, Neo),
      retrieve(<<URI/binary, "/", Id/binary>>)
  end;
get_node(Neo, Id0) ->
  case id_to_binary(Id0) of
    {error, Reason} -> {error, Reason};
    Id              -> get_node(Neo, Id)
  end.

%%
%% http://docs.neo4j.org/chunked/stable/rest-api-nodes.html#rest-api-delete-node
%%
-spec delete_node(neo4j_node()) -> ok | {error, term()}.
delete_node(Node) ->
  {_, URI} = lists:keyfind(<<"self">>, 1, Node),
  delete(URI).

%%
%% http://docs.neo4j.org/chunked/stable/rest-api-node-properties.html#rest-api-get-properties-for-node
%%
-spec get_node_properties(neo4j_node() | neo4j_id()) -> proplists:proplist() | {error, term()}.
get_node_properties(Node) ->
  {_, URI} = lists:keyfind(<<"properties">>, 1, Node),
  retrieve(URI).

%%
%% http://docs.neo4j.org/chunked/stable/rest-api-node-properties.html#rest-api-update-node-properties
%%
-spec set_node_properties( neo4j_node()
                         , proplist:proplist()) -> ok | {error, term()}.
set_node_properties(Node, Props) ->
  {_, URI} = lists:keyfind(<<"properties">>, 1, Node),
  update(URI, jsonx:encode(Props)).

%%
%% http://docs.neo4j.org/chunked/stable/rest-api-node-properties.html
%%
-spec get_node_property(neo4j_node(), binary()) -> term() | {error, term()}.
get_node_property(Node, Prop) when is_binary(Prop) ->
  {_, URI} = lists:keyfind(<<"property">>, 1, Node),
  retrieve(replace_param(URI, <<"key">>, Prop));
get_node_property(_, _) ->
  {error, invalid_property}.

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-node-properties.html#rest-api-set-property-on-node
%%
-spec set_node_property( neo4j_node()
                       , binary()
                       , term()
                       ) -> ok | {error, term()}.
set_node_property(Node, Prop, Val) when is_binary(Prop) ->
  {_, URI} = lists:keyfind(<<"properties">>, 1, Node),
  Payload = jsonx:encode(Val),
  update(<<URI/binary, "/", Prop/binary, "/">>, Payload);
set_node_property(_, _, _) ->
  {error, invalid_property}.

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-node-properties.html#rest-api-delete-all-properties-from-node
%%
-spec delete_node_properties(neo4j_node()) -> ok | {error, term()}.
delete_node_properties(Node) ->
  {_, URI} = lists:keyfind(<<"properties">>, 1, Node),
  delete(URI).


%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-node-properties.html#rest-api-delete-a-named-property-from-a-node
%%
-spec delete_node_property(neo4j_node(), binary()) -> ok | {error, term()}.
delete_node_property(Node, Prop) when is_binary(Prop) ->
  {_, URI} = lists:keyfind(<<"properties">>, 1, Node),
  delete(<<URI/binary, "/", Prop/binary>>);
delete_node_property(_, _) ->
  {error, invalid_property}.

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-relationships.html#rest-api-get-all-relationships
%%
-spec get_relationships( neo4j_node()
                       , all | in | out
                       ) -> [neo4j_relationship()] | {error, term()}.
get_relationships(Node, Direction) ->
    get_relationship_by_direction(Node, Direction).

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-relationships.html#rest-api-get-all-relationships
%%
-spec get_typed_relationships( neo4j_node()
                             , binary()
                             ) -> [neo4j_relationship()] | {error, term()}.
get_typed_relationships(Node, Type) ->
  get_relationship_by_type(Node, Type).

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-relationships.html#rest-api-get-typed-relationships
%%
-spec get_typed_relationships( neo4j_node()
                             , binary()
                             , all | in | out
                             ) -> [neo4j_relationship()] | {error, term()}.
get_typed_relationships(Node, Type, Direction) ->
  get_relationship_by_type(Node, Type, Direction).

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-node-labels.html#rest-api-adding-a-label-to-a-node
%%      http://docs.neo4j.org/chunked/stable/rest-api-node-labels.html#rest-api-adding-multiple-labels-to-a-node
%%
-spec add_node_labels( neo4j_node()
                     , binary() | [binary()]
                     ) -> ok | {error, term()}.
add_node_labels(Node, Labels) ->
  {_, URI} = lists:keyfind(<<"labels">>, 1, Node),
  create(URI, jsonx:encode(Labels)).

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-node-labels.html#rest-api-replacing-labels-on-a-node
%%
-spec set_node_labels( neo4j_node()
                     , binary() | [binary()]
                     ) -> ok | {error, term()}.
set_node_labels(Node, Labels) ->
  {_, URI} = lists:keyfind(<<"labels">>, 1, Node),
  update(URI, jsonx:encode(Labels)).

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-node-labels.html#rest-api-removing-a-label-from-a-node
%%
-spec delete_node_label( neo4j_node()
                       , binary()
                       ) -> ok | {error, term()}.
delete_node_label(Node, Label) ->
  {_, URI} = lists:keyfind(<<"labels">>, 1, Node),
  delete(<<URI/binary, "/", Label/binary>>).

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-node-labels.html#rest-api-listing-labels-for-a-node
%%
-spec get_node_labels(neo4j_node()) -> ok | {error, term()}.
get_node_labels(Node) ->
  {_, URI} = lists:keyfind(<<"labels">>, 1, Node),
  retrieve(URI).

%%_* Relationships--------------------------------------------------------------

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-relationships.html#rest-api-get-typed-relationships
%%
-spec get_relationship(neo4j_root(), neo4j_id() | neo4j_relationship()) -> neo4j_relationship() | {error, term()}.
get_relationship(_Neo, [{_,_}|_] = Relationship) ->
  Relationship;
get_relationship(Neo, Id) when is_binary(Id) ->
  case is_uri(Id) of
    true -> retrieve(Id);
    false ->
      {_, URI} = lists:keyfind(<<"relationship">>, 1, Neo),
      retrieve(<<URI/binary, "/", Id/binary>>)
  end;
get_relationship(Neo, Id0) ->
  case id_to_binary(Id0) of
    {error, Reason} -> {error, Reason};
    Id              -> get_relationship(Neo, Id)
  end.

%%
%% http://docs.neo4j.org/chunked/stable/rest-api-relationships.html#rest-api-create-relationship
%%
-spec create_relationship( neo4j_node()
                         , neo4j_node()
                         , binary()
                         ) -> neo4j_relationship().
create_relationship(FromNode, ToNode, Type) ->
  {_, CreateURI} = lists:keyfind(<<"create_relationship">>, 1, FromNode),
  {_, ToURI} = lists:keyfind(<<"self">>, 1, ToNode),
  Payload = jsonx:encode([ {<<"to">>, ToURI}
                         , {<<"type">>, Type}
                         ]),
  create(CreateURI, Payload).

%%
%% http://docs.neo4j.org/chunked/stable/rest-api-relationships.html#rest-api-create-a-relationship-with-properties
%%
-spec create_relationship( neo4j_node()
                         , neo4j_node()
                         , binary()
                         , proplists:proplist()
                         ) -> neo4j_relationship().
create_relationship(FromNode, ToNode, Type, Props) ->
  {_, CreateURI} = lists:keyfind(<<"create_relationship">>, 1, FromNode),
  {_, ToURI} = lists:keyfind(<<"self">>, 1, ToNode),
  Payload = jsonx:encode([ {<<"to">>, ToURI}
                         , {<<"type">>, Type}
                         , {<<"data">>, Props}
                         ]),
  create(CreateURI, Payload).

%%
%% http://docs.neo4j.org/chunked/stable/rest-api-nodes.html#rest-api-delete-node
%%
-spec delete_relationship(neo4j_relationship()) -> ok | {error, term()}.
delete_relationship(Relationship) ->
  {_, URI} = lists:keyfind(<<"self">>, 1, Relationship),
  delete(URI).

%%
%% http://docs.neo4j.org/chunked/stable/rest-api-relationships.html#rest-api-get-all-properties-on-a-relationship
%%
-spec get_relationship_properties(neo4j_relationship() | neo4j_id()) -> proplists:proplist() | {error, term()}.
get_relationship_properties(Relationship) ->
  {_, URI} = lists:keyfind(<<"properties">>, 1, Relationship),
  retrieve(URI).

%%
%% http://docs.neo4j.org/chunked/stable/rest-api-relationships.html#rest-api-set-all-properties-on-a-relationship
%%
-spec set_relationship_properties( neo4j_relationship()
                                 , proplist:proplist()) -> ok | {error, term()}.
set_relationship_properties(Relationship, Props) ->
  {_, URI} = lists:keyfind(<<"properties">>, 1, Relationship),
  update(URI, jsonx:encode(Props)).

%%
%% http://docs.neo4j.org/chunked/stable/rest-api-relationships.html#rest-api-get-all-properties-on-a-relationship
%%
-spec get_relationship_property( neo4j_relationship()
                               , binary()
                               ) -> proplists:proplist() | {error, term()}.
get_relationship_property(Relationship, Prop) when is_binary(Prop) ->
  {_, URI} = lists:keyfind(<<"property">>, 1, Relationship),
  retrieve(replace_param(URI, <<"key">>, Prop));
get_relationship_property(_, _) ->
  {error, invalid_property}.

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-relationships.html#rest-api-set-single-property-on-a-relationship
%%
-spec set_relationship_property( neo4j_relationship()
                               , binary()
                               , term()
                               ) -> ok | {error, term()}.
set_relationship_property(Relationship, Prop, Val) when is_binary(Prop) ->
      {_, URI} = lists:keyfind(<<"properties">>, 1, Relationship),
      Payload = jsonx:encode(Val),
      update(<<URI/binary, "/", Prop/binary, "/">>, Payload);
set_relationship_property(_, _, _) ->
  {error, invalid_property}.

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-relationship-properties.html#rest-api-remove-properties-from-a-relationship
%%
-spec delete_relationship_properties(neo4j_relationship()) -> ok | {error, term()}.
delete_relationship_properties(Relationship) ->
  {_, URI} = lists:keyfind(<<"properties">>, 1, Relationship),
  delete(URI).

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-relationship-properties.html#rest-api-remove-property-from-a-relationship
%%
-spec delete_relationship_property(neo4j_relationship()
                                  , binary()
                                  ) -> ok | {error, term()}.
delete_relationship_property(Relationship, Prop) when is_binary(Prop) ->
  {_, URI} = lists:keyfind(<<"properties">>, 1, Relationship),
  delete(<<URI/binary, "/", Prop/binary>>);
delete_relationship_property(_, _) ->
  {error, invalid_property}.

%%_* Indices -------------------------------------------------------------------

%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-schema-indexes.html#rest-api-create-index
%%
-spec create_index(neo4j_root(), binary(), [binary()]) -> propliststs:proplist() | {error, term()}.
create_index(Neo, Label, PropKeys) ->
  {_, URI} = lists:keyfind(<<"index">>, 1, Neo),
  Payload = jsonx:encode([{<<"property_keys">>, PropKeys}]),
  create(<<URI/binary, "/", Label/binary>>, Payload).

%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-schema-indexes.html#rest-api-drop-index
%%
-spec drop_index(neo4j_root(), binary(), binary()) -> propliststs:proplist() | {error, term()}.
drop_index(Neo, Label, Key) ->
  {_, URI} = lists:keyfind(<<"index">>, 1, Neo),
  delete(<<URI/binary, "/", Label/binary, "/", Key/binary>>).

%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-schema-indexes.html#rest-api-list-indexes-for-a-label
%%
-spec list_indexes(neo4j_root(), binary()) -> propliststs:proplist() | {error, term()}.
list_indexes(Neo, Label) ->
  {_, URI} = lists:keyfind(<<"index">>, 1, Neo),
  retrieve(<<URI/binary, "/", Label/binary>>).

%%_* Consraints ----------------------------------------------------------------

%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-schema-constraints.html#rest-api-create-uniqueness-constraint
%%
-spec create_constraint(neo4j_root(), binary(), [binary()]) -> propliststs:proplist() | {error, term()}.
create_constraint(Neo, Label, PropKeys) ->
  {_, URI} = lists:keyfind(<<"constraint">>, 1, Neo),
  Payload = jsonx:encode([{<<"property_keys">>, PropKeys}]),
  create(<<URI/binary, "/", Label/binary, "/uniqueness">>, Payload).

%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-schema-constraints.html#rest-api-get-a-specific-uniqueness-constraint
%%
-spec get_constraint(neo4j_root(), binary(), [binary()]) -> propliststs:proplist() | {error, term()}.
get_constraint(Neo, Label, PropKey) ->
  {_, URI} = lists:keyfind(<<"constraint">>, 1, Neo),
  retrieve(<<URI/binary, "/", Label/binary, "/uniqueness/", PropKey/binary>>).


%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-schema-constraints.html#rest-api-get-all-uniqueness-constraints-for-a-label
%%
-spec get_uniqueness_constraints(neo4j_root(), binary()) -> propliststs:proplist() | {error, term()}.
get_uniqueness_constraints(Neo, Label) ->
  {_, URI} = lists:keyfind(<<"constraint">>, 1, Neo),
  retrieve(<<URI/binary, "/", Label/binary, "/uniqueness">>).


%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-schema-constraints.html#rest-api-get-all-constraints-for-a-label
%%
-spec get_label_constraints(neo4j_root(), binary()) -> propliststs:proplist() | {error, term()}.
get_label_constraints(Neo, Label) ->
  {_, URI} = lists:keyfind(<<"constraint">>, 1, Neo),
  retrieve(<<URI/binary, "/", Label/binary>>).


%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-schema-constraints.html#rest-api-get-all-constraints
%%
-spec get_constraints(neo4j_root()) -> propliststs:proplist() | {error, term()}.
get_constraints(Neo) ->
  {_, URI} = lists:keyfind(<<"constraint">>, 1, Neo),
  retrieve(URI).


%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-schema-constraints.html#rest-api-drop-constraint
%%
-spec drop_constraint(neo4j_root(), binary(), [binary()]) -> propliststs:proplist() | {error, term()}.
drop_constraint(Neo, Label, PropKey) ->
  {_, URI} = lists:keyfind(<<"constraint">>, 1, Neo),
  delete(<<URI/binary, "/", Label/binary, "/uniqueness/", PropKey/binary>>).


%%_* Traverse ------------------------------------------------------------------

%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-traverse.html
%%
%%      Note: you'll have to construct your request body manually, e.g:
%%
%%      Neo = neo4j:connect([{base_uri, BaseUri}]),
%%      Node = neo4j:get_node(Neo, 101),
%%      Body = [ {<<"order">>, <<"breadth_first">>}
%%             , {<<"uniqueness">>, <<"none">>}
%%             , {<<"return_filter">>, [ {<<"language">>, <<"builtin">>}
%%                                     , {<<"name">>, <<"all">>}
%%                                     ]
%%               }
%%             ],
%%      neo4j:traverse(Node, Body)
%%         or
%%      neo4j:traverse(Node, Body, ReturnType) %% where ReturnType is a binary
-spec traverse(neo4j_node(), proplists:proplist()) -> proplists:proplist() | {error, term()}.
traverse(Node, Request) ->
  traverse(Node, Request, <<"node">>).

-spec traverse(neo4j_node(), proplists:proplist(), binary()) -> proplists:proplist() | {error, term()}.
traverse(Node, Request, ReturnType) ->
  {_, URI} = lists:keyfind(<<"traverse">>, 1, Node),
  Payload = jsonx:encode(Request),
  create(replace_param(URI, <<"returnType">>, ReturnType), Payload).

%%_* Paged traverse ------------------------------------------------------------

%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-traverse.html#rest-api-creating-a-paged-traverser
%%      http://docs.neo4j.org/chunked/milestone/rest-api-traverse.html#rest-api-paging-through-the-results-of-a-paged-traverser
%%      http://docs.neo4j.org/chunked/milestone/rest-api-traverse.html#rest-api-paged-traverser-page-size
%%      http://docs.neo4j.org/chunked/milestone/rest-api-traverse.html#rest-api-paged-traverser-timeout
%%
%%      Note: you'll have to construct your request body manually, e.g:
%%
%%      Neo = neo4j:connect([{base_uri, BaseUri}]),
%%      Node = neo4j:get_node(Neo, 101),
%%      Body = [ {<<"order">>, <<"breadth_first">>}
%%             , {<<"uniqueness">>, <<"none">>}
%%             , {<<"return_filter">>, [ {<<"language">>, <<"builtin">>}
%%                                     , {<<"name">>, <<"all">>}
%%                                     ]
%%               }
%%             ],
%%      PT = neo4j:paged_traverse(Node, Body)
%%         or
%%      PT = neo4j:paged_traverse(Node, Body, [ {<<"returnType">>, ReturnType}
%%                                            , {<<"leaseTime">>, LeaseTime}
%%                                            , {<<"pageSize">>, PageSize}
%%                                            ]).
%%
%%      To retrieve the next page, just pass in the PT:
%%
%%      neo4j:paged_traverse(PT). %% and so on, until you get an
%%                                %% {error, not_found}
%%
-spec paged_traverse(proplists:proplist()) -> proplists:proplist() | {error, term()}.
paged_traverse(PagedTraverse) ->
  {_, URI} = lists:keyfind(<<"self">>, 1, PagedTraverse),
  retrieve(URI).

-spec paged_traverse(neo4j_node(), proplists:proplist()) -> proplists:proplist() | {error, term()}.
paged_traverse(Node, Request) ->
  paged_traverse(Node, Request, [{<<"returnType">>, <<"node">>}]).

-spec paged_traverse(neo4j_node(), proplists:proplist(), proplists:proplist()) -> proplists:proplist() | {error, term()}.
paged_traverse(Node, Request, Props) ->
  QueryProps = [P || P = {Key, _} <- Props, Key /= <<"returnType">>],
  Query = case encode_query_string(QueryProps) of
            <<>> -> <<>>;
            S    -> <<"?", S/binary>>
          end,
  ReturnType = case lists:keyfind(return_type, 1, Props) of
                 {_, R} -> R;
                 _      -> <<"node">>
               end,
  {_, URI} = lists:keyfind(<<"paged_traverse">>, 1, Node),
  TypedURI = replace_param(URI, <<"returnType">>, ReturnType),
  QueryURI = replace_param(TypedURI, <<"?pageSize,leaseTime">>, Query),
  Payload = jsonx:encode(Request),
  create(QueryURI, Payload).

%%_* Graph algorithms ----------------------------------------------------------

%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-graph-algos.html
%%
%%      Note: you'll have to construct some of yourrequest body manually, e.g:
%%
%%      Neo = neo4j:connect([{base_uri, BaseUri}]),
%%      Node = neo4j:get_node(Neo, 101),
%%      AdditionalParams = [{<<"relationships">>, [ {<<"type">>, <<"to">>}
%%                                                , {<<"direction">>, <<"out">>}
%%                                                ]
%%                          }
%%                         ],
%%      neo4j:paths(Node, <<"shortestPath">>, 3, AdditionalParams).
%%
-spec paths(neo4j_node(), binary(), integer(), proplists:proplist()) -> proplists:proplist() | {error, term()}.
paths(Node, Algorithm, MaxDepth, Params) ->
  graph_algorithm(<<"paths">>, Node, Algorithm, MaxDepth, Params).

-spec path(neo4j_node(), binary(), integer(), proplists:proplist()) -> proplists:proplist() | {error, term()}.
path(Node, Algorithm, MaxDepth, Params) ->
  graph_algorithm(<<"path">>, Node, Algorithm, MaxDepth, Params).

-spec graph_algorithm(binary(), neo4j_node(), binary(), integer(), proplists:proplist()) -> proplists:proplist() | {error, term()}.
graph_algorithm(PathOrPaths, Node, Algorithm, MaxDepth, Params) ->
  {_, URI} = lists:keyfind(<<"self">>, 1, Node),
  PathsURI = <<URI/binary, "/", PathOrPaths/binary>>,
  Payload = jsonx:encode([ {<<"to">>, URI}
                         , {<<"algorithm">>, Algorithm}
                         , {<<"max_depth">>, MaxDepth}
                         | Params
                         ]
                        ),
  create(PathsURI, Payload).

%%_* Batch operations ----------------------------------------------------------

%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-batch-ops.html
%%
%%      Note: you'll have to construct the batch operation manually:
%%
%%      Neo = neo4j:connect([{base_uri, BaseUri}]),
%%      Payload = [ [ {<<"method">>, <<"PUT">>}
%%                  , {<<"to">>, <<"/node/31/properties">>}
%%                  , {<<"body">>, [{<<"age">>, 1}]}
%%                  , {<<"id">>, 0}
%%                  ]
%%                , [ {<<"method">>, <<"GET">>}
%%                  , {<<"to">>, <<"/node/31">>}
%%                  , {<<"id">>, 1}
%%                  ]
%%                , [ {<<"method">>, <<"POST">>}
%%                  , {<<"to">>, <<"/node">>}
%%                  , {<<"body">>, [{<<"age">>, 1}]}
%%                  , {<<"id">>, 2}
%%                  ]
%%                , [ {<<"method">>, <<"POST">>}
%%                  , {<<"to">>, <<"/node">>}
%%                  , {<<"body">>, [{<<"age">>, 1}]}
%%                  , {<<"id">>, 3}
%%                  ]
%%                ],
%%      neo4j:batch(Neo, Payload).
%%
-spec batch(neo4j_root(), proplists:proplist()) -> proplists:proplist() | {error, term()}.
batch(Neo, Request) ->
  {_, URI} = lists:keyfind(<<"batch">>, 1, Neo),
  Payload = jsonx:encode(Request),
  create(URI, Payload).


%%
%%_* Legacy node indices -------------------------------------------------------

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-indexes.html#rest-api-create-node-index
%%
-spec create_node_index(neo4j_root(), binary()) -> neo4j_index() | {error, term()}.
create_node_index(Neo, Name) ->
  {_, URI} = lists:keyfind(<<"node_index">>, 1, Neo),
  Payload = jsonx:encode([{<<"name">>, Name}]),
  create(URI, Payload).

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-indexes.html#rest-api-create-node-index
%%
-spec create_node_index(neo4j_root(), binary(), proplists:proplist()) -> neo4j_index() | {error, term()}.
create_node_index(Neo, Name, Config) ->
  {_, URI} = lists:keyfind(<<"node_index">>, 1, Neo),
  Payload = jsonx:encode([ {<<"name">>, Name}
                         , {<<"config">>, Config}
                         ]
                        ),
  create(URI, Payload).

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-indexes.html#rest-api-delete-node-index
%%
-spec delete_node_index(neo4j_root(), binary()) -> ok | {error, term()}.
delete_node_index(Neo, Name) ->
  {_, URI} = lists:keyfind(<<"node_index">>, 1, Neo),
  delete(<<URI/binary, "/", Name/binary>>).

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-indexes.html#rest-api-list-node-indexes
%%
-spec node_indices(neo4j_root()) -> [{binary(), neo4j_index()}] | {error, term()}.
node_indices(Neo) ->
  {_, URI} = lists:keyfind(<<"node_index">>, 1, Neo),
  list(retrieve(URI)).

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-indexes.html#rest-api-add-node-to-index
%%
-spec add_node_to_index( neo4j_root()
                       , neo4j_node()
                       , Index::binary()
                       , Key::binary
                       , Value::binary
                       ) -> term() | {error, term()}.
add_node_to_index(Neo, Node, Index, Key, Value) ->
  {_, NodeURI} = lists:keyfind(<<"self">>, 1, Node),
  Payload = jsonx:encode([ {<<"uri">>, NodeURI}
                         , {<<"key">>, Key}
                         , {<<"value">>, Value}
                         ]
                        ),
  {_, URI} = lists:keyfind(<<"node_index">>, 1, Neo),
  create(<<URI/binary, "/", Index/binary>>, Payload).

%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-unique-indexes.html#rest-api-add-an-existing-node-to-unique-index-not-indexed
%%      http://docs.neo4j.org/chunked/milestone/rest-api-unique-indexes.html#rest-api-add-an-existing-node-to-unique-index-already-indexed
%%
-spec add_node_to_index( neo4j_root()
                       , neo4j_node()
                       , Index::binary()
                       , Key::binary
                       , Value::binary
                       , Uniqueness::binary()
                       ) -> term() | {error, term()}.
add_node_to_index(Neo, Node, Index, Key, Value, Uniqieness) ->
  {_, NodeURI} = lists:keyfind(<<"self">>, 1, Node),
  Payload = jsonx:encode([ {<<"uri">>, NodeURI}
                         , {<<"key">>, Key}
                         , {<<"value">>, Value}
                         ]
                        ),
  {_, URI} = lists:keyfind(<<"node_index">>, 1, Neo),
  create(<<URI/binary, "/", Index/binary, "?uniqueness=", Uniqieness/binary>>, Payload).


%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-indexes.html#rest-api-remove-all-entries-with-a-given-node-from-an-index
%%
-spec remove_from_node_index(neo4j_root(), neo4j_node(), binary()) -> term() | {error, term()}.
remove_from_node_index(Neo, Node, Index) ->
  Id = id(Node),
  {_, URI} = lists:keyfind(<<"node_index">>, 1, Neo),
  delete(<<URI/binary, "/", Index/binary, "/", Id/binary>>).

%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-indexes.html#rest-api-remove-all-entries-with-a-given-node-and-key-from-an-index
%%
-spec remove_from_node_index(neo4j_root(), neo4j_node(), binary(), binary()) -> term() | {error, term()}.
remove_from_node_index(Neo, Node, Index, Key) ->
  Id = id(Node),
  {_, URI} = lists:keyfind(<<"node_index">>, 1, Neo),
  delete(<<URI/binary, "/", Index/binary, "/", Key/binary, "/", Id/binary>>).

%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-indexes.html#rest-api-remove-all-entries-with-a-given-node
%%
-spec remove_from_node_index(neo4j_root(), neo4j_node(), binary(), binary(), binary()) -> term() | {error, term()}.
remove_from_node_index(Neo, Node, Index, Key, Value) ->
  Id = id(Node),
  {_, URI} = lists:keyfind(<<"node_index">>, 1, Neo),
  delete(<<URI/binary, "/", Index/binary, "/", Key/binary, "/", Value/binary, "/", Id/binary>>).

%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-indexes.html#rest-api-find-node-by-exact-match
%%
-spec find_node_exact(neo4j_root(), binary(), binary(), binary()) -> term() | {error, term()}.
find_node_exact(Neo, Index, Key, Value) ->
  {_, URI} = lists:keyfind(<<"node_index">>, 1, Neo),
  retrieve(<<URI/binary, "/", Index/binary, "/", Key/binary, "/", Value/binary>>).

%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-indexes.html#rest-api-find-node-by-query
%%
-spec find_node_query(neo4j_root(), binary(), binary()) -> term() | {error, term()}.
find_node_query(Neo, Index, Query) ->
  {_, URI} = lists:keyfind(<<"node_index">>, 1, Neo),
  retrieve(<<URI/binary, "/", Index/binary, "?query=", Query/binary>>).

%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-indexes.html#rest-api-find-node-by-query
%%
-spec find_node_query(neo4j_root(), binary(), binary(), binary()) -> term() | {error, term()}.
find_node_query(Neo, Index, Query, Ordering) ->
  {_, URI} = lists:keyfind(<<"node_index">>, 1, Neo),
  retrieve(<<URI/binary, "/", Index/binary, "?query=", Query/binary, "&ordering=", Ordering/binary>>).

%%_* Legacy relationship indices ------------------------------------------------------

%%
%% @doc
%%
-spec create_relationship_index(neo4j_root(), binary()) -> neo4j_index() | {error, term()}.
create_relationship_index(Neo, Name) ->
  {_, URI} = lists:keyfind(<<"relationship_index">>, 1, Neo),
  Payload = jsonx:encode([{<<"name">>, Name}]),
  create(URI, Payload).

%%
%% @doc
%%
-spec create_relationship_index(neo4j_root(), binary(), proplists:proplist()) -> neo4j_index() | {error, term()}.
create_relationship_index(Neo, Name, Config) ->
  {_, URI} = lists:keyfind(<<"relationship_index">>, 1, Neo),
  Payload = jsonx:encode([ {<<"name">>, Name}
                         , {<<"config">>, Config}
                         ]
                        ),
  create(URI, Payload).

%%
%% @doc
%%
-spec delete_relationship_index(neo4j_root(), binary()) -> ok | {error, term()}.
delete_relationship_index(Neo, Name) ->
  {_, URI} = lists:keyfind(<<"relationship_index">>, 1, Neo),
  delete(<<URI/binary, "/", Name/binary>>).

%%
%% @doc
%%
-spec relationship_indices(neo4j_root()) -> [{binary(), neo4j_index()}] | {error, term()}.
relationship_indices(Neo) ->
  {_, URI} = lists:keyfind(<<"relationship_index">>, 1, Neo),
  list(retrieve(URI)).

%%
%% @doc
%%
-spec add_relationship_to_index( neo4j_root()
                               , neo4j_relationship()
                               , Index::binary()
                               , Key::binary
                               , Value::binary
                               ) -> term() | {error, term()}.
add_relationship_to_index(Neo, Relationship, Index, Key, Value) ->
  {_, NodeURI} = lists:keyfind(<<"self">>, 1, Relationship),
  Payload = jsonx:encode([ {<<"uri">>, NodeURI}
                         , {<<"key">>, Key}
                         , {<<"value">>, Value}
                         ]
                        ),
  {_, URI} = lists:keyfind(<<"relationship_index">>, 1, Neo),
  create(<<URI/binary, "/", Index/binary>>, Payload).

%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-unique-indexes.html#rest-api-add-an-existing-relationship-to-a-unique-index-not-indexed
%%      http://docs.neo4j.org/chunked/milestone/rest-api-unique-indexes.html#rest-api-add-an-existing-relationship-to-a-unique-index-already-indexed
%%
-spec add_relationship_to_index( neo4j_root()
                               , neo4j_relationship()
                               , Index::binary()
                               , Key::binary
                               , Value::binary
                               , Uniqueness::binary()
                               ) -> term() | {error, term()}.
add_relationship_to_index(Neo, Relationship, Index, Key, Value, Uniqieness) ->
  {_, NodeURI} = lists:keyfind(<<"self">>, 1, Relationship),
  Payload = jsonx:encode([ {<<"uri">>, NodeURI}
                         , {<<"key">>, Key}
                         , {<<"value">>, Value}
                         ]
                        ),
  {_, URI} = lists:keyfind(<<"relationship_index">>, 1, Neo),
  create(<<URI/binary, "/", Index/binary, "?uniqueness=", Uniqieness/binary>>, Payload).


%%
%% @doc
%%
-spec remove_from_relationship_index(neo4j_root(), neo4j_relationship(), binary()) -> term() | {error, term()}.
remove_from_relationship_index(Neo, Relationship, Index) ->
  Id = id(Relationship),
  {_, URI} = lists:keyfind(<<"relationship_index">>, 1, Neo),
  delete(<<URI/binary, "/", Index/binary, "/", Id/binary>>).

%%
%% @doc
%%
-spec remove_from_relationship_index(neo4j_root(), neo4j_relationship(), binary(), binary()) -> term() | {error, term()}.
remove_from_relationship_index(Neo, Relationship, Index, Key) ->
  Id = id(Relationship),
  {_, URI} = lists:keyfind(<<"relationship_index">>, 1, Neo),
  delete(<<URI/binary, "/", Index/binary, "/", Key/binary, "/", Id/binary>>).

%%
%% @doc
%%
-spec remove_from_relationship_index(neo4j_root(), neo4j_relationship(), binary(), binary(), binary()) -> term() | {error, term()}.
remove_from_relationship_index(Neo, Relationship, Index, Key, Value) ->
  Id = id(Relationship),
  {_, URI} = lists:keyfind(<<"relationship_index">>, 1, Neo),
  delete(<<URI/binary, "/", Index/binary, "/", Key/binary, "/", Value/binary, "/", Id/binary>>).

%%
%% @doc
%%
-spec find_relationship_exact(neo4j_root(), binary(), binary(), binary()) -> term() | {error, term()}.
find_relationship_exact(Neo, Index, Key, Value) ->
  {_, URI} = lists:keyfind(<<"relationship_index">>, 1, Neo),
  retrieve(<<URI/binary, "/", Index/binary, "/", Key/binary, "/", Value/binary>>).

%%
%% @doc
%%
-spec find_relationship_query(neo4j_root(), binary(), binary()) -> term() | {error, term()}.
find_relationship_query(Neo, Index, Query) ->
  {_, URI} = lists:keyfind(<<"relationship_index">>, 1, Neo),
  retrieve(<<URI/binary, "/", Index/binary, "?query=", Query/binary>>).

%%
%% @doc
%%
-spec find_relationship_query(neo4j_root(), binary(), binary(), binary()) -> term() | {error, term()}.
find_relationship_query(Neo, Index, Query, Ordering) ->
  {_, URI} = lists:keyfind(<<"relationship_index">>, 1, Neo),
  retrieve(<<URI/binary, "/", Index/binary, "?query=", Query/binary, "&ordering=", Ordering/binary>>).

%%_* Uniqueness (legacy) -------------------------------------------------------

%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-unique-indexes.html#rest-api-get-or-create-unique-node-create
%%      http://docs.neo4j.org/chunked/milestone/rest-api-unique-indexes.html#rest-api-get-or-create-unique-node-existing
%%      http://docs.neo4j.org/chunked/milestone/rest-api-unique-indexes.html#rest-api-create-a-unique-node-or-return-fail-create
%%      http://docs.neo4j.org/chunked/milestone/rest-api-unique-indexes.html#rest-api-create-a-unique-node-or-return-fail-fail
%%
-spec unique_create_node( neo4j_root()
                        , proplists:proplist()
                        , binary()
                        , binary()
                        , binary()
                        , binary()
                        ) -> neo4j_node() | {error, term()}.
unique_create_node(Neo, Props, Index, Key, Value, Uniqueness) ->
  {_, URI} = lists:keyfind(<<"node_index">>, 1, Neo),
  Payload = jsonx:encode([ {<<"key">>, Key}
                         , {<<"value">>, Value}
                         , {<<"properties">>, Props}
                         ]),
  create(<<URI/binary, "/", Index/binary, "?uniqueness=", Uniqueness/binary>>, Payload).

%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-unique-indexes.html#rest-api-get-or-create-unique-relationship-create
%%      http://docs.neo4j.org/chunked/milestone/rest-api-unique-indexes.html#rest-api-get-or-create-unique-relationship-existing
%%      http://docs.neo4j.org/chunked/milestone/rest-api-unique-indexes.html#rest-api-create-a-unique-relationship-or-return-fail-create
%%      http://docs.neo4j.org/chunked/milestone/rest-api-unique-indexes.html#rest-api-create-a-unique-relationship-or-return-fail-fail
%%
-spec unique_create_relationship( neo4j_root()
                                , neo4j_node()
                                , neo4j_node()
                                , binary()
                                , binary()
                                , binary()
                                , binary()
                                , binary()
                                ) -> neo4j_relationship() | {error, term()}.
unique_create_relationship(Neo, StartNode, EndNode, Type, Index, Key, Value, Uniqueness) ->
  {_, URI} = lists:keyfind(<<"relationship_index">>, 1, Neo),
  {_, StartUri} = lists:keyfind(<<"self">>, 1, StartNode),
  {_, EndUri} = lists:keyfind(<<"self">>, 1, EndNode),
  Payload = jsonx:encode([ {<<"key">>, Key}
                         , {<<"value">>, Value}
                         , {<<"type">>, Type}
                         , {<<"start">>, StartUri}
                         , {<<"end">>, EndUri}
                         ]),
  create(<<URI/binary, "/", Index/binary, "?uniqueness=", Uniqueness/binary>>, Payload).

%%_* Legacy auto indices -------------------------------------------------------

%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-auto-indexes.html#rest-api-find-node-by-exact-match-from-an-automatic-index
%%
-spec find_node_auto_exact(neo4j_root(), binary(), binary()) -> term() | {error, term()}.
find_node_auto_exact(Neo, Key, Value) ->
  {_, URI} = lists:keyfind(<<"base_uri">>, 1, Neo),
  retrieve(<<URI/binary, "index/auto/node/", Key/binary, "/", Value/binary>>).

%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-auto-indexes.html#rest-api-find-node-by-query-from-an-automatic-index
%%
-spec find_node_auto_query(neo4j_root(), binary()) -> term() | {error, term()}.
find_node_auto_query(Neo, Query) ->
  {_, URI} = lists:keyfind(<<"base_uri">>, 1, Neo),
  retrieve(<<URI/binary, "index/auto/node?query=", Query/binary>>).

%%
%% @doc
%%
-spec find_relationship_auto_exact(neo4j_root(), binary(), binary()) -> term() | {error, term()}.
find_relationship_auto_exact(Neo, Key, Value) ->
  {_, URI} = lists:keyfind(<<"base_uri">>, 1, Neo),
  retrieve(<<URI/binary, "index/auto/relationship/", Key/binary, "/", Value/binary>>).

%%
%% @doc
%%
-spec find_relationship_auto_query(neo4j_root(), binary()) -> term() | {error, term()}.
find_relationship_auto_query(Neo, Query) ->
  {_, URI} = lists:keyfind(<<"base_uri">>, 1, Neo),
  retrieve(<<URI/binary, "index/auto/relationship?query=", Query/binary>>).


%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-configurable-auto-indexes.html#rest-api-create-an-auto-index-for-nodes-with-specific-configuration
%%
-spec create_node_auto_index(neo4j_root(), proplists:proplist()) -> term() | {error, term()}.
create_node_auto_index(Neo, Config) ->
  create_node_index(Neo, <<"node_auto_index">>, Config).


%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-configurable-auto-indexes.html#rest-api-create-an-auto-index-for-relationships-with-specific-configuration
%%
-spec create_relationship_auto_index(neo4j_root(), proplists:proplist()) -> term() | {error, term()}.
create_relationship_auto_index(Neo, Config) ->
  create_node_index(Neo, <<"relationship_auto_index">>, Config).


%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-configurable-auto-indexes.html#rest-api-get-current-status-for-autoindexing-on-nodes
%%
-spec get_node_auto_index_status(neo4j_root()) -> boolean() | {error, term()}.
get_node_auto_index_status(Neo) ->
  {_, URI} = lists:keyfind(<<"base_uri">>, 1, Neo),
  retrieve(<<URI/binary, "index/auto/node/status">>).

%%
%% @doc
%%
-spec get_relationship_auto_index_status(neo4j_root()) -> boolean() | {error, term()}.
get_relationship_auto_index_status(Neo) ->
  {_, URI} = lists:keyfind(<<"base_uri">>, 1, Neo),
  retrieve(<<URI/binary, "index/auto/relationship/status">>).


%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-configurable-auto-indexes.html#rest-api-enable-node-autoindexing
%%
-spec set_node_auto_index_status(neo4j_root(), boolean()) -> ok | {error, term()}.
set_node_auto_index_status(Neo, Status) ->
  {_, URI} = lists:keyfind(<<"base_uri">>, 1, Neo),
  update(<<URI/binary, "index/auto/node/status">>, jsonx:encode(Status)).

%%
%% @doc
%%
-spec set_relationship_auto_index_status(neo4j_root(), boolean()) -> ok | {error, term()}.
set_relationship_auto_index_status(Neo, Status) ->
  {_, URI} = lists:keyfind(<<"base_uri">>, 1, Neo),
  update(<<URI/binary, "index/auto/relationship/status">>, jsonx:encode(Status)).


%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-configurable-auto-indexes.html#rest-api-lookup-list-of-properties-being-autoindexed
%%
-spec get_node_auto_index_properties(neo4j_root()) -> boolean() | {error, term()}.
get_node_auto_index_properties(Neo) ->
  {_, URI} = lists:keyfind(<<"base_uri">>, 1, Neo),
  retrieve(<<URI/binary, "index/auto/node/properties">>).

%%
%% @doc
%%
-spec get_relationship_auto_index_properties(neo4j_root()) -> boolean() | {error, term()}.
get_relationship_auto_index_properties(Neo) ->
  {_, URI} = lists:keyfind(<<"base_uri">>, 1, Neo),
  retrieve(<<URI/binary, "index/auto/relationship/properties">>).


%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-configurable-auto-indexes.html#rest-api-add-a-property-for-autoindexing-on-nodes
%%
-spec add_node_auto_index_property(neo4j_root(), binary()) -> ok | {error, term()}.
add_node_auto_index_property(Neo, Property) ->
  {_, URI} = lists:keyfind(<<"base_uri">>, 1, Neo),
  create(<<URI/binary, "index/auto/node/properties">>, jsonx:encode(Property)).

%%
%% @doc
%%
-spec add_relationship_auto_index_property(neo4j_root(), binary()) -> ok | {error, term()}.
add_relationship_auto_index_property(Neo, Property) ->
  {_, URI} = lists:keyfind(<<"base_uri">>, 1, Neo),
  create(<<URI/binary, "index/auto/relationship/properties">>, jsonx:encode(Property)).


%%
%% @doc http://docs.neo4j.org/chunked/milestone/rest-api-configurable-auto-indexes.html#rest-api-remove-a-property-for-autoindexing-on-nodes
%%
-spec remove_node_auto_index_property(neo4j_root(), binary()) -> ok | {error, term()}.
remove_node_auto_index_property(Neo, Property) ->
  {_, URI} = lists:keyfind(<<"base_uri">>, 1, Neo),
  delete(<<URI/binary, "index/auto/node/properties/", Property/binary>>).

%%
%% @doc
%%
-spec remove_relationship_auto_index_property(neo4j_root(), binary()) -> ok | {error, term()}.
remove_relationship_auto_index_property(Neo, Property) ->
  {_, URI} = lists:keyfind(<<"base_uri">>, 1, Neo),
  delete(<<URI/binary, "index/auto/relationship/properties/", Property/binary>>).


%%_* Internal ==================================================================

%%
%% http://docs.neo4j.org/chunked/stable/rest-api-service-root.html#rest-api-get-service-root
%%
-spec get_root(binary()) -> neo4j_root() | {error, term()}.
get_root(BaseURI) when is_list(BaseURI)   -> get_root(list_to_binary(BaseURI));
get_root(BaseURI) when is_binary(BaseURI) ->
  case hackney:request(get, BaseURI, headers()) of
    {error, Reason} -> {error, Reason};
    {ok, StatusCode, _, Client} when StatusCode /= 200 ->
      {ok, Body} = hackney:body(Client),
      {error, {non_200_response, StatusCode, Body}};
    {ok, _, _, Client} ->
      {ok, Body} = hackney:body(Client),
      case jsonx:decode(Body, [{format, proplist}]) of
        {error, E1, E2} -> {error, {E1, E2}};
        Root          ->
          %% we add some links as these are not returned by neo4j
          %% an we wouldn't want to recreate them over and over again
          [ {<<"base_uri">>, BaseURI}
          , {<<"relationship">>, <<BaseURI/binary, "relationship">>}
          , {<<"label">>, <<BaseURI/binary, "label">>}
          , {<<"labels">>, <<BaseURI/binary, "labels">>}
          , {<<"index">>, <<BaseURI/binary, "schema/index">>}
          , {<<"constraint">>, <<BaseURI/binary, "schema/constraint">>}
            | Root
          ]
      end
  end.

-spec create(binary()) -> neo4j_type() | binary() | [term()] | {error, term()}.
create(URI) ->
  io:format("[POST] ~p~n", [URI]),
  case hackney:request(post, URI, headers()) of
    {error, Reason} -> {error, Reason};
    {ok, 200, _, Client} ->
      {ok, Body} = hackney:body(Client),
      jsonx:decode(Body, [{format, proplist}]);
    {ok, 201, Headers, Client} ->
      {ok, Body} = hackney:body(Client),
      case lists:keyfind(<<"Location">>, 1, Headers) of
        {_, Location} -> [ {<<"self">>, Location}
                         | jsonx:decode(Body, [{format, proplist}])
                         ];
        _             -> jsonx:decode(Body, [{format, proplist}])
      end;
    {ok, 204, _, _} ->
      ok;
    {ok, Status, _, Client} ->
      process_response(URI, Status, Client)
  end.

-spec create(binary(), binary()) -> neo4j_type() | binary() | [term()] | {error, term()}.
create(URI, Payload) ->
  io:format("[POST] ~p ~p~n", [URI, Payload]),
  case hackney:request(post, URI, headers(), Payload) of
    {error, Reason} -> {error, Reason};
    {ok, 200, _, Client} ->
      {ok, Body} = hackney:body(Client),
      jsonx:decode(Body, [{format, proplist}]);
    {ok, 201, Headers, Client} ->
      {ok, Body} = hackney:body(Client),
      case lists:keyfind(<<"Location">>, 1, Headers) of
        {_, Location} -> [ {<<"self">>, Location}
                         | jsonx:decode(Body, [{format, proplist}])
                         ];
        _             -> jsonx:decode(Body, [{format, proplist}])
      end;
    {ok, 204, _, _} ->
      ok;
    {ok, Status, _, Client} ->
      process_response(URI, Status, Client)
  end.

-spec retrieve(binary()) -> neo4j_type() | binary() | [term()] | {error, term()}.
retrieve(URI) ->
  io:format("[GET] ~p~n", [URI]),
  case hackney:request(get, URI, headers()) of
    {error, Reason} -> {error, Reason};
    {ok, 404, _, _} ->
      {error, not_found};
    {ok, 200, _, Client} ->
      {ok, Body} = hackney:body(Client),
      jsonx:decode(Body, [{format, proplist}]);
    {ok, 204, _, _} ->
      <<>>;
    {ok, Status, _, Client} ->
      process_response(URI, Status, Client)
  end.

-spec update(binary(), binary()) -> ok | {error, term()}.
update(URI, Payload) ->
  io:format("[PUT] ~p ~p~n", [URI, Payload]),
  case hackney:request(put, URI, headers(), Payload) of
    {error, Reason} -> {error, Reason};
    {ok, 204, _, _} ->
      ok;
    {ok, Status, _, Client} ->
      process_response(URI, Status, Client)
  end.

-spec delete(binary()) -> ok | {error, term()}.
delete(URI) ->
  io:format("[DELETE] ~p~n", [URI]),
  case hackney:request(delete, URI) of
    {error, Reason} -> {error, Reason};
    {ok, 204, _, _} ->
      ok;
    {ok, 200, _, Client} ->
      {ok, Body} = hackney:body(Client),
      jsonx:decode(Body, [{format, proplist}]);
    {ok, Status, _, Client} ->
      process_response(URI, Status, Client)
  end.

%%
%% @doc http://docs.neo4j.org/chunked/stable/rest-api-relationships.html#rest-api-get-all-relationships
%%
-spec get_relationship_by_direction(neo4j_node(), all | in | out) -> [neo4j_relationship()] | {error, term()}.
get_relationship_by_direction(Node, all) ->
  {_, URI} = lists:keyfind(<<"all_relationships">>, 1, Node),
  retrieve(URI);
get_relationship_by_direction(Node, in) ->
  {_, URI} = lists:keyfind(<<"incoming_relationships">>, 1, Node),
  retrieve(URI);
get_relationship_by_direction(Node, out) ->
  {_, URI} = lists:keyfind(<<"outgoing_relationships">>, 1, Node),
  retrieve(URI);
get_relationship_by_direction(_, _) ->
  {error, invalid_relationship_direction}.

-spec get_relationship_by_type(neo4j_node(), binary()) -> [neo4j_relationship()] | {error, term()}.
get_relationship_by_type(Node, Type) ->
  get_relationship_by_type(Node, Type, all).

-spec get_relationship_by_type( neo4j_node()
                              , binary()
                              , all | in | out
                              ) -> [neo4j_relationship()] | {error, term()}.
get_relationship_by_type(Node, Type, all) ->
  {_, URI} = lists:keyfind(<<"all_typed_relationships">>, 1, Node),
  retrieve(replace_param(URI, <<"-list|&|types">>, Type));
get_relationship_by_type(Node, Type, in) ->
  {_, URI} = lists:keyfind(<<"incoming_typed_relationships">>, 1, Node),
  retrieve(replace_param(URI, <<"-list|&|types">>, Type));
get_relationship_by_type(Node, Type, out) ->
  {_, URI} = lists:keyfind(<<"outgoing_typed_relationships">>, 1, Node),
  retrieve(replace_param(URI, <<"-list|&|types">>, Type));
get_relationship_by_type(_, _, _) ->
  {error, invalid_relationship_direction_or_type}.

%%
%% @doc
%% {
%%   "statements" : [ {
%%     "statement" : "CREATE (n {props}) RETURN n",
%%     "parameters" : {
%%       "props" : {
%%         "name" : "My Node"
%%       }
%%     }
%%   } ]
%% }
%%
-spec encode_transaction_query(proplists:proplist()) -> binary().
encode_transaction_query(<<"">>) ->
  jsonx:encode([{<<"statements">>, []}]);
encode_transaction_query(Q) ->
  Statements = [prepare_statement(Query) || Query <- Q],
  jsonx:encode([{<<"statements">>, Statements}]).

-spec prepare_statement(binary()) -> proplists:proplist();
                       ({binary()}) -> proplists:proplist();
                       ({binary(), proplists:proplist()}) -> proplists:proplist();
                       ({binary(), proplists:proplist(), [binary()]}) -> proplists:proplist().
prepare_statement(Q) when is_binary(Q) ->
  prepare_statement({Q, [], []});
prepare_statement({Q}) ->
  prepare_statement({Q, [], []});
prepare_statement({Q, P}) ->
  prepare_statement({Q, P, []});
prepare_statement({Query, [], []}) ->
  [{<<"statement">>, Query}];
prepare_statement({Query, Params, []}) ->
  [{<<"statement">>, Query}
  , {<<"parameters">>, Params}
  ];
prepare_statement({Query, [], Formats}) ->
  [{<<"statement">>, Query}
  , {<<"resultDataContents">>, Formats}
  ];
prepare_statement({Query, Params, Formats}) ->
  [{<<"statement">>, Query}
  , {<<"parameters">>, Params}
  , {<<"resultDataContents">>, Formats}
  ].

%%_* Helpers ===================================================================

-spec start_app(atom()) -> [atom()].

start_app(App) ->
  lists:flatten(start_app(App, 30)).

-spec start_app(atom(), 0..30) -> [atom()].
start_app(_, 0) ->
  throw(too_much_recursion);
start_app(App, N) ->
  case application:start(App) of
    {error, {already_started, App}} ->
      [];
    {error, {not_started, OtherApp}} ->
      [start_app(OtherApp, N - 1),
        start_app(App, N - 1)];
    ok ->
      [App]
  end.

-spec id_to_binary(neo4j_id()) -> binary() | {error, invalid_id}.
id_to_binary(Id) when is_integer(Id) ->
  list_to_binary(integer_to_list(Id));
id_to_binary(Id) when is_list(Id) ->
  list_to_binary(Id);
id_to_binary(Id) when is_binary(Id) ->
  Id;
id_to_binary(_) ->
  {error, invalid_id}.

%%
%% Replace {key} type params in URIs provided by resources
%%
-spec replace_param(binary(), binary(), binary()) -> binary().
replace_param(URI, Param, Value) ->
  binary:replace(URI, <<"{", Param/binary, "}">>, Value).

-spec is_uri(binary()) -> boolean().
is_uri(<<$h, $t, $t, $p, _/binary>>) -> true;
is_uri(_)                            -> false.

-spec id(proplists:proplist()) -> binary().
id(Obj) ->
  {_, URI} = lists:keyfind(<<"self">>, 1, Obj),
  lists:last(binary:split(URI, <<"/">>, [global])).

-spec process_response(integer(), binary(), hackney:client()) -> {error, term()}.
process_response(URI, 404, _Client) ->
  {error, {not_found, URI}};
process_response(URI, 405, _Client) ->
  {error, {method_not_allowed, URI}};
process_response(URI, Status, Client) ->
  {ok, Body} = hackney:body(Client),
  case Body of
    <<>> -> {error, {Status, URI, <<>>}};
    _ -> {error, {Status, URI, jsonx:decode(Body, [{format, proplist}])}}
  end.

-spec list(list() | binary()) -> list().
list(L) when is_list(L)   -> L;
list(B) when is_binary(B) -> binary_to_list(B).

-spec encode_query_string(proplists:proplist()) -> binary().
encode_query_string(Props) ->
  List = [<<Key/binary, "=", Value/binary>> || {Key, Value} <- Props],
  Join = fun(B, <<>>) ->
              B;
            (B, Acc) ->
              <<Acc/binary, "&", B/binary>>
         end,
  lists:foldl(Join, <<>>, List).

-spec headers() -> proplists:proplist().
headers() ->
  [ {<<"Accept">>, <<"application/json; charset=UTF-8">>}
  , {<<"Content-Type">>, <<"application/json">>}
  ].
