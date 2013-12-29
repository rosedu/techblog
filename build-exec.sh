#!/bin/bash

# This file is to help build an executable for the Linux platform and have it
# on the root of the techblog.
#
# It needs to be run whenever the `site.hs' file changes and only then.

set -e

# If it is not important to have the executable in the root (or not on Linux)
# then run the following commands manually (since they should be platform
# independent, assuming everything is installed).
cabal clean
cabal configure
cabal build

# This command moves the generated executable to the root of the techblog.
# With it you can run techblog [options].
# Without it you have to run dist/build/techblog/techblog [options].
cp dist/build/techblog/techblog .

# Free some space. Totally optional.
strip techblog
rm -rf dist/
