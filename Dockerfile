FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

RUN flutter build apk --release --no-pub

FROM alpine:3.19 AS export
WORKDIR /output
COPY --from=builder /app/build/app/outputs/flutter-apk/app-release.apk ./grabbit.apk

CMD ["sh", "-c", "echo 'APK ready at /output/grabbit.apk'"]