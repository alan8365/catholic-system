FROM ruby:3.1.2

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		postgresql-client \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

COPY Gemfile* ./
RUN bundle install
COPY . .

ENV PORT 3000
EXPOSE ${PORT}

#CMD rails db:prepare
#CMD rails db:seed
#CMD rails server -b 0.0.0.0 -p $PORT
#CMD ["/usr/src/app/start.sh", "rails", "server", "-b", "0.0.0.0", "-p", "$PORT"]
ENTRYPOINT "/usr/src/app/start.sh"