# --- Stage 1: Build ---
ARG ELIXIR_VERSION=1.19.5
ARG OTP_VERSION=28.0.1
ARG DEBIAN_VERSION=bookworm-20260316-slim
ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} AS builder

RUN apt-get update -y && \
    apt-get install -y build-essential git curl && \
    apt-get clean && rm -f /var/lib/apt/lists/*_*

# Install Node.js 24.x and yarn for Webpack asset compilation
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn && \
    apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

ENV MIX_ENV="prod"

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Fetch dependencies first (leverages Docker layer caching)
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# Build assets with Webpack
COPY assets/package.json assets/yarn.lock assets/
RUN cd assets && yarn install --frozen-lockfile

COPY priv priv
COPY assets assets

RUN cd assets && NODE_OPTIONS=--openssl-legacy-provider yarn deploy
RUN mix phx.digest

# Compile application and build release
COPY lib lib
COPY config/runtime.exs config/

RUN mix compile
RUN mix release

# --- Stage 2: Runtime ---
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates imagemagick && \
    apt-get clean && rm -f /var/lib/apt/lists/*_*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"

WORKDIR /app
RUN chown nobody /app

ENV MIX_ENV="prod"

COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/helheim ./

USER nobody

CMD ["/app/bin/helheim", "start"]
