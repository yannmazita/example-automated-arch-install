#!/bin/bash
cd /serv/example-server/src/my_website || exit
poetry run gunicorn my_website.wsgi:application
