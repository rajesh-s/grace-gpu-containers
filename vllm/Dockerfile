ARG CUDA_VERSION=12.9.0
ARG IMAGE_DISTRO=ubuntu24.04
ARG PYTHON_VERSION=3.12

# ---------- Builder Base ----------
FROM nvcr.io/nvidia/cuda:${CUDA_VERSION}-devel-${IMAGE_DISTRO} AS base

# Set arch lists for all targets
# 'a' suffix is not forward compatible but enables all optimizations
ARG TORCH_CUDA_ARCH_LIST="9.0a"
ENV TORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST}
ENV UV_TORCH_BACKEND=cu129
ARG VLLM_FA_CMAKE_GPU_ARCHES="90a-real"
ENV VLLM_FA_CMAKE_GPU_ARCHES=${VLLM_FA_CMAKE_GPU_ARCHES}

# Update apt packages and install dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update
RUN apt upgrade -y
RUN apt install -y --no-install-recommends \
        curl \
        git \
        libibverbs-dev \
        zlib1g-dev \
        libnuma-dev

# Clean apt cache
RUN apt clean
RUN rm -rf /var/lib/apt/lists/*
RUN rm -rf /var/cache/apt/archives

# Set compiler paths
ENV CC=/usr/bin/gcc
ENV CXX=/usr/bin/g++

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

# Setup build workspace
WORKDIR /workspace

# Prep build venv
ARG PYTHON_VERSION
RUN uv venv -p ${PYTHON_VERSION} --seed --python-preference only-managed
ENV VIRTUAL_ENV=/workspace/.venv
ENV PATH=${VIRTUAL_ENV}/bin:${PATH}
ENV CUDA_HOME=/usr/local/cuda
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}

RUN apt-get update && apt install -y wget

RUN uv pip install numpy==2.0.0
# Install pytorch nightly
RUN uv pip install torch==2.8.0+cu129 torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu129 --torch-backend=cu129

FROM base AS build-base
RUN mkdir /wheels

# Install build deps that aren't in project requirements files
# Make sure to upgrade setuptools to avoid triton build bug
RUN uv pip install -U build cmake ninja pybind11 setuptools wheel

FROM build-base AS build-triton
ARG TRITON_REF=release/3.4.x
ARG TRITON_BUILD_SUFFIX=+cu129
ENV TRITON_WHEEL_VERSION_SUFFIX=${TRITON_BUILD_SUFFIX:-}
RUN git clone https://github.com/triton-lang/triton.git
RUN cd triton && \
    git checkout ${TRITON_REF} && \
    git submodule sync && \
    git submodule update --init --recursive -j 8 && \
    uv build --wheel --no-build-isolation -o /wheels

RUN export MAX_JOBS=6
FROM build-base AS build-xformers
ARG XFORMERS_REF=v0.0.32.post2
ARG XFORMERS_BUILD_VERSION=0.0.30+cu129
ENV BUILD_VERSION=${XFORMERS_BUILD_VERSION:-${XFORMERS_REF#v}}
RUN git clone  https://github.com/facebookresearch/xformers.git
RUN cd xformers && \
    git checkout ${XFORMERS_REF} && \
    git submodule sync && \
    git submodule update --init --recursive -j 8 && \
    uv build --wheel --no-build-isolation -o /wheels

# Currently not supported on CUDA 12.8
FROM build-base AS build-flashinfer
ARG FLASHINFER_ENABLE_AOT=1
ARG FLASHINFER_REF=v0.4.1
ARG FLASHINFER_BUILD_SUFFIX=cu129
ENV FLASHINFER_LOCAL_VERSION=${FLASHINFER_BUILD_SUFFIX:-}
RUN git clone https://github.com/flashinfer-ai/flashinfer.git
RUN cd flashinfer && \
    git checkout ${FLASHINFER_REF} && \
    git submodule sync && \
    git submodule update --init --recursive -j 8 && \
    uv build --wheel --no-build-isolation -o /wheels

FROM build-base AS build-lmcache
ARG LMCACHE_REF=v0.3.7
RUN git clone https://github.com/LMCache/LMCache.git -b ${LMCACHE_REF} && \
    cd LMCache && \
    uv pip install setuptools_scm && \
    python -m build --wheel --no-isolation && \
    cp dist/*.whl /wheels/

FROM build-base AS build-vllm
ARG VLLM_REF=v0.11.0
RUN git clone https://github.com/vllm-project/vllm.git
RUN cd vllm && \
    git checkout ${VLLM_REF} && \
    git submodule sync && \
    git submodule update --init --recursive -j 8 && \
    python use_existing_torch.py && \
    uv pip install -r requirements/build.txt && \
    MAX_JOBS=16 uv build --wheel --no-build-isolation -o /wheels

# Build infinistore after vllm to avoid cache invalidation
FROM build-base AS build-infinistore
# Install additional dependencies needed for building infinistore on aarch64
RUN apt update && apt install -y cmake pybind11-dev python3-dev libuv1-dev libspdlog-dev libboost-dev libboost-all-dev meson

# Build flatbuffers from source with proper CMake version
RUN git clone -b v1.12.0 https://github.com/google/flatbuffers.git && \
  cd flatbuffers && \
  cmake -B build -DFLATBUFFERS_BUILD_TESTS=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5 && \
  cmake --build build -j && \
  cmake --install build

# Build InfiniStore from source as a Python package
RUN git clone https://github.com/bytedance/InfiniStore && \
    cd InfiniStore && \
    uv pip install meson && \
    uv pip install --no-deps --no-build-isolation -e . && \
    uv pip uninstall infinistore && \
    python -m build --wheel --no-isolation && \
    cp dist/*.whl /wheels/

FROM base AS vllm-openai
COPY --from=build-flashinfer /wheels/* wheels/
COPY --from=build-triton /wheels/* wheels/
COPY --from=build-vllm /wheels/* wheels/
COPY --from=build-xformers /wheels/* wheels/
COPY --from=build-lmcache /wheels/* wheels/
COPY --from=build-infinistore /wheels/* wheels/

# Install wheels (infinistore is now built as a wheel)
RUN uv pip install wheels/*
RUN rm -r wheels

# Install pynvml
RUN uv pip install pynvml pandas

# Add additional packages for vLLM OpenAI
RUN uv pip install accelerate hf_transfer modelscope bitsandbytes timm boto3 runai-model-streamer runai-model-streamer[s3] tensorizer

# Clean uv cache
RUN uv clean

# python3-config https://github.com/astral-sh/uv/issues/10263
RUN export PATH="$(dirname $(realpath .venv/bin/python)):$PATH"

# Install build tools and dependencies
RUN uv pip install -U build cmake ninja pybind11 setuptools==79.0.1 wheel

# Enable hf-transfer
ENV HF_HUB_ENABLE_HF_TRANSFER=1
RUN uv pip install datasets aiohttp

# Install nsys for profiling
ARG NSYS_URL=https://developer.nvidia.com/downloads/assets/tools/secure/nsight-systems/2025_5/
ARG NSYS_PKG=nsight-systems-cli-2025.5.1_2025.5.1.121-1_arm64.deb
RUN apt-get update && apt install -y wget libglib2.0-0
RUN wget ${NSYS_URL}${NSYS_PKG} && dpkg -i $NSYS_PKG && rm $NSYS_PKG
RUN apt install -y --no-install-recommends tmux cmake

# Deprecated cleanup
RUN uv pip uninstall pynvml && uv pip install nvidia-ml-py

# API server entrypoint
# ENTRYPOINT ["vllm", "serve"]
CMD ["/bin/bash"]
