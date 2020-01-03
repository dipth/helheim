# Helheim

[Helheim](https://helheim.dk) is a free and open source Danish online community for alternative people.

## Requirements:

  * `Elixir` 1.9.1 OTP 21
  * `Node.js` 13.5.0
  * `yarn` 1.21.1
  * `Imagemagick` 7.0.9-12
  * `PostgreSQL` 12.1
  * `Chromedriver` 2.36

The recommended way to install Elixir and Node.js is through the modular version manager asdf:
https://github.com/asdf-vm/asdf
https://github.com/asdf-vm/asdf-elixir
https://github.com/asdf-vm/asdf-nodejs

yarn can be installed through node.js

The remaining can be installed with Homebrew:
https://brew.sh/

## Getting started:

1. Get elixir dependencies:

    ```
    mix deps.get
    ```

2. Get node.js dependencies:

    ```
    cd assets
    yarn
    cd ..
    ```

3. Create, migrate and seed database:

    ```
    mix ecto.setup
    ```

4. Start server:

    ```
    mix phx.server
    ```

5. Load [`localhost:4000`](http://localhost:4000) in your preferred browser

## Contributing

We appreciate any contribution to Helheim.
Check our [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) and [CONTRIBUTING.md](CONTRIBUTING.md) guides for more information
