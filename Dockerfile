FROM ruby:3.4.6-alpine3.22 AS miniapp

RUN apk --update add --no-cache \
    build-base \
    yaml-dev \
    tzdata \
    yarn \
    libc6-compat \
    postgresql-dev \
    postgresql-client \
    redis \
    curl \
    libffi-dev \
    ruby-dev \
    vips \
    vips-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libheif-dev \
    imagemagick \
    imagemagick-dev \
    && rm -rf /var/cache/apk/*

ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development test"

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN gem update --system 3.7.2
RUN gem install bundler -v $(tail -n 1 Gemfile.lock)
RUN bundle check || bundle install --jobs=2 --retry=3
RUN bundle clean --force

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

COPY . .

RUN bundle exec bootsnap precompile --gemfile app/ lib/ config/

RUN addgroup -g 1000 deploy && adduser -u 1000 -G deploy -D -s /bin/sh deploy
USER deploy:deploy

EXPOSE 3000
