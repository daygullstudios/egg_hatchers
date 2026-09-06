FROM ghcr.io/cirruslabs/flutter:3.44.0 AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release --no-pub \
    && dart compile exe tool/multiplayer_server.dart \
        -o build/nestarium-server

FROM debian:bookworm-slim AS runtime

RUN useradd --create-home --uid 10001 nestarium

WORKDIR /app
COPY --from=build --chown=nestarium:nestarium \
    /app/build/nestarium-server /app/nestarium-server
COPY --from=build --chown=nestarium:nestarium \
    /app/build/web /app/build/web

ENV HOST=0.0.0.0
ENV PORT=10000
ENV WEB_ROOT=/app/build/web

EXPOSE 10000
USER nestarium

ENTRYPOINT ["/app/nestarium-server"]
