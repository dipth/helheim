# Helheim

Prerequisites:

  * Install Erlang with `brew install erlang`
  * Install Elixir with `brew install elixir`
  * Install Imagemagick with `brew install imagemagick`
  * Install Hex package manager with `mix local.hex`
  * Install Phoenix with `mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new.ez`
  * Update to the latest version of NPM with `npm install npm@latest -g`
  * Install brunch with `npm install -g brunch`
  * Install Phantom.js with `npm install -g phantomjs`
  * Create a postgres user with `createuser -d -P -s postgres` - when prompted for the password, choose `postgres`

To start your Phoenix app:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Optionally load a database dump with `mix data.import PATH_TO_DUMP_FILE`
  * Install frontend dependencies with `cd assets && yarn`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
