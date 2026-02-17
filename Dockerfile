FROM rust:1.93-trixie

# TUI開発に必要なシステム依存関係のインストール
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    git \
    curl \
    ripgrep \
    # TUI/ターミナル制御に関連するライブラリ
    libncurses5-dev \
    libncursesw5-dev \
    # デバッグ用
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Rustツールチェーンの拡張
RUN rustup component add rust-analyzer rustfmt clippy

# Cargoツールのインストール（root権限で実行）
RUN cargo install bacon

# Claude Code のインストール
RUN curl -fsSL https://claude.ai/install.sh | sh

# 作業ディレクトリの設定
WORKDIR /app

# 開発用ユーザーの作成（権限トラブル防止）
RUN useradd -m -s /bin/bash claude_dev
USER claude_dev
