#!/bin/bash
mkdir -p build

elm make --optimize --output=build/Main.max.js src/Main.elm

uglifyjs build/Main.max.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output=build/Main.js

# FIXME: find way to compact and inline worker
cat src/simplejs-worker.js src/myjsfunctions.js > build/worker.js

cat src/index.html | inliner -m > build/index.html

echo "please open build/index.html using a web-server"
