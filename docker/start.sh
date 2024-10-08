#!/bin/bash

export CODE="tipitaka-pali-reader"
export NAME="$CODE-$USER"

podman run --rm -it --events-backend=file --hostname=palm --network host -v $PWD:/workspace:z $CODE

# if podman container exists $NAME; then
#     podman start -i -a $NAME
# else    
#     podman run --name $NAME -it --events-backend=file --hostname=palm --network host -v $PWD:/workspace:z $CODE
# fi
