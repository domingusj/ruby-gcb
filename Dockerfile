# build stage
FROM alpine:3.5 as builder

ENV BUNDLER_VERSION 1.16.1

RUN set -ex && \
    apk upgrade && \
    apk --no-cache add ruby \
            ruby-bigdecimal \
            ruby-dev \
            ruby-io-console \
            ruby-irb \
            ruby-json \
            ruby-rake \
            build-base \
            bzip2 \
            ca-certificates \
            libffi-dev \
            libressl-dev \
            procps \
            yaml-dev \
            zlib-dev \
            mariadb \
            git && \
    { \
      echo 'install: --no-document'; \
      echo 'update: --no-document'; \
    } >> /etc/gemrc && \
    gem install bundler

# Set Bundler up to ensure bundled dependencies are in our vendor directory.
ENV BUNDLE_PATH="/opt/vendor/bundle" \
    BUNDLE_BIN="/opt/vendor/bundle/bin" \
    BUNDLE_APP_CONFIG="/usr/local/bundler" \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLE_FORCE_RUBY_PLATFORM=1
ENV PATH $BUNDLE_BIN:$PATH

RUN mkdir -p $BUNDLE_APP_CONFIG \
    && chmod 777 $BUNDLE_APP_CONFIG

COPY Gemfile Gemfile.lock ./

RUN bundle install

# run image

# final stage
FROM alpine:3.5

ENV BUNDLER_VERSION 1.16.1

RUN set -ex && \
    apk upgrade && \
    apk --no-cache add ruby \
            ruby-io-console \
            ruby-irb \
            ruby-json \
            ruby-rake \
            ruby-bigdecimal \
            bzip2 \
            ca-certificates \
            procps && \
    { \
      echo 'install: --no-document'; \
      echo 'update: --no-document'; \
    } >> /etc/gemrc && \
    gem install bundler

# Set Bundler up to ensure bundled dependencies are in our vendor directory.
ENV BUNDLE_PATH="/opt/vendor/bundle" \
    BUNDLE_BIN="/opt/vendor/bundle/bin" \
    BUNDLE_APP_CONFIG="/usr/local/bundler" \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLE_FORCE_RUBY_PLATFORM=1 \
    BUNDLE_GEMFILE="/opt/app/Gemfile"
ENV PATH $BUNDLE_BIN:$PATH

COPY . /opt/app
COPY --from=builder /opt/vendor /opt/vendor

RUN addgroup app && \
    adduser -h /opt/app -s /bin/sh -g app -G app -D app && \
    chown -R app:app /opt

USER app

WORKDIR /opt/app

CMD ["/opt/app/ruby-test.rb"]
