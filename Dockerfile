FROM plugfox/flutter:stable-android as build

USER root

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    ANDROID_NDK_HOME=$ANDROID_HOME/ndk \
    FLUTTER_SDK_HOME=$FLUTTER_HOME \
    PATH=$CARGO_HOME/bin:$ANDROID_HOME/ndk/22.1.7171670:$PATH \
    RUST_VERSION=stable

RUN set -eux; \
    apk add --no-cache make git ca-certificates musl-dev gcc file ;\
    yes "y" | $FLUTTER_HOME/bin/flutter doctor --android-licenses ;\
    $FLUTTER_HOME/bin/dart --disable-analytics ;\
    $FLUTTER_HOME/bin/flutter config --no-analytics --enable-android ;\
    $FLUTTER_HOME/bin/flutter precache --universal --android ;\
    sdkmanager --sdk_root=${ANDROID_HOME} --install 'ndk;22.1.7171670' ;\
    apkArch="$(apk --print-arch)"; \
    case "$apkArch" in \
        x86_64) rustArch='x86_64-unknown-linux-musl'; rustupSha256='bdf022eb7cba403d0285bb62cbc47211f610caec24589a72af70e1e900663be9' ;; \
        aarch64) rustArch='aarch64-unknown-linux-musl'; rustupSha256='89ce657fe41e83186f5a6cdca4e0fd40edab4fd41b0f9161ac6241d49fbdbbbe' ;; \
        *) echo >&2 "unsupported architecture: $apkArch"; exit 1 ;; \
    esac; \
    url="https://static.rust-lang.org/rustup/archive/1.24.3/${rustArch}/rustup-init"; \
    wget "$url"; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host ${rustArch}; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    $CARGO_HOME/bin/rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android ;\
    $CARGO_HOME/bin/cargo install cargo-ndk ;\
    rm -rf $CARGO_HOME/registry ;\
    find $ANDROID_HOME -type f -executable -exec strip --strip-unneeded {} \; && find $RUSTUP_HOME -type f -executable -exec strip --strip-unneeded {} \; && find $RUSTUP_HOME -name *.so -exec strip --strip-unneeded {} \; && find $RUSTUP_HOME -name *.rlib -exec strip -d {} \; && find $RUSTUP_HOME -name *.a -exec strip -d {} \;

COPY config.toml /usr/local/cargo/

WORKDIR /
CMD [ "/bin/bash" ]
