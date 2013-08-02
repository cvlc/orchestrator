#!/bin/sh
# This will simply loop through all the docker containers running on the local host and stop each of them.
docker ps | cut -d' ' -f1 | grep -v 'ID' | xargs docker stop
