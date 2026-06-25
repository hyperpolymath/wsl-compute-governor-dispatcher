<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
# Changelog

All notable changes to this project are documented here.

## [0.1.0] — 2026-06-25 — phased pilot

Initial public pilot. WSL2-focused, experimental (n=1).

### Added
- `builds.slice` + `bgc` wrapper — opt-in cgroup CPU/RAM partitioning for heavy
  builds/provers (CPUWeight=20, MemoryMax=6G, MemoryHigh=5G). Verified enforced.
- `estate-guard` systemd user timer — memory/process pressure warnings, `renice` of
  runaway build tools (never the agents), hourly git GC hygiene.
- `config/wslconfig.example` — memory/swap cap guidance with host-RAM headroom.
- `scripts/gpu-onnx-smoketest.py` — phase-1 GPU offload check (ONNX-Runtime / CUDA EP).
- Comprehensive README + EXPLAINME with explicit limitations.

### Known limitations
See README "Limitations": experimental n=1; most heavy load (compilers, provers, agent
orchestration) is CPU-bound and not GPU-offloadable; `MemoryMax` trades VM-crash for
in-slice OOM-kill; opt-in only.
