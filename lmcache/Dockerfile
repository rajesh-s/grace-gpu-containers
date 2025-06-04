ARG CUDA_VERSION=12.8.1
ARG IMAGE_DISTRO=ubuntu24.04
ARG PYTHON_VERSION=3.12

# ---------- Builder Base ----------
FROM nvcr.io/nvidia/cuda:${CUDA_VERSION}-devel-${IMAGE_DISTRO} AS base

ARG TORCH_CUDA_ARCH_LIST="9.0a"
ENV TORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST}
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt update && apt upgrade -y && \
    apt install -y --no-install-recommends \
        curl \
        git \
        libibverbs-dev \
        zlib1g-dev && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

# Set compiler paths
ENV CC=/usr/bin/gcc
ENV CXX=/usr/bin/g++

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

# Set up workspace and virtualenv
WORKDIR /workspace
ARG PYTHON_VERSION
RUN uv venv -p ${PYTHON_VERSION} --seed --python-preference only-managed

# Activate uv venv
ENV VIRTUAL_ENV=/workspace/.venv
ENV PATH=${VIRTUAL_ENV}/bin:${PATH}
ENV CUDA_HOME=/usr/local/cuda
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}

# Install Python deps in venv
RUN uv pip install numpy==2.0.0
RUN uv pip install torch==2.7.0 torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu128

FROM base AS build-base

# Install build tools and dependencies
RUN uv pip install -U build cmake ninja pybind11 setuptools==79.0.1 wheel

# Clone and build LMCache wheel
RUN git clone https://github.com/rajesh-s/LMCache.git -b v0.3.0 && \
    cd LMCache && \
    uv pip install setuptools_scm && \
    python -m build --wheel --no-isolation && \
    cp dist/*.whl /workspace/

CMD ["/bin/bash"]