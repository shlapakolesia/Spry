#!/bin/sh
set -e

if [ -n "$AWS_LAMBDA_RUNTIME_API" ]; then
    exec python -m awslambdaric "$@"
fi

exec "$@"
