#!/bin/bash

list="$(
    sudo ps -A \
    | grep -iE '([h]ear|[f]irefox|[b]lue|[c]oreaudiod)' \
    | cut -c 1-90
    )"


pids=$( cut -c 1-6 <<< "$list" )


echo sudo renice -5 $pids
sudo renice -5 $pids

