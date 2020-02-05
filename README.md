# BankingApi

Example of Banking API using Elixir language.

## Requirements

- Docker Compose: https://docs.docker.com/compose/install/

## Running Development Environment

1. Clone this repository
2. Run `cd banking_api/` (or whatever folder's name you chose)
3. Rename the file **.env_example** to **.env**, and fill out the variables with their values. (secret from `mix phx.gen.secret`, and database's urls). 
*Atention: If you don't have a secret, leave the SECRET_KEY_BASE variable blank in .env file. It will be generated automatically when you run the next command. After that just copy and paste the generated secret into the .env file.*
4. Run `docker-compose up --build` at the project's root directory

Now you can access the api through [`localhost:4000`](http://localhost:4000)

## Running Tests

If you want to run the automated tests in this API:

1. Run Development Environment as above.
2. Run `docker exec -it {DOCKER_CONTAINER_NAME || DOCKER_CONTAINER_ID} mix test`

## Deployment

### Deploying to Heroku

1. Create a new app in Heroku
2. Set Heroku stack to `container`
3. Set Config Vars:
- `DATABASE_URL`: productions postgres database url (example: `ecto://USER:PASSWORD@HOST/DATABASE`)
- `RENDER_EXTERNAL_HOSTNAME`: your app host (example: `app_name.herokuapp.com`)
- `SECRET_KEY_BASE`: app secret (from `mix phx.gen.secret`)
4. Fill out `ENV SECRET_KEY_BASE=` in **Dockerfile** with the same secret from *Config Vars*
5. Push the repository files to your Heroku app

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
