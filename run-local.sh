#!/bin/bash
. env/bin/activate
while IFS='=' read -r key value; do eval "export $key=$value"; done < <(cat .env);
python3 -m flask run --reload --host=0.0.0.0
