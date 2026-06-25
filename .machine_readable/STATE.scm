; SPDX-License-Identifier: MPL-2.0
; STATE.scm — current project state (RSR machine-readable artefact)
(define state
  `((metadata
     (project . "wsl-compute-governor-dispatcher")
     (updated . "2026-06-25"))
    (position
     (phase . pilot)              ; design|implementation|testing|maintenance|archived
     (maturity . experimental))   ; experimental|alpha|beta|production|lts
    (scope
     (target . "WSL2")
     (note . "cgroup-slice core is general systemd/cgroup-v2 Linux; .wslconfig layer is WSL-only"))
    (verified
     (cpu-partition . "builds.slice enforces MemoryMax=6G MemoryHigh=5G cpu.weight=20; bgc confirmed")
     (watchdog . "estate-guard user timer live; GC hygiene ran across estate")
     (gpu . "RTX 4070 visible via GPU-PV, CUDA 13.1 runtime present; ONNX offload smoketest staged, not yet run"))
    (ecosystem
     (part-of . ("RSR Framework"))
     (depends-on . ("systemd" "cgroup-v2" "WSL2")))))
