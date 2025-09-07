FROM nvcr.io/nvidia/pytorch:25.08-py3

WORKDIR /workspace

ARG COMFYUI_VERSION=0.3.57
ARG HF_ENDPOINT=https://hf-mirror.com
ARG HF_HOME=/root/.cache/huggingface
ENV HF_HUB_OFFLINE=1

# ------------------------------
# 1. Aliyun mirrors for Ubuntu
# ------------------------------
RUN sed -i 's|archive.ubuntu.com|mirrors.aliyun.com|g' /etc/apt/sources.list.d/ubuntu.sources \
    && sed -i 's|security.ubuntu.com|mirrors.aliyun.com|g' /etc/apt/sources.list.d/ubuntu.sources

# ------------------------------
# 2. Configure Pip mirrors (Tsinghua + PyTorch/NVIDIA extra)
# ------------------------------
RUN mkdir -p /root/.pip && \
    echo "[global]" > /root/.pip/pip.conf && \
    echo "index-url = http://mirrors.aliyun.com/pypi/simple/" >> /root/.pip/pip.conf && \
    echo "extra-index-url =" >> /root/.pip/pip.conf && \
    echo "    https://mirrors.aliyun.com/pytorch-wheels" >> /root/.pip/pip.conf && \
    echo "    https://pypi.ngc.nvidia.com" >> /root/.pip/pip.conf && \
    pip config set global.trusted-host mirrors.aliyun.com

# ------------------------------
# 3. Download and extract Stable Diffusion source
# ------------------------------
RUN mkdir -p ./comfyui && \
    wget -O- https://github.com/comfyanonymous/ComfyUI/archive/refs/tags/v${COMFYUI_VERSION}.tar.gz | \
    tar zxvf - --strip-components=1 -C comfyui
WORKDIR /workspace/comfyui

# Plugins
ARG COMFYUI_MANAGER_VERSION=3.35
ARG NUNCHAKU_VERSION=1.0.0
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    --mount=type=cache,target=/root/.cache/pip \
    --mount=type=cache,target=/root/.cache/huggingface \
    mkdir -p ./custom_nodes/{comfyui-manager,nunchaku_nodes} && \
    wget -O- https://github.com/Comfy-Org/ComfyUI-Manager/archive/refs/tags/${COMFYUI_MANAGER_VERSION}.tar.gz | \
    tar zxvf - --strip-components=1 -C ./custom_nodes/comfyui-manager && \
    wget -O- https://github.com/nunchaku-tech/ComfyUI-nunchaku/archive/refs/tags/v${NUNCHAKU_VERSION}.tar.gz | \
    tar zxvf - --strip-components=1 -C ./custom_nodes/nunchaku_nodes && \
    for req in ./custom_nodes/*/requirements.txt; do \
        [ -f "$req" ] && pip install -r "$req"; \
    done

# ------------------------------
# 4. Install environment deps
# ------------------------------
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    --mount=type=cache,target=/root/.cache/pip \
    --mount=type=cache,target=/root/.cache/huggingface \
    apt-get update && apt-get install -y --no-install-recommends \
        libgl1 && \
    pip install -r requirements.txt && \
    pip install https://modelscope.cn/models/nunchaku-tech/nunchaku/resolve/master/nunchaku-${NUNCHAKU_VERSION}+torch2.8-cp312-cp312-linux_x86_64.whl && \
    pip uninstall -y flash-attn && \
    pip install -U --use-pep517 --no-build-isolation --no-cache-dir "git+https://github.com/Dao-AILab/flash-attention.git"

## ------------------------------
## 5. Default entrypoint
## ------------------------------
ADD ./entrypoint.sh ./
ENTRYPOINT ["./entrypoint.sh"]

CMD ["python", "main.py", "--listen", "0.0.0.0", "--preview-method", "auto", "--normalvram", "--disable-smart-memory"]
