# Building containers for GH200

Currently, prebuilt wheels for `vLLM` and `LMcache` are not available for `aarch64`. This can make setup tedious when working on modern `aarch64` platforms such as NVIDIA GH200.

Further, Nvidia at this time does not provide the `Dockerfile` associated with the NGC containers which makes replacing some of the components (like a newer version of vLLM) tedious.

This repository provides a Dockerfile to build a container with vLLM and all its dependencies pre-installed to try out various things such as KV offloading.

If you prefer not to build the image yourself, you can pull the ready-to-use image directly from Docker Hub:

```bash
docker run --rm -it --gpus all -v "$PWD":"$PWD" -w "$PWD" rajesh550/gh200-vllm:0.11.0 bash

# CUDA 13
docker run --rm -it --gpus all -v "$PWD":"$PWD" -w "$PWD" rajesh550/gh200-vllm:0.11.1rc1 bash
```

👉 [Docker Hub](https://hub.docker.com/repository/docker/rajesh550/gh200-vllm/general)

Version info:

```bash
CUDA: 13.0.1
Ubuntu: 24.04
Python: 3.12
PyTorch: 2.9.0+cu130
Triton: 3.5.x
xformers: 0.32.post2+
flashinfer: 0.4.0
LMCache: 0.3.7
vLLM: 0.11.1rc1
```