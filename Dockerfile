# Pick the ruby version for your rails app
FROM ruby:3.0.0

# Installing some needed things here
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev tzdata libicu-dev

# for nokogiri
RUN apt-get install -yqq libxml2-dev libxslt1-dev

# node
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs

# yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update -qq && apt-get install -y yarn

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Make the directory for the app
RUN mkdir /app

# Set the working directory of everything to the directory we just made.
WORKDIR /app

# Gems
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
COPY package.json package.json
COPY yarn.lock yarn.lock

# Install and run bundle to get the app ready
RUN gem install bundler
RUN bundle install
RUN yarn install
RUN yarn check --integrity

# Copy the Rails application into place
COPY . /app
