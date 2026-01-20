# ExternalTaskSensor 使い方ガイド（Airflow 2系）

## 概要

`ExternalTaskSensor`は、**別のDAGのタスク完了を待機する**ためのセンサーです。
DAG間で依存関係を作りたいときに使用します。

```
DAG A (source_dag)          DAG B (dependent_dag)
┌─────────────────┐         ┌─────────────────────────┐
│  source_task    │ ──────► │  ExternalTaskSensor     │
│  (完了を待つ)    │         │  ↓                      │
└─────────────────┘         │  downstream_task        │
                            └─────────────────────────┘
```

## インポート

```python
from airflow.sensors.external_task import ExternalTaskSensor
```

## 基本的な使い方

```python
from airflow import DAG
from airflow.sensors.external_task import ExternalTaskSensor
from airflow.operators.empty import EmptyOperator
from datetime import datetime

with DAG(
    dag_id="dependent_dag",
    start_date=datetime(2024, 1, 1),
    schedule="@daily",
    catchup=False,
) as dag:

    # 別DAGのタスク完了を待つ
    wait_for_upstream = ExternalTaskSensor(
        task_id="wait_for_upstream",
        external_dag_id="source_dag",      # 待機対象のDAG ID
        external_task_id="source_task",    # 待機対象のタスク ID
        poke_interval=60,                  # 60秒ごとにチェック
        timeout=3600,                      # 1時間でタイムアウト
        mode="reschedule",                 # リソース効率の良いモード
    )

    downstream_task = EmptyOperator(task_id="downstream_task")

    wait_for_upstream >> downstream_task
```

## 主要パラメータ一覧

| パラメータ | 必須 | デフォルト | 説明 |
|-----------|:----:|-----------|------|
| `external_dag_id` | ✓ | - | 待機対象のDAG ID |
| `external_task_id` | - | None | 待機対象のタスク ID（省略時はDAG全体の完了を待つ） |
| `external_task_group_id` | - | None | 待機対象のタスクグループ ID |
| `allowed_states` | - | `["success"]` | 成功とみなす状態のリスト |
| `failed_states` | - | `[]` | 失敗とみなす状態のリスト |
| `execution_delta` | - | None | 実行日時の差分（timedelta） |
| `execution_date_fn` | - | None | 実行日時を動的に計算する関数 |
| `poke_interval` | - | 30 | チェック間隔（秒） |
| `timeout` | - | 604800 | タイムアウト時間（秒）※デフォルト7日 |
| `mode` | - | `"poke"` | 動作モード（`"poke"` or `"reschedule"`） |
| `deferrable` | - | False | Deferrable モードの有効化 |

## パラメータ詳細

### mode（動作モード）

```python
# poke モード（デフォルト）
# - ワーカースロットを占有し続ける
# - 短時間で完了が見込まれる場合に使用
ExternalTaskSensor(
    task_id="wait_poke",
    external_dag_id="source_dag",
    external_task_id="source_task",
    mode="poke",
)

# reschedule モード（推奨）
# - チェック後にワーカースロットを解放
# - 長時間待機が見込まれる場合に使用
ExternalTaskSensor(
    task_id="wait_reschedule",
    external_dag_id="source_dag",
    external_task_id="source_task",
    mode="reschedule",
    poke_interval=300,  # 5分ごとにチェック
)
```

### allowed_states / failed_states

```python
ExternalTaskSensor(
    task_id="wait_with_states",
    external_dag_id="source_dag",
    external_task_id="source_task",
    allowed_states=["success", "skipped"],  # これらの状態で成功判定
    failed_states=["failed"],               # この状態で即座に失敗
)
```

### execution_delta（実行日時の差分）

スケジュールが異なるDAG間で依存関係を作る場合に使用します。

```python
from datetime import timedelta

# 例: 毎時実行のDAGが、前日の日次DAGを待つ場合
ExternalTaskSensor(
    task_id="wait_for_yesterday",
    external_dag_id="daily_dag",
    external_task_id="daily_task",
    execution_delta=timedelta(days=1),  # 1日前の実行を待つ
)
```

### execution_date_fn（動的な実行日時）

より複雑な実行日時の計算が必要な場合に使用します。

