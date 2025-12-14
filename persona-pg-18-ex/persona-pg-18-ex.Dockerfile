# Use the official Postgres 18 Debian-based image
FROM postgres:18

# Install minimal dependencies needed for repo bootstrap
RUN apt-get update && apt-get install -y \
    wget \
    gpgv \
    curl \
    ca-certificates \
    lsb-release \
    git \
    build-essential \
    postgresql-server-dev-18 \
    && rm -rf /var/lib/apt/lists/*

# Install Percona repository bootstrap package (generic, codename-agnostic)
RUN wget -q https://repo.percona.com/apt/percona-release_latest.generic_all.deb && \
    dpkg -i percona-release_latest.generic_all.deb && \
    rm -f percona-release_latest.generic_all.deb

# Enable Percona PostgreSQL 18 repository
RUN percona-release setup ppg-18

# Install required PostgreSQL extensions
RUN apt-get update && apt-get install -y \
    percona-pg-stat-monitor18 \
    postgresql-18-cron \
    && rm -rf /var/lib/apt/lists/*

# Build and install pg_ivm 1.13 from source
RUN git clone --branch v1.13 --depth 1 https://github.com/sraoss/pg_ivm.git /tmp/pg_ivm && \
    cd /tmp/pg_ivm && \
    make && \
    make install && \
    cd / && \
    rm -rf /tmp/pg_ivm

# Remove build dependencies to reduce image size
RUN apt-get purge -y \
    git \
    build-essential \
    postgresql-server-dev-18 \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Copy the initialization script into the entrypoint init directory
COPY startup.sql /docker-entrypoint-initdb.d/

# Default command remains as postgres, overridden in docker-compose.yml
CMD ["postgres"]
