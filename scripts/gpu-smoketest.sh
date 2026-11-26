#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Phase-1 GPU offload check: is the GPU reachable from WSL2?
#
# Run:  bash scripts/gpu-smoketest.sh
#
# Exit 0 = the WSL GPU device, the NVIDIA WSL driver libraries and nvidia-smi
# all work, which is what an ONNX-Runtime / CUDA run needs first. This script
# does not run a matmul; that step needs a GPU runtime library, and this repo
# keeps its scripts to Bash. PyTorch and CuPy/Numba come later.
set -euo pipefail

fail() { echo "FAIL: $*" >&2; exit 1; }

if [ ! -e /dev/dxg ]; then
  fail "/dev/dxg is missing: this is not WSL2 with GPU paravirtualisation enabled."
fi
echo "ok: /dev/dxg present"

shopt -s nullglob
libs=(/usr/lib/wsl/lib/libcuda.so*)
[ "${#libs[@]}" -gt 0 ] || fail "no libcuda in /usr/lib/wsl/lib: install the NVIDIA WSL driver on the Windows host."
echo "ok: ${libs[0]}"

smi="$(command -v nvidia-smi || true)"
[ -n "$smi" ] || smi=/usr/lib/wsl/lib/nvidia-smi
[ -x "$smi" ] || fail "nvidia-smi not found (PATH or /usr/lib/wsl/lib)."

if ! out="$("$smi" --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>&1)"; then
  fail "nvidia-smi could not talk to the GPU: $out"
fi
echo "ok: GPU visible -> $out"
echo "OK: the GPU is reachable from WSL2."
