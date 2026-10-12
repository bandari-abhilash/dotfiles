#!/bin/bash

# Lock the screen immediately (unlike `pmset displaysleepnow`, this doesn't
# depend on the "require password after sleep" setting)

osascript -l JavaScript \
  -e 'ObjC.import("Foundation")' \
  -e '$.NSBundle.bundleWithPath("/System/Library/PrivateFrameworks/login.framework").load' \
  -e 'ObjC.bindFunction("SACLockScreenImmediate", ["int", []])' \
  -e '$.SACLockScreenImmediate()'
