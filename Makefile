PROJECT = neo4j

DEPS = hackney hackney_lib jsonx mimetypes
dep_hackney = https://github.com/benoitc/hackney
dep_jsonx = https://github.com/iskra/jsonx
dep_mimetypes = https://github.com/spawngrid/mimetypes
dep_hackney_lib = https:/github.com/benoitc/hackney_lib.git

PLT_APPS ?= asn1 compiler crypto erts inets kernel public_key stdlib ssl syntax_tools

include erlang.mk
