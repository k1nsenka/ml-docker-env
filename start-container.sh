#!/bin/bash

# エラーが発生した時点でスクリプトを終了
set -e

# スクリプトの実行ディレクトリに移動
cd "$(dirname "$0")"

# ハッシュファイルの保存場所
HASH_FILE=".docker_files_hash"

# bashrcの設定内容
BASHRC_CONTENT='
# カラー設定
export PS1="\[\033[38;5;040m\]\u\[\033[38;5;243m\]@\[\033[38;5;033m\]\h\[\033[38;5;243m\]:\[\033[38;5;045m\]\w\[\033[38;5;243m\]\\$ \[\033[0m\]"

# ls コマンドの色設定
export LS_COLORS="di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"
alias ls="ls --color=auto"

# その他のエイリアス
alias ll="ls -la"
alias l="ls -l"
'

# 不要なイメージを削除
cleanup_images() {
    echo "Checking for unused Docker images..."
    
    # <none>タグのイメージを取得
    NONE_IMAGES=$(docker images -f "dangling=true" -q)
    
    if [ ! -z "$NONE_IMAGES" ]; then
        echo "Found unused images. Removing..."
        docker rmi $NONE_IMAGES 2>/dev/null || true
        echo "Cleanup complete."
    else
        echo "No unused images found."
    fi
}

# コンテナの状態確認
container_status() {
    docker-compose ps --quiet ml_env
}

# Dockerファイルのハッシュを計算
calculate_hash() {
    find . -type f \( -name "Dockerfile" -o -name "docker-compose.yml" \) -exec sha256sum {} \; | sort > "${HASH_FILE}.new"
}

# ファイルの変更を確認
check_files_changed() {
    if [ ! -f "$HASH_FILE" ]; then
        return 0
    fi
    
    calculate_hash
    if ! diff -q "${HASH_FILE}.new" "$HASH_FILE" >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# ハッシュファイルを更新
update_hash() {
    mv "${HASH_FILE}.new" "$HASH_FILE"
}

# シェルの設定を更新
setup_shell() {
    echo "Setting up colored shell prompt..."
    docker-compose exec ml_env bash -c "echo '$BASHRC_CONTENT' > ~/.bashrc"
}

# Jupyterの起動
start_jupyter() {
    echo "Starting JupyterLab..."
    docker-compose exec -d ml_env bash -c "jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token=''"
    echo "JupyterLab started. Access at http://localhost:8888"
}

# メイン処理
main() {
    # 不要なイメージを削除
    cleanup_images
    
    echo "Checking for Docker file changes..."
    
    # Dockerファイルの変更をチェック
    if check_files_changed; then
        echo "Docker files have changed. Rebuilding container..."
        docker-compose down
        docker-compose build
        update_hash
        echo "Rebuild complete."
        
        # ビルド後に再度クリーンアップを実行
        cleanup_images
    fi
    
    echo "Starting Docker container..."
    
    # コンテナが存在するか確認
    if [ -z "$(container_status)" ]; then
        echo "Container not found. Starting new container..."
        docker-compose up -d
        
        # コンテナの起動を待機
        echo "Waiting for container to be ready..."
        sleep 5
        
        # 新規コンテナの場合はシェル設定を実行
        setup_shell
    else
        # コンテナが停止している場合は起動
        if ! docker-compose ps | grep -q "Up" | grep "ml_env"; then
            echo "Container exists but is not running. Starting container..."
            docker-compose start
            sleep 5
        fi
    fi
    
    # コンテナの状態を確認
    if [ -z "$(container_status)" ]; then
        echo "Failed to start container. Please check docker-compose.yml and try again."
        exit 1
    fi
    
    # Jupyterを起動するか尋ねる
    read -p "Do you want to start JupyterLab? [y/N]: " START_JUPYTER
    if [[ "$START_JUPYTER" =~ ^[Yy]$ ]]; then
        start_jupyter
    fi
    
    echo "Connecting to container..."
    docker-compose exec ml_env /bin/bash --login
}

# スクリプト実行
main