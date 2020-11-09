#!/bin/bash
set -e
set -u

helm inspect values "$(pwd)/charts/loki" > loki.values
helm inspect values "$(pwd)/charts/promtail" > promtail.values

