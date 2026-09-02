FROM ghcr.io/cirruslabs/flutter:3.44.0 AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release --no-pub \
    && dart compile exe tool/multiplayer_server.dart \
        -o build/egg-hatchers-server

FROM debian:bookworm-slim AS runtime

RUN useradd --create-home --uid 10001 egg-hatchers

WORKDIR /app
COPY --from=build --chown=egg-hatchers:egg-hatchers \
    /app/build/egg-hatchers-server /app/egg-hatchers-server
COPY --from=build --chown=egg-hatchers:egg-hatchers \
    /app/build/web /app/build/web

ENV HOST=0.0.0.0
ENV PORT=10000
ENV WEB_ROOT=/app/build/web

EXPOSE 10000
USER egg-hatchers

ENTRYPOINT ["/app/egg-hatchers-server"]
