#!/bin/sh

set -e
set -x

VERSIONS="1.9.3-p392 1.8.7-p370 2.0.0-p0 jruby-1.7.3"

for version in $VERSIONS; do
  RBENV_VERSION=$version bundle install --quiet
  RBENV_VERSION=$version bundle exec rspec spec
done
