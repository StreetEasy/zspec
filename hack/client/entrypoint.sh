#!/bin/bash
while ! bundle exec zspec connected; do
  echo "REDIS is unavailable - sleeping"
  sleep 1
done

echo "Build Number: ${ZSPEC_BUILD_NUMBER}"

echo "Queuing specs"
bundle exec zspec queue_specs spec/zspec

echo "Printing results"
bundle exec zspec present
