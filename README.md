# Building containers for GH200

Currently, prebuilt wheels for `vLLM` and `LMcache` are not available for `aarch64`. This can make setup tedious when working on modern `aarch64` platforms such as NVIDIA GH200.

This repository provides a Dockerfile to build a container with vLLM and all its dependencies pre-installed to try out various things such as KV offloading.

If you prefer not to build the image yourself, you can pull the ready-to-use image directly from Docker Hub:

`docker pull rajesh550/gh200-vllm:0.10.2`

👉 [Docker Hub](https://hub.docker.com/repository/docker/rajesh550/gh200-vllm/general)

