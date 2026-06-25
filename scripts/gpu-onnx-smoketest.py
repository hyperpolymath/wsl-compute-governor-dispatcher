#!/usr/bin/env python3
# SPDX-License-Identifier: MPL-2.0
"""Phase-1 GPU offload check: can ONNX-Runtime use the GPU (CUDA EP) in WSL2?

Install:  python3 -m pip install onnxruntime-gpu onnx numpy
Run:      python3 scripts/gpu-onnx-smoketest.py

Exit 0 + a matmul that ran on CUDAExecutionProvider == GPU offload works.
This is the lightest of the phased examples; PyTorch and CuPy/Numba come later.
"""
import sys

try:
    import numpy as np
    import onnxruntime as ort
    from onnx import TensorProto, helper
except ImportError:
    sys.exit("missing deps -> python3 -m pip install onnxruntime-gpu onnx numpy")

print("onnxruntime", ort.__version__)
provs = ort.get_available_providers()
print("available providers:", provs)
if "CUDAExecutionProvider" not in provs:
    sys.exit("CUDAExecutionProvider NOT available — install onnxruntime-gpu and "
             "ensure the NVIDIA WSL driver is present (/dev/dxg, /usr/lib/wsl/lib).")

N = 1024
g = helper.make_graph(
    [helper.make_node("MatMul", ["A", "B"], ["Y"])], "mm",
    [helper.make_tensor_value_info("A", TensorProto.FLOAT, [N, N]),
     helper.make_tensor_value_info("B", TensorProto.FLOAT, [N, N])],
    [helper.make_tensor_value_info("Y", TensorProto.FLOAT, [N, N])])
model = helper.make_model(g, opset_imports=[helper.make_opsetid("", 18)])

sess = ort.InferenceSession(model.SerializeToString(),
                            providers=["CUDAExecutionProvider", "CPUExecutionProvider"])
used = sess.get_providers()[0]
a = np.random.rand(N, N).astype(np.float32)
b = np.random.rand(N, N).astype(np.float32)
out = sess.run(["Y"], {"A": a, "B": b})[0]
print(f"OK — {N}x{N} matmul ran on {used}; result {out.shape}")
if used != "CUDAExecutionProvider":
    sys.exit("ran on CPU fallback, not GPU — check driver/onnxruntime-gpu install.")
