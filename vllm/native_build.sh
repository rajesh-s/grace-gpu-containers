curl -LsSf https://astral.sh/uv/install.sh | export UV_INSTALL_DIR=/usr/local/bin sh
mkdir vllm-build && cd vllm-build
uv vexport -p ${PYTHON_VERSION} --seed --python-preference only-managed
source .vexport/bin/activate

export CUDA_VERSION=12.6.3
export IMAGE_DISTRO=ubuntu24.04
export PYTHON_VERSION=3.12
export TORCH_CUDA_ARCH_LIST="9.0a"
export TORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST}
export VLLM_FA_CMAKE_GPU_ARCHES="90a-real"
export VLLM_FA_CMAKE_GPU_ARCHES=${VLLM_FA_CMAKE_GPU_ARCHES}

uv pip install numpy==2.0.0 
uv pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu126 
uv pip install build cmake ninja pybind11 setuptools wheel

mkdir wheels

# triton-lang
export TRITON_REF=release/3.2.x
export TRITON_BUILD_SUFFIX=+cu126
export TRITON_WHEEL_VERSION_SUFFIX=${TRITON_BUILD_SUFFIX:-}
git clone https://github.com/triton-lang/triton.git
cd triton && \
    git checkout ${TRITON_REF} && \
    git submodule sync && \
    git submodule update --init --recursive -j 8 && \
    uv build python --wheel --no-build-isolation -o ../wheels
cd ..

# xformers
export MAX_JOBS=10
export XFORMERS_REF=v0.0.29.post2
export XFORMERS_BUILD_VERSION=0.0.29.post2+cu126
export BUILD_VERSION=${XFORMERS_BUILD_VERSION:-${XFORMERS_REF#v}}
git clone  https://github.com/facebookresearch/xformers.git
cd xformers && \
    git checkout ${XFORMERS_REF} && \
    git submodule sync && \
    git submodule update --init --recursive -j 8 && \
    uv build --wheel --no-build-isolation -o ../wheels
cd ..

# flashinfer
export FLASHINFER_ENABLE_AOT=1
export FLASHINFER_REF=v0.2.2.post1
export FLASHINFER_BUILD_SUFFIX=cu126
export FLASHINFER_LOCAL_VERSION=${FLASHINFER_BUILD_SUFFIX:-}
uv pip install setuptools==75.6.0 packaging==23.2 ninja==1.11.1.3 build==1.2.2.post1
git clone https://github.com/flashinfer-ai/flashinfer.git
cd flashinfer && \
    git checkout ${FLASHINFER_REF} && \
    git submodule sync && \
    git submodule update --init --recursive -j 8 && \
    uv build --wheel --no-build-isolation -o ../wheels && cd ..

uv pip install wheels/*
uv pip install pynvml pandas accelerate hf_transfer modelscope bitsandbytes timm boto3 runai-model-streamer runai-model-streamer[s3] tensorizer

git clone https://github.com/Dao-AILab/flash-attention.git && cd flash-attention
FLASH_ATTENTION_TRITON_AMD_ENABLE="TRUE" MAX_JOBS=10 python setup.py install
cd hopper && FLASH_ATTENTION_TRITON_AMD_ENABLE="TRUE" MAX_JOBS=5 python setup.py install



# vllm
export VLLM_REF=v0.8.1
export MAX_JOBS=4
export CUDACXX=/home1/apps/nvidia/Linux_aarch64/24.9/cuda/12.6/bin/nvcc
git clone https://github.com/vllm-project/vllm.git
cd vllm && \
    git checkout ${VLLM_REF} && \
    git submodule sync && \
    git submodule update --init --recursive -j 8 && \
    uv pip install -r requirements/build.txt && \
    uv build --wheel --no-build-isolation -o ../wheels && cd ..



