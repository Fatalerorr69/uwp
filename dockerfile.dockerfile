# Dockerfile
FROM ubuntu:22.04 AS base

# Metadata
LABEL maintainer="Fatalerorr69"
LABEL version="5.0.0"
LABEL description="Universal Workspace Project"

# Nastavení prostředí
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Prague \
    UWP_HOME=/opt/uwp \
    UWP_USER=uwpuser \
    UWP_UID=1000

# Vytvoření uživatele
RUN groupadd -r ${UWP_USER} -g 1000 && \
    useradd -r -u ${UWP_UID} -g ${UWP_USER} ${UWP_USER}

# Instalace základních závislostí
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    nano \
    vim \
    htop \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Instalace Docker CE (pro Docker-in-Docker)
RUN curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh && \
    usermod -aG docker ${UWP_USER}

# Vytvoření struktury UWP
WORKDIR ${UWP_HOME}

COPY --chown=${UWP_USER}:${UWP_USER} . .

# Instalace Python závislostí
RUN pip3 install --no-cache-dir \
    numpy \
    pandas \
    scikit-learn \
    nltk \
    gensim \
    textblob \
    pyyaml \
    python-dotenv \
    colorama \
    tqdm

# Instalace Node.js závislostí
RUN npm install -g \
    nodemon \
    typescript \
    @types/node

# Nastavení oprávnění
RUN chown -R ${UWP_USER}:${UWP_USER} ${UWP_HOME} && \
    chmod +x ${UWP_HOME}/scripts/*.sh

# Přepnutí na neprivilegovaného uživatele
USER ${UWP_USER}

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ${UWP_HOME}/scripts/healthcheck.sh

# Entrypoint
ENTRYPOINT ["/opt/uwp/scripts/entrypoint.sh"]
CMD ["uwp", "status"]