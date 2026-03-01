#!/bin/bash

# =============================================================================
# Скрипт для установки нод и скачивания моделей ПОСЛЕ запуска ComfyUI
# =============================================================================

curl -fsSL https://raw.githubusercontent.com/vast-ai/base-image/refs/heads/main/derivatives/pytorch/derivatives/comfyui/provisioning_scripts/default.sh | bash

echo "=== Запуск пользовательского скрипта ==="

# Путь к ComfyUI
COMFYUI_DIR="/workspace/ComfyUI"
CUSTOM_NODES_DIR="$COMFYUI_DIR/custom_nodes"
MODELS_DIR="$COMFYUI_DIR/models"

# Максимальное ожидание ComfyUI — 10 минут
MAX_WAIT=600
WAITED=0

echo "Ждём запуска ComfyUI на порту 18188..."
while [ $WAITED -lt $MAX_WAIT ]; do
    if curl -s -f http://localhost:18188 > /dev/null 2>&1; then
        echo "ComfyUI запущен! Продолжаем..."
        break
    fi
    echo "ComfyUI ещё не готов... ждём 10 секунд ($WAITED/$MAX_WAIT)"
    sleep 10
    WAITED=$((WAITED + 10))
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo "Ошибка: ComfyUI не запустился за 10 минут. Выход."
    exit 1
fi

# Активируем виртуальное окружение (на всякий случай)
source /venv/main/bin/activate 2>/dev/null || echo "Виртуальное окружение не найдено, продолжаем без активации"

# =============================================================================
# Установка custom nodes
# =============================================================================

echo "=== Установка custom nodes ==="

cd "$CUSTOM_NODES_DIR" || { echo "Папка custom_nodes не найдена!"; exit 1; }

# Список нод, которые нужно установить
declare -A NODES=(
    ["ComfyUI-KJNodes"]="https://github.com/kijai/ComfyUI-KJNodes"
    # Добавь сюда другие ноды, если нужно, например:
    # ["ComfyUI-Reactor"]="https://github.com/Gourieff/comfyui-reactor-node"
    # ["ComfyUI-IPAdapter_plus"]="https://github.com/cubiq/ComfyUI_IPAdapter_plus"
)

for node_name in "${!NODES[@]}"; do
    repo_url="${NODES[$node_name]}"
    node_path="$CUSTOM_NODES_DIR/$node_name"

    if [ -d "$node_path" ]; then
        echo "Нода $node_name уже существует → обновляем..."
        cd "$node_path"
        git pull --ff-only || echo "Не удалось обновить $node_name"
    else
        echo "Устанавливаем ноду $node_name..."
        git clone "$repo_url" "$node_name"
        cd "$node_path"
    fi

    # Установка зависимостей, если есть requirements.txt
    if [ -f "requirements.txt" ]; then
        echo "Устанавливаем зависимости для $node_name..."
        pip install -r requirements.txt --no-cache-dir || \
        pip install -r requirements.txt --no-deps --no-cache-dir || \
        echo "Не удалось установить зависимости для $node_name"
    fi

    cd "$CUSTOM_NODES_DIR"
done

echo "Установка нод завершена."

# =============================================================================
# Создаём папки для моделей (если ещё нет)
# =============================================================================

mkdir -p "$MODELS_DIR"/{checkpoints,diffusion_models,unet,loras,vae,text_encoders}

# =============================================================================
# Скачивание моделей
# =============================================================================

echo "=== Скачивание моделей ==="

cd "$MODELS_DIR" || exit 1

# 1. Основная модель
echo "→ Qwen-Image-Edit-2511-FP8_e4m3fn.safetensors"
[ ! -s diffusion_models/Qwen-Image-Edit-2511-FP8_e4m3fn.safetensors ] && \
wget --continue -O diffusion_models/Qwen-Image-Edit-2511-FP8_e4m3fn.safetensors \
  "https://huggingface.co/1038lab/Qwen-Image-Edit-2511-FP8/resolve/main/Qwen-Image-Edit-2511-FP8_e4m3fn.safetensors"

# 2. LoRA Lightning 4 steps
echo "→ Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors"
[ ! -s loras/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors ] && \
wget --continue -O loras/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors \
  "https://huggingface.co/lightx2v/Qwen-Image-Edit-2511-Lightning/resolve/main/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors"

# 3. LoRA bfs_head_swap
echo "→ bfs_head_v5_2511_merged_version_rank_16_fp16.safetensors"
[ ! -s loras/bfs_head_v5_2511_merged_version_rank_16_fp16.safetensors ] && \
wget --continue -O loras/bfs_head_v5_2511_merged_version_rank_16_fp16.safetensors \
  "https://huggingface.co/GerbyHorty76/bfs_head_swap/resolve/main/bfs_head_v5_2511_merged_version_rank_16_fp16.safetensors"

# 4. VAE qwen_image_vae
echo "→ qwen_image_vae.safetensors"
[ ! -s vae/qwen_image_vae.safetensors ] && \
wget --continue -O vae/qwen_image_vae.safetensors \
  "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors"

# 5. VAE ae (для Z-Image-Turbo)
echo "→ ae.safetensors"
[ ! -s vae/ae.safetensors ] && \
wget --continue -O vae/ae.safetensors \
  "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors?download=true"

# 6. Text Encoders
echo "→ qwen_3_4b.safetensors"
[ ! -s text_encoders/qwen_3_4b.safetensors ] && \
wget --continue -O text_encoders/qwen_3_4b.safetensors \
  "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors?download=true"

echo "→ qwen_2.5_vl_7b_fp8_scaled.safetensors"
[ ! -s text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors ] && \
wget --continue -O text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors \
  "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"

# 7. Civitai Zimage Turbo NSFW (с твоим токеном)
CIVITAI_TOKEN="286e8ec5eab4ab91ebf800c88b612d68"
echo "→ zimage-turbo-nsfw-2602-bf16.safetensors (Civitai)"
[ ! -s checkpoints/zimage-turbo-nsfw-2602-bf16.safetensors ] && \
wget --continue -O checkpoints/zimage-turbo-nsfw-2602-bf16.safetensors \
  "https://civitai.com/api/download/models/2668773?type=Model&format=SafeTensor&size=full&fp=bf16&token=$CIVITAI_TOKEN"

echo "=== Все операции завершены ==="
echo "Можешь проверить папки и запустить workflow."
