FROM python:3.9-buster

# Install system dependencies
RUN set -e; \
    apt-get update -y && apt-get install -y lsb-release; \
    gcsFuseRepo=gcsfuse-`lsb_release -c -s`; \
    echo "deb http://packages.cloud.google.com/apt $gcsFuseRepo main" | \
    tee /etc/apt/sources.list.d/gcsfuse.list; \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    apt-key add -; \
    apt-get update; \
    apt-get install -y gcsfuse \
    && apt-get clean

# Set defaults and fallbacks
ENV MNT_DIR /mnt/gcs
ENV PORT 8080
ENV APP_HOME /app
WORKDIR $APP_HOME

RUN pip install -U datasette

RUN mkdir -p /mnt/gcs
COPY startup.sh /app

ENTRYPOINT /app/startup.sh
