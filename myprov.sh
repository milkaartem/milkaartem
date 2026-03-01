#!/bin/bash

# Сначала дефолтный provisioning
curl -fsSL https://raw.githubusercontent.com/vast-ai/base-image/refs/heads/main/derivatives/pytorch/derivatives/comfyui/provisioning_scripts/default.sh | bash

echo "=== Запуск пользовательского скрипта ==="

COMFYUI_DIR="/workspace/ComfyUI"
CUSTOM_NODES_DIR="$COMFYUI_DIR/custom_nodes"
MODELS_DIR="$COMFYUI_DIR/models"



# =============================================================================
# Скачивание моделей
# =============================================================================
mkdir -p "$MODELS_DIR"/{checkpoints,diffusion_models,unet,loras,vae,text_encoders}

echo "=== Скачивание моделей ==="
cd "$MODELS_DIR" || exit 1

echo "→ Qwen-Image-Edit-2511-FP8_e4m3fn.safetensors"
[ ! -s diffusion_models/Qwen-Image-Edit-2511-FP8_e4m3fn.safetensors ] && \
wget --continue -O diffusion_models/Qwen-Image-Edit-2511-FP8_e4m3fn.safetensors \
  "https://huggingface.co/1038lab/Qwen-Image-Edit-2511-FP8/resolve/main/Qwen-Image-Edit-2511-FP8_e4m3fn.safetensors"

echo "→ Qwen Lightning LoRA"
[ ! -s loras/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors ] && \
wget --continue -O loras/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors \
  "https://huggingface.co/lightx2v/Qwen-Image-Edit-2511-Lightning/resolve/main/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors"

echo "→ bfs_head_swap LoRA"
[ ! -s loras/bfs_head_v5_2511_merged_version_rank_16_fp16.safetensors ] && \
wget --continue -O loras/bfs_head_v5_2511_merged_version_rank_16_fp16.safetensors \
  "https://huggingface.co/GerbyHorty76/bfs_head_swap/resolve/main/bfs_head_v5_2511_merged_version_rank_16_fp16.safetensors"

echo "→ qwen_image_vae.safetensors"
[ ! -s vae/qwen_image_vae.safetensors ] && \
wget --continue -O vae/qwen_image_vae.safetensors \
  "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors"

echo "→ ae.safetensors"
[ ! -s vae/ae.safetensors ] && \
wget --continue -O vae/ae.safetensors \
  "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors?download=true"

echo "→ qwen_3_4b.safetensors"
[ ! -s text_encoders/qwen_3_4b.safetensors ] && \
wget --continue -O text_encoders/qwen_3_4b.safetensors \
  "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors?download=true"

echo "→ qwen_2.5_vl_7b_fp8_scaled.safetensors"
[ ! -s text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors ] && \
wget --continue -O text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors \
  "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"

CIVITAI_TOKEN="286e8ec5eab4ab91ebf800c88b612d68"
echo "→ zimage-turbo-nsfw (Civitai)"
[ ! -s checkpoints/reazit.safetensors ] && \
wget --continue -O checkpoints/reazit.safetensors \
  "https://civitai.com/api/download/models/2689145?type=Model&format=SafeTensor&size=full&fp=fp16&token=$CIVITAI_TOKEN"

echo "=== Все операции завершены ==="
