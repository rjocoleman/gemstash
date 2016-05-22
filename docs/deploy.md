# Deploying Gemstash

Bundler is here for the rescue to keep Gemstash up to date! Create a `Gemfile`
pointing to Gemstash:
```ruby
# ./Gemfile
source "https://www.rubygems.org"
gem "gemstash"
```

Then `bundle` to create your `Gemfile.lock`. When you are ready to upgrade,
simply `bundle update`. You may need to run `gemstash` via `bundle exec`.
Alternatively, you can `gem uninstall gemstash` and `gem install gemstash` when
you want to upgrade.

Gemstash will automatically run any necessary migrations, so updating the gem is
all that needs to be done.

It is probably wise to stop Gemstash before upgrading, then starting again once
you are done:
```
$ bundle exec gemstash stop
$ bundle update
$ bundle exec gemstash start
```

## Downgrading

It is not recommended to go backwards in Gemstash versions. Migrations may have
run that could leave the database in a bad state.

## Docker

A Docker image is provided and published on [DockerHub](https://hub.docker.com/r/bundler/gemstash).
This image is designed for Gemstash to be configured via environment variables.

### Configuration

For Gemstash version 1.0.1 and below use `$ gemstash setup` and persist your `~/.gemstash/config.yml` file as appropriate.

For newer versions the Gemstash [`config.yml`](https://github.com/bundler/gemstash/blob/master/docs/reference.md#configuration) configuration keys are pulled from the containers environment variables (if set).

This method of configuration means that `$ gemstash setup` is not used in the Docker image.

Available environment variables:

```shell
BASE_PATH
CACHE_TYPE
MEMCACHED_SERVERS
DB_ADAPTER
DB_URL
RUBYGEMS_URL
BIND
```

### Data persistence

* Data volume: `/root/.gemstash/` is the Gemstash directory. All Gemstash data (including the db if sqlite is used) is stored here. This can be configured as a named or data volume to persist the data between container invocations

* External resources: Postgres or MySQL databases can also be used via `DB_URL` and `DB_ADAPTER`.

### Usage

The `Dockerfile` specifies the Entrypoint of this image to be the Gemstash binary. The default command is the server (i.e. to serve `docker run bundler/gemstash`)

Other commands can be run by prefixing them e.g. `docker run bundler/gemstash authorize`

#### Docker Compose

Below is an example [Docker Compose](https://docs.docker.com/compose/overview/) configuration file that brings up Gemstash as app, Postgres, links this into the container and persists data for the db as well as gems to [named volumes](https://docs.docker.com/engine/userguide/containers/dockervolumes/#creating-and-mounting-a-data-volume-container).

```yaml
# docker-compose.yml
app:
  image: bundler/gemstash
  restart: always
  ports:
    - 9292:9292
  environment:
    - DB_URL=postgres://postgres:password@database:5432/postgres
    - DB_ADAPTER=postgres
  links:
    - database
  volumes:
    - gemstash-gems-data-vol:/root/.gemstash

database:
  image: postgres
  restart: always
  ports:
    - 5432
  environment:
    - POSTGRES_PASSWORD=password
  volumes:
    - gemstash-gems-db-data-vol:/var/lib/postgresql/data
```

The Postgres container and it's configuration environment variables could be omitted to use the default sqlite database.

### Development

The Dockerfile is located in the root of the Gem git repo.
`$ docker build -t bundler/gemstash .` `RACK_ENV` environment variable defaults to `production` in the Docker image.
