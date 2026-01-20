FROM python:3.12.3-slim

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pip install -U pip --no-cache-dir

RUN curl -sSL https://install.python-poetry.org | python3 -

COPY ./pyproject.toml ./poetry.toml ./

RUN /root/.local/bin/poetry install --only=main --no-root

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONUTF8=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PATH="/app/.venv/bin:$PATH" \
    AIRFLOW__CORE__LOAD_EXAMPLES=False \
    AIRFLOW__CORE__DAGS_FOLDER=/app/dags

COPY ./dags/ /app/dags/

CMD [ "airflow", "standalone" ]
