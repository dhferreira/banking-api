# BankingApi

Example of Banking API using Elixir language.

## Requirements

- Docker Compose: https://docs.docker.com/compose/install/

## Running Development Environment

1. Clone this repository
2. Run `cd banking_api/` (or whatever folder's name you chose)
3. Rename the file ".env_example" to ".env", and fill out the variables with their values. (secret from `mix gen.secret`, and database's urls)
3. Run `docker-compose up --build` at the project's root directory

Now you can access the api through [`localhost:4000`](http://localhost:4000)

## Running Tests

If you want to run the automated tests in this API, after run Development Environment

1. Run Development Environment
2. Inside the running Docker's Container
3. Run `mix test`

## Live Demo (Production)

Access: [`Live Demo`](https://banking-api-elixir.herokuapp.com/api)

## API Documentation

Documentation: [`Api Documentation`](https://banking-api-elixir.herokuapp.com/doc)

## Learn more

- Official website: http://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Mailing list: http://groups.google.com/group/phoenix-talk
- Source: https://github.com/phoenixframework/phoenix
