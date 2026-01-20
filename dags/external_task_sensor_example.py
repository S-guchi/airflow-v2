from datetime import datetime, timedelta
from airflow import DAG
from airflow.sensors.external_task import ExternalTaskSensor
from airflow.operators.empty import EmptyOperator

default_args = {
    'owner': 'airflow',
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
    'start_date': datetime(2024, 1, 1),
}

dag = DAG(
    'external_task_sensor_example',
    default_args=default_args,
    description='ExternalTaskSensor example DAG',
    schedule_interval=timedelta(days=1),
    catchup=False,
)

wait_for_upstream = ExternalTaskSensor(
    task_id='wait_for_upstream',
    external_dag_id='hello_world_dag',
    external_task_id='end',
    timeout=3600,
    mode='reschedule',
    dag=dag,
)

my_task = EmptyOperator(task_id='my_task', dag=dag)

wait_for_upstream >> my_task