```python
from datetime import timedelta

# 前日の実行を待つ
ExternalTaskSensor(
    task_id="wait_dynamic",
    external_dag_id="source_dag",
    external_task_id="source_task",
    execution_date_fn=lambda dt: dt - timedelta(days=1),
)

# 週の初め（月曜日）の実行を待つ
def get_monday(dt):
    return dt - timedelta(days=dt.weekday())

ExternalTaskSensor(
    task_id="wait_for_monday",
    external_dag_id="weekly_dag",
    external_task_id="weekly_task",
    execution_date_fn=get_monday,
)
```

> **注意**: `execution_delta` と `execution_date_fn` は同時に指定できません。

### deferrable（Deferrable モード）

Airflow 2.6以降で利用可能。Triggererを使用してリソース効率を最大化します。

```python
ExternalTaskSensor(
    task_id="wait_deferrable",
    external_dag_id="source_dag",
    external_task_id="source_task",
    deferrable=True,
)
```

## 実践的なユースケース

### 1. DAG全体の完了を待つ

```python
# external_task_id を省略すると、DAG全体の完了を待つ
ExternalTaskSensor(
    task_id="wait_for_entire_dag",
    external_dag_id="source_dag",
    timeout=7200,
    mode="reschedule",
)
```

### 2. タスクグループの完了を待つ

```python
ExternalTaskSensor(
    task_id="wait_for_task_group",
    external_dag_id="source_dag",
    external_task_group_id="etl_group",  # タスクグループIDを指定
    timeout=3600,
    mode="reschedule",
)
```

### 3. 複数DAGからの依存

```python
wait_for_dag_a = ExternalTaskSensor(
    task_id="wait_for_dag_a",
    external_dag_id="dag_a",
    external_task_id="final_task",
    mode="reschedule",
)

wait_for_dag_b = ExternalTaskSensor(
    task_id="wait_for_dag_b",
    external_dag_id="dag_b",
    external_task_id="final_task",
    mode="reschedule",
)

process_task = EmptyOperator(task_id="process_task")

[wait_for_dag_a, wait_for_dag_b] >> process_task
```

## ExternalTaskMarker との連携

`ExternalTaskMarker`を使うと、親タスクをクリアした際に子タスクも自動的にクリアできます。

### 親DAG（source_dag）

```python
from airflow.sensors.external_task import ExternalTaskMarker

with DAG(dag_id="source_dag", ...) as dag:

    source_task = EmptyOperator(task_id="source_task")

    # 子DAGとの依存関係をマーク
    marker = ExternalTaskMarker(
        task_id="marker_for_child",
        external_dag_id="dependent_dag",
        external_task_id="wait_for_upstream",
    )

    source_task >> marker
```

### 子DAG（dependent_dag）

```python
with DAG(dag_id="dependent_dag", ...) as dag:

    wait_for_upstream = ExternalTaskSensor(
        task_id="wait_for_upstream",
        external_dag_id="source_dag",
        external_task_id="source_task",
    )

    downstream_task = EmptyOperator(task_id="downstream_task")

    wait_for_upstream >> downstream_task
```

これにより、`source_dag`の`source_task`をクリアすると、`dependent_dag`の`wait_for_upstream`も自動的にクリアされます。

## ベストプラクティス

1. **mode="reschedule" を使用する**
   長時間の待機が予想される場合、ワーカーリソースを効率的に使用できます。

2. **適切なtimeoutを設定する**
   デフォルトの7日間は長すぎる場合が多いです。業務要件に合わせて設定しましょう。

3. **failed_statesを活用する**
   上流タスクが失敗した場合に即座に検知できます。

4. **ExternalTaskMarkerと併用する**
   再実行時の運用が楽になります。

5. **poke_intervalを適切に設定する**
   頻繁すぎるチェックはDBに負荷をかけます。通常は60〜300秒程度が適切です。

## トラブルシューティング

### センサーがタイムアウトする

- 上流DAGのスケジュールと`execution_delta`/`execution_date_fn`が正しく設定されているか確認
- 上流タスクが実際に実行されているか確認
- `allowed_states`に期待する状態が含まれているか確認

### 実行日時が一致しない

Airflowの`execution_date`（Airflow 2.2以降は`logical_date`）は**スケジュール間隔の開始時刻**です。
異なるスケジュールのDAG間では`execution_delta`または`execution_date_fn`で調整が必要です。

## 参考リンク

- [Apache Airflow 公式ドキュメント - Cross-DAG Dependencies](https://airflow.apache.org/docs/apache-airflow-providers-standard/stable/sensors/external_task_sensor.html)
- [Apache Airflow 公式ドキュメント - Sensors](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/sensors.html)
