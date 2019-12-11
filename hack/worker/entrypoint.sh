#!/bin/bash
while ! bundle exec zspec connected; do
  echo "REDIS is unavailable - sleeping"
  sleep 1
done

echo "Build Number: ${ZSPEC_BUILD_NUMBER}"

echo "Starting worker"
bundle exec zspec work
