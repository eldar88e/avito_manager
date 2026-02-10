FROM ruby:3.4.8-alpine3.23 AS miniapp

RUN apk --update add --no-cache \
    build-base \
    yaml-dev \
    tzdata \
    libpq \
    postgresql-dev \
    vips \
    vips-dev \
    curl \
    yarn \
    && rm -rf /var/cache/apk/*
    # yaml

ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development test"

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v $(tail -n 1 Gemfile.lock)
RUN bundle check || bundle install --jobs=2 --retry=3
RUN bundle clean --force

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

RUN apk --update add --no-cache \
    fontconfig \
    freetype \
    ttf-dejavu \
    && rm -rf /var/cache/apk/*

COPY . .

# RUN bundle exec bootsnap precompile --gemfile app/ lib/ config/

#RUN addgroup -g 1000 deploy && adduser -u 1000 -G deploy -D -s /bin/sh deploy
#USER deploy:deploy

EXPOSE 3000
