FROM ruby:2.3-alpine

RUN apk update && apk upgrade
RUN apk add ruby-dev build-base

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
ADD . $APP_HOME

RUN gem install bundler
RUN bundle install
