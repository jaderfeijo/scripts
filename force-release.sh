#!/usr/bin/env bash

BRANCH=`git rev-parse --abbrev-ref HEAD`
ssh gojimo@gojimos-mac-mini.local -t 'cd ~/gojimo-x && nohup fastlane deploy branch:$BRANCH > ~/gojimo-x-deploy.out 2>&1 &'
