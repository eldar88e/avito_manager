FROM ruby:3.4.8-alpine3.23 AS builder

RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    vips-dev \
    yaml-dev \
    tzdata \
    yarn

ENV RAILS_ENV=production \
    NODE_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development test"

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v "$(tail -n 1 Gemfile.lock)" \
 && bundle install --jobs=2 --retry=3 \
 && bundle clean --force \
 && rm -rf /usr/local/bundle/cache

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile \
 && rm -rf node_modules/.cache

COPY . .

RUN SECRET_KEY_BASE=dummy DB_USER=dummy DB_PASSWORD=dummy REDIS_URL=dummy \
    bundle exec rails assets:precompile \
    && rm -rf node_modules
#    && bundle exec bootsnap precompile --gemfile app/ lib/ config/

FROM ruby:3.4.8-alpine3.23 AS runtime

RUN apk add --no-cache \
    tzdata \
    libpq \
    yaml \
    vips \
    fontconfig \
    freetype \
    ttf-dejavu

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development test"

WORKDIR /app

RUN addgroup -g 1000 deploy && adduser -u 1000 -G deploy -D -s /bin/sh deploy

COPY --from=builder --chown=deploy:deploy /usr/local/bundle /usr/local/bundle
COPY --from=builder --chown=deploy:deploy /app /app

USER deploy:deploy

EXPOSE 3000
