# Airflow オペレーター一覧（Airflow 2系）

オペレーターは**タスクの実行内容を定義する**コンポーネントです。

## 基本オペレーター

| オペレーター | 用途 | インポート |
|-------------|------|-----------|
| `PythonOperator` | Python関数を実行 | `airflow.operators.python` |
| `BashOperator` | Bashコマンドを実行 | `airflow.operators.bash` |
| `EmptyOperator` | 何もしない（ダミー/合流点） | `airflow.operators.empty` |
| `BranchPythonOperator` | 条件分岐 | `airflow.operators.python` |
| `ShortCircuitOperator` | 条件でスキップ | `airflow.operators.python` |
| `TriggerDagRunOperator` | 別DAGをトリガー | `airflow.operators.trigger_dagrun` |

## データ転送・通信系

| オペレーター | 用途 | インポート |
|-------------|------|-----------|
| `EmailOperator` | メール送信 | `airflow.operators.email` |
| `SimpleHttpOperator` | HTTPリクエスト | `airflow.providers.http.operators.http` |
| `SqlOperator` | SQL実行 | `airflow.providers.common.sql.operators.sql` |

## AWS系

要インストール: `apache-airflow-providers-amazon`

| オペレーター | 用途 |
|-------------|------|
| `S3CreateBucketOperator` | S3バケット作成 |
| `S3DeleteObjectsOperator` | S3オブジェクト削除 |
| `S3CopyObjectOperator` | S3オブジェクトコピー |
| `S3ToRedshiftOperator` | S3→Redshiftロード |
| `RedshiftSQLOperator` | Redshift SQL実行 |
| `LambdaInvokeFunctionOperator` | Lambda実行 |
| `GlueJobOperator` | Glueジョブ実行 |
| `AthenaOperator` | Athenaクエリ実行 |
| `EcsRunTaskOperator` | ECSタスク実行 |
| `StepFunctionStartExecutionOperator` | Step Functions実行 |

## GCP系

要インストール: `apache-airflow-providers-google`

| オペレーター | 用途 |
|-------------|------|
| `BigQueryInsertJobOperator` | BigQueryジョブ実行 |
| `BigQueryCreateEmptyTableOperator` | BigQueryテーブル作成 |
| `GCSToBigQueryOperator` | GCS→BigQueryロード |
| `BigQueryToGCSOperator` | BigQuery→GCS出力 |
| `GCSCreateBucketOperator` | GCSバケット作成 |
| `GCSDeleteObjectsOperator` | GCSオブジェクト削除 |
| `DataprocSubmitJobOperator` | Dataprocジョブ実行 |
| `CloudRunExecuteJobOperator` | Cloud Runジョブ実行 |
| `PubSubPublishMessageOperator` | Pub/Subメッセージ送信 |

## 使用例

### PythonOperator

```python
from airflow.operators.python import PythonOperator

def my_function(name):
    print(f"Hello, {name}")
    return "done"

python_task = PythonOperator(
    task_id='python_task',
    python_callable=my_function,
    op_kwargs={'name': 'World'},
)
```

### BashOperator

```python
from airflow.operators.bash import BashOperator

bash_task = BashOperator(
    task_id='bash_task',
    bash_command='echo "Hello World" && date',
)
```

### BranchPythonOperator（条件分岐）

```python
from airflow.operators.python import BranchPythonOperator
from airflow.operators.empty import EmptyOperator

def choose_branch(**context):
    if context['logical_date'].weekday() < 5:
        return 'weekday_task'
    return 'weekend_task'

branch = BranchPythonOperator(
    task_id='branch',
    python_callable=choose_branch,
)

weekday_task = EmptyOperator(task_id='weekday_task')
weekend_task = EmptyOperator(task_id='weekend_task')

branch >> [weekday_task, weekend_task]
```

### TriggerDagRunOperator（別DAGをトリガー）

```python
from airflow.operators.trigger_dagrun import TriggerDagRunOperator

trigger = TriggerDagRunOperator(
    task_id='trigger_other_dag',
    trigger_dag_id='target_dag',
    wait_for_completion=True,
)
```

### SimpleHttpOperator

```python
from airflow.providers.http.operators.http import SimpleHttpOperator

http_task = SimpleHttpOperator(
    task_id='http_task',
    http_conn_id='http_default',
    endpoint='api/data',
    method='GET',
)
```

### S3関連

```python
from airflow.providers.amazon.aws.operators.s3 import (
    S3CreateBucketOperator,
    S3CopyObjectOperator,
)

create_bucket = S3CreateBucketOperator(
    task_id='create_bucket',
    bucket_name='my-bucket',
    aws_conn_id='aws_default',
)

copy_file = S3CopyObjectOperator(
    task_id='copy_file',
    source_bucket_name='source-bucket',
    source_bucket_key='data/input.csv',
    dest_bucket_name='dest-bucket',
    dest_bucket_key='data/output.csv',
    aws_conn_id='aws_default',
)
```

### BigQuery関連

```python
from airflow.providers.google.cloud.operators.bigquery import (
    BigQueryInsertJobOperator,
)

bq_task = BigQueryInsertJobOperator(
    task_id='bq_query',
    configuration={
        'query': {
            'query': 'SELECT * FROM dataset.table',
            'useLegacySql': False,
        }
    },
    gcp_conn_id='google_cloud_default',
)
```

## オペレーターとセンサーの違い

| 種類 | 目的 |
|------|------|
| **オペレーター** | 処理を実行する（データ転送、コマンド実行など） |
| **センサー** | 条件を満たすまで待機する |

センサーもオペレーターの一種ですが、待機に特化しています。
