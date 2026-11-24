FROM debian:bookworm-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git libglu1-mesa unzip xz-utils zip
RUN git clone --depth 1 --branch 3.47.0 https://github.com/flutter/flutter.git /opt/flutter \
    && test "$(git -C /opt/flutter rev-parse HEAD)" = "4cf24164269a5ebf0c16a028a00727d0e77bbb05" \
    && git config --global --add safe.directory /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"
WORKDIR /app
COPY frontend/pubspec.yaml frontend/pubspec.lock ./
RUN flutter pub get --enforce-lockfile
COPY frontend/ .
RUN flutter build web --release --dart-define=BACKEND_URL=

FROM nginx:1.27-alpine
COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
