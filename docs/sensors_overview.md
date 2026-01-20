# Airflow センサー一覧（Airflow 2系）

センサーは**特定の条件が満たされるまで待機する**特殊なオペレーターです。

## よく使うセンサー

| センサー | 用途 | インポート |
|---------|------|-----------|
| `ExternalTaskSensor` | 別DAGのタスク完了を待つ | `airflow.sensors.external_task` |
| `FileSensor` | ファイルの存在を待つ | `airflow.sensors.filesystem` |
| `TimeSensor` | 指定時刻まで待つ | `airflow.sensors.time_sensor` |
| `TimeDeltaSensor` | 指定時間経過を待つ | `airflow.sensors.time_delta` |
| `PythonSensor` | Python関数がTrueを返すまで待つ | `airflow.sensors.python` |
| `HttpSensor` | HTTPエンドポイントの応答を待つ | `airflow.providers.http.sensors.http` |
| `SqlSensor` | SQLクエリが条件を満たすまで待つ | `airflow.providers.common.sql.sensors.sql` |

## クラウド系センサー（AWS）

要インストール: `apache-airflow-providers-amazon`

| センサー | 用途 |
|---------|------|
| `S3KeySensor` | S3オブジェクトの存在 |
| `S3KeysUnchangedSensor` | S3オブジェクトが変更されなくなるまで待つ |
| `SqsSensor` | SQSメッセージの受信 |
| `RedshiftClusterSensor` | Redshiftクラスタの状態 |
| `GlueCatalogPartitionSensor` | Glueパーティションの存在 |

## クラウド系センサー（GCP）

要インストール: `apache-airflow-providers-google`

| センサー | 用途 |
|---------|------|
| `GCSObjectExistenceSensor` | GCSオブジェクトの存在 |
| `GCSObjectsWithPrefixExistenceSensor` | 特定プレフィックスのオブジェクト存在 |
| `BigQueryTableExistenceSensor` | BigQueryテーブルの存在 |
| `PubSubPullSensor` | Pub/Subメッセージの受信 |

## 使用例

### FileSensor

```python
from airflow.sensors.filesystem import FileSensor

FileSensor(
    task_id="wait_for_file",
    filepath="/data/input.csv",
    poke_interval=60,
    timeout=3600,
    mode="reschedule",
)
```

### TimeSensor

```python
from airflow.sensors.time_sensor import TimeSensor
from datetime import time

TimeSensor(
    task_id="wait_until_6am",
    target_time=time(6, 0),
)
```

### PythonSensor

```python
from airflow.sensors.python import PythonSensor

def check_condition():
    # 条件を満たせばTrue
    return some_condition()

PythonSensor(
    task_id="wait_custom",
    python_callable=check_condition,
    poke_interval=60,
)
```

### S3KeySensor

```python
from airflow.providers.amazon.aws.sensors.s3 import S3KeySensor

S3KeySensor(
    task_id="wait_for_s3_file",
    bucket_name="my-bucket",
    bucket_key="data/input.csv",
    aws_conn_id="aws_default",
    poke_interval=60,
    timeout=3600,
)
```

### HttpSensor

```python
from airflow.providers.http.sensors.http import HttpSensor

HttpSensor(
    task_id="wait_for_api",
    http_conn_id="http_default",
    endpoint="health",
    response_check=lambda response: response.status_code == 200,
    poke_interval=60,
)
```

### SqlSensor

```python
from airflow.providers.common.sql.sensors.sql import SqlSensor

SqlSensor(
    task_id="wait_for_data",
    conn_id="postgres_default",
    sql="SELECT COUNT(*) FROM my_table WHERE date = '{{ ds }}'",
    poke_interval=60,
)
```

## 共通パラメータ

全センサーで使える主要パラメータ:

| パラメータ | デフォルト | 説明 |
|-----------|-----------|------|
| `poke_interval` | 30 | チェック間隔（秒） |
| `timeout` | 604800 | タイムアウト（秒）※7日 |
| `mode` | `"poke"` | `"poke"` or `"reschedule"` |
| `soft_fail` | False | タイムアウト時にスキップ扱いにする |
| `deferrable` | False | Deferrableモード（2.6+） |

## mode の選び方

- **poke**: 短時間で完了が見込まれる場合（ワーカー占有）
- **reschedule**: 長時間待機が見込まれる場合（ワーカー解放、推奨）
