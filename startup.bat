cd ./ebin
start cmd /k "title [timer] & erl.exe    -name timer@127.0.0.1 -s server_tool run --line line@127.0.0.1"
start cmd /k "title [db] & erl.exe   -mnesia dir '"../dbfile/"'   -name db@127.0.0.1 -s server_tool run --line line@127.0.0.1"
start cmd /k "title [line] & erl.exe    -name line@127.0.0.1 -s server_tool run --line line@127.0.0.1"
start cmd /k "title [map1] & erl.exe  -smp disable  -name map1@127.0.0.1 -s server_tool run --line line@127.0.0.1"
start cmd /k "title [map2] & erl.exe  -smp disable  -name map2@127.0.0.1 -s server_tool run --line line@127.0.0.1"
start cmd /k "title [gate1] & erl.exe  -smp disable  -name gate1@127.0.0.1 -s server_tool run --line line@127.0.0.1"
start cmd /k "title [chat1] & erl.exe    -name chat1@127.0.0.1 -s server_tool run --line line@127.0.0.1"
start cmd /k "title [cross] & erl.exe    -name cross@127.0.0.1 -s server_tool run --line line@127.0.0.1"
start cmd /k "title [guild] & erl.exe    -name guild@127.0.0.1 -s server_tool run --line line@127.0.0.1"
start cmd /k "title [gm] & erl.exe    -name gm@127.0.0.1 -s server_tool run --line line@127.0.0.1"
start cmd /k "title [auth] & erl.exe    -name auth@127.0.0.1 -s server_tool run --line line@127.0.0.1"