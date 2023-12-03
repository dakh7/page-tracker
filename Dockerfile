FROM python:3.11.6-slim-bullseye AS builder

RUN apt-get update && \
    apt-get upgrade --yes

RUN useradd --create-home pagetracker
USER pagetracker
WORKDIR /home/pagetracker

ENV VIRTUALENV=/home/pagetracker/venv
RUN python3 -m venv $VIRTUALENV
ENV PATH="$VIRTUALENV/bin:$PATH"

COPY --chown=pagetracker pyproject.toml constraints.txt ./

RUN pip install -U pip setuptools && pip install --no-cache-dir -c constraints.txt ".[dev]" 

COPY --chown=pagetracker src/ src/
COPY --chown=pagetracker test/ test/

RUN pip install . -c constraints.txt && \
    pytest test/unit/ && \
    flake8 src/ && \
    isort src/ --check && \
    black src/ --check --quiet && \
    pylint src/ --disable=C0114,C0116,R1705 && \
    bandit -r src/ --quiet && \
    pip wheel --wheel-dir dist/ . -c constraints.txt

FROM python:3.11.6-slim-bullseye

RUN apt-get update && \
    apt-get upgrade --yes

RUN useradd --create-home pagetracker
USER pagetracker
WORKDIR /home/pagetracker

ENV VIRTUALENV=/home/pagetracker/venv
RUN python3 -m venv $VIRTUALENV
ENV PATH="%VIRTUALENV/bin:$PATH"

COPY --from=builder /home/pagetracker/dist/page_tracker*.whl /home/pagetracker

RUN pip install -U pip setuptools && pip install --no-cache-dir page_tracker*.whl

CMD ["flask", "--app", "page_tracker.app", "run", \
     "--host", "0.0.0.0", "--port", "5000"]


