# Airflow 2.10.3 Docker Application

Airflow 2.10.3 を実行するためのDocker環境です。

## ファイル構成

- `Dockerfile` - Airflowコンテナイメージ定義
- `pyproject.toml` - Poetryの依存パッケージ定義
- `poetry.toml` - Poetry設定（プロジェクト内仮想環境）
- `poetry.lock` - 依存パッケージのロックファイル
- `dags/` - DAG定義ファイルのディレクトリ

## セットアップ手順

1. 依存パッケージをインストール
   ```bash
   poetry install
   ```

2. Dockerイメージをビルド
   ```bash
   docker build -t airflow:2.10.3 .
   ```

3. コンテナを実行
   ```bash
   docker run -it airflow:2.10.3
   ```
