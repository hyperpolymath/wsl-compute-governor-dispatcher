# SPDX-License-Identifier: MPL-2.0
set shell := ["bash", "-uc"]

default: status

# install user units + bgc wrapper, enable the watchdog timer
install:
    bash scripts/install.sh

# remove everything this installed (leaves .wslconfig alone)
uninstall:
    bash scripts/uninstall.sh

# show timer state, slice limits, and memory
status:
    @echo "== watchdog timer =="; systemctl --user is-active estate-guard.timer 2>/dev/null || echo inactive
    @echo "== builds.slice limits =="; systemctl --user show builds.slice -p CPUWeight,MemoryHigh,MemoryMax 2>/dev/null || true
    @echo "== memory =="; free -h
    @echo "== bgc =="; command -v bgc || echo "not on PATH (add ~/.local/bin)"

# phase-1 GPU offload check (needs: pip install onnxruntime-gpu onnx numpy)
gpu-smoketest:
    python3 scripts/gpu-onnx-smoketest.py

# end-to-end sanity: install, then prove a command lands in builds.slice
test: install
    bgc bash -c 'echo "cgroup: $(cat /proc/self/cgroup)"'
