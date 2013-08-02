#!/bin/sh
docker ps | cut -d' ' -f1 | grep -v 'ID' | xargs docker stop
