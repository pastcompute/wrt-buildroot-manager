#!/bin/bash
#
# This file gets copied into a new project by `wrt-project create`.
# Clone a copy of wrt-buildroot-manager into project and then build it; useful for a casual user
# to build someone elses project.
#

set -e

git clone http://github.com/pastcompute/wrt-buildroot-manager

wrt-buildroot-manager/configure.sh

source  wrt-buildroot-manager/wrt-buildroot-manager.source

wrt-project build

