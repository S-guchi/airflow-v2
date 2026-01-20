# ExternalTaskSensor シンプルガイド

別のDAGのタスク完了を待つセンサーです。

## 基本コード

```python
from airflow import DAG
from airflow.sensors.external_task import ExternalTaskSensor
from airflow.operators.empty import EmptyOperator
from datetime import datetime

with DAG(
    dag_id="my_dag",
    start_date=datetime(2024, 1, 1),
    schedule="@daily",
    catchup=False,
) as dag:

    wait_for_upstream = ExternalTaskSensor(
        task_id="wait_for_upstream",
        external_dag_id="source_dag",       # 待つDAGのID
        external_task_id="source_task",     # 待つタスクのID
        timeout=3600,                       # タイムアウト（秒）
        mode="reschedule",                  # ワーカーを効率的に使う
    )

    my_task = EmptyOperator(task_id="my_task")

    wait_for_upstream >> my_task
```

## 最低限のパラメータ

| パラメータ | 説明 |
|-----------|------|
| `external_dag_id` | 待機対象のDAG ID |
| `external_task_id` | 待機対象のタスク ID |
| `timeout` | タイムアウト秒数（設定推奨） |
| `mode` | `"reschedule"` 推奨 |
