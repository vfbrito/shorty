FROM ruby:2.4.2
MAINTAINER Vera Brito <vfbrito@gmail.com>

RUN apt-get update -qq && apt-get install -y build-essential

ENV APP_NAME /impraise-shorty
RUN mkdir $APP_NAME
WORKDIR $APP_NAME

ADD Gemfile* $APP_NAME/

RUN bundle install

ADD . $APP_NAME