#!/bin/bash
set -e

daemonset=$1
namespace=$2

# The binaries downloaded by the install-binaries script are located in the /tmp directory.
export PATH=$PATH:${3:-"/tmp"}

kubectl rollout status ds "${daemonset}" -n "${namespace}" --timeout 30m
