# M1 Mac上で動作するx86機械学習環境

本番環境(x86)との互換性を保ちながらM1 Mac上で開発できる機械学習環境のDockerセットアップです。Rosetta 2エミュレーションを活用したx86 Dockerコンテナを使用しています。

## 特徴

- **x86互換性**: 本番環境と同じx86アーキテクチャで動作
- **PyTorch対応**: x86版PyTorch 2.5.1がプリインストール済み
- **Jupyter Lab統合**: データ分析作業用のJupyter Lab環境
- **簡単セットアップ**: スクリプト一発で環境構築
- **自動管理**: ファイル変更検知による自動リビルド機能

## クイックスタート

```bash
# リポジトリをクローン
git clone https://github.com/あなたのユーザー名/リポジトリ名.git
cd リポジトリ名

# 実行権限を付与
chmod +x start_container.sh start_jupyter.sh

# データディレクトリを作成
mkdir -p docker_data

# コンテナを起動
./start_container.sh
```

## 前提条件

- M1/M2/M3 Mac（Apple Silicon）
- Docker Desktop for Mac
- Docker DesktopでRosetta 2エミュレーションが有効化されていること

## ディレクトリ構造

```
.
├── Dockerfile              # x86環境の定義
├── docker_files_hash       # Dockerfile差分検査用のハッシュファイル
├── docker-compose.yml      # Docker Compose設定
├── start_container.sh      # 環境起動スクリプト
├── start_jupyter.sh        # Jupyter Lab起動スクリプト
└── docker_data/            # データ共有ディレクトリ
```

## ライセンス
MITライセンス

## 貢献

問題報告や機能リクエストは、GitHubのIssuesで受け付けています。Pull Requestも歓迎します。