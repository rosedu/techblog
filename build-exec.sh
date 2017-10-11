#!/bin/bash

# This file is to help build an executable for the Linux platform and have it
# on the root of the techblog.
#
# It needs to be run whenever the `site.hs' file changes and only then.

set -e

which stack || echo "Get stack from https://docs.haskellstack.org/en/stable/README/#the-haskell-tool-stack"

# If it is not important to have the executable in the root (or not on Linux)
# then run the following commands manually (since they should be platform
# independent, assuming everything is installed).
stack build

# Ensure that previous site is cleaned up
stack exec techblog -- clean

# From now, run stack exec techblog -- [options]
