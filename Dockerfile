FROM ghcr.io/cirruslabs/flutter:stable

WORKDIR /workspace

RUN flutter config --enable-web

COPY styleai/pubspec.yaml styleai/pubspec.lock* ./styleai/

WORKDIR /workspace/styleai

RUN flutter pub get

COPY styleai/ /workspace/styleai/

EXPOSE 3000

CMD ["flutter", "run", "-d", "web-server", "--web-hostname", "0.0.0.0", "--web-port", "3000"]