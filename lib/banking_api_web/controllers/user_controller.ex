defmodule BankingApiWeb.UserController do
  @moduledoc """
  User controller
  """
  use BankingApiWeb, :controller
  use PhoenixSwagger

  require Logger

  import Guardian.Plug

  alias BankingApi.Auth
  alias BankingApi.Auth.Guardian
  alias BankingApi.Auth.User

  action_fallback BankingApiWeb.FallbackController

  def swagger_definitions do
    %{
      User:
        swagger_schema do
          title("User")
          description("An user of the application")

          properties do
            name(:string, "User's name", required: true)
            id(:binary_id, "Unique identifier - uuid", required: true)
            email(:string, "User's email", required: true)
            is_active(:boolean, "If account is active or not")
            permission(:string, "User permission", example: "ADMIN | DEFAULT")
          end

          example(%{
            id: "01992124-d1a5-4ddc-b4e9-395905f50d77",
            name: "João da Silva",
            email: "joao.silva@gmail.com",
            is_active: true,
            permission: "ADMIN",
            account: %{
              id: "aa992124-d1a5-4ddc-b4e8-395902f50d77",
              balance: "1253.00"
            }
          })
        end,
      UserAccount:
        swagger_schema do
          title("User with Account")
          description("An user of the application")

          properties do
            name(:string, "User's name", required: true)
            id(:binary_id, "Unique identifier - uuid", required: true)
            email(:string, "User's email", required: true)
            is_active(:boolean, "If account is active or not")
            permission(:string, "User permission", example: "ADMIN | DEFAULT")
            account(Schema.ref(:Account))
          end

          example(%{
            id: "01992124-d1a5-4ddc-b4e9-395905f50d77",
            name: "João da Silva",
            email: "joao.silva@gmail.com",
            is_active: true,
            permission: "ADMIN",
            account: %{
              id: "aa992124-d1a5-4ddc-b4e8-395902f50d77",
              balance: "1253.00"
            }
          })
        end,
      UserAuth:
        swagger_schema do
          title("User with Authorization")
          description("An user of the application with authentication token")

          properties do
            name(:string, "User's name", required: true)
            id(:binary_id, "Unique identifier - uuid", required: true)
            email(:string, "User's email", required: true)
            is_active(:boolean, "If account is active or not")
            permission(:string, "User permission", example: "ADMIN | DEFAULT")
            account(Schema.ref(:Account))
            token(:string, "Access Token of type Bearer", required: true)
          end

          example(%{
            id: "01992124-d1a5-4ddc-b4e9-395905f50d77",
            name: "João da Silva",
            email: "joao.silva@gmail.com",
            is_active: true,
            permission: "ADMIN",
            account: %{
              id: "aa992124-d1a5-4ddc-b4e8-395902f50d77",
              balance: "1253.00"
            },
            token:
              "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJiYW5raW5nX2FwaSIsImV4cCI6MTU4MjgyMTY4OCwiaWF0IjoxNTgwNDAyNDg4LCJpc3MiOiJiYW5raW5nX2FwaSIsImp0aSI6ImZmYjJjODhiLTRkYjctNDZiYy04ODVhLWM5YzM5MTViNmQ4NSIsIm5iZiI6MTU4MDQwMjQ4NywicGVybXMiOnsiZGVmYXVsdCI6WyJiYW5raW5nIl19LCJzwMDMzZjVkZC04ZmUxLTQ4NzMtOTA0Yi0yMWZkMWQ1YjNkMDciLCJ0eXAiOiJhY2Nlc3MifQ.ahU_OOoP2a7sh1e4TpxsHiu3LR4DDx832x4qUbX47etxS4vhwFRzLlrTxybUexAhzMPw6kxr07DSGVEIXCiEuw"
          })
        end,
      Users:
        swagger_schema do
          title("Users")
          description("All Users of the application")
          type(:array)
          items(Schema.ref(:UserAccount))
        end,
      Error:
        swagger_schema do
          title("Error")
          description("Error responses from the API")

          properties do
            errors(
              :object,
              "Object with details about the error",
              required: true
            )
          end
        end
    }
  end

  swagger_path :index do
    get("/backoffice/users")
    summary("List all users")
    description("Returns a list of all users. Permission needed: ADMIN")
    operation_id("list_users")
    response(200, "Ok", Schema.ref(:Users))
    tag("Backoffice")
    security([%{Bearer: []}])
  end

  def index(conn, _params) do
    users = Auth.list_users()
    render(conn, "index.json", users: users)
  end

  swagger_path :create do
    post("/backoffice/users")
    summary("Create a new User")
    description("Records a new User. Permission Needed: ADMIN")
    operation_id("create_user")
    response(200, "Ok", Schema.ref(:UserAccount))

    response(400, "Error: Bad Request", Schema.ref(:Error),
      examples: %{errors: %{details: "Bad Request"}}
    )

    response(422, "Error: Unprocessable Entity", Schema.ref(:Error),
      examples: %{errors: %{email: "has already been taken"}}
    )

    tag("Backoffice")
    security([%{Bearer: []}])

    parameters do
      user(
        :body,
        %PhoenixSwagger.Schema{
          type: :object,
          required: ["name", "email", "password"],
          properties: %{
            name: %PhoenixSwagger.Schema{
              type: :string,
              description: "User's name"
            },
            email: %PhoenixSwagger.Schema{
              type: :string,
              description: "User's email"
            },
            password: %PhoenixSwagger.Schema{
              type: :string,
              description: "User's password"
            },
            permission: %PhoenixSwagger.Schema{
              type: :string,
              description: "User's access permission"
            },
            is_active: %PhoenixSwagger.Schema{
              type: :boolean,
              description: "User's status"
            }
          },
          example: %{
            user: %{
              name: "João da Silva",
              email: "joao.silva@gmail.com",
              password: "joao1234",
              permission: "ADMIN"
            }
          }
        },
        "User Object",
        required: true
      )
    end
  end

  def create(conn, %{"user" => user_params}) do
    case Auth.create_user(user_params) do
      # Create OK
      {:ok, %User{} = user} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", Routes.user_path(conn, :show, user))
        |> render("show.json", %{user: user})

      # Create failed
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, changeset}
    end
  end

  swagger_path :show do
    get("/backoffice/users/{id}")
    summary("Get User by ID")
    description("Returns a single user given an ID. Permission Needed: ADMIN")
    operation_id("get_user_by_id")
    response(200, "Ok", Schema.ref(:UserAccount))

    response(400, "Error: Bad Request", Schema.ref(:Error),
      examples: %{errors: %{details: "Bad Request"}}
    )

    response(404, "Error: Not Found", Schema.ref(:Error),
      examples: %{errors: %{details: "Not Found"}}
    )

    tag("Backoffice")
    security([%{Bearer: []}])

    parameters do
      id(:path, :string, "User's ID", required: true)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Auth.get_user!(id)
    render(conn, "show.json", user: user)
  end

  swagger_path :show_current_user do
    get("/user")
    summary("Get current User")
    description("Returns the logged in user")
    operation_id("get_current_user")
    response(200, "Ok", Schema.ref(:UserAccount))

    response(400, "Error: Bad Request", Schema.ref(:Error),
      examples: %{errors: %{details: "Bad Request"}}
    )

    tag("User")
    security([%{Bearer: []}])
  end

  def show_current_user(conn, _params) do
    current_user = current_resource(conn)
    render(conn, "show.json", user: current_user)
  end

  swagger_path :update do
    put("/backoffice/users/{id}")
    summary("Update an existing User")
    description("Updates an existing User. Permission Needed: ADMIN")
    operation_id("update_user")
    response(200, "Ok", Schema.ref(:UserAccount))

    response(400, "Error: Bad Request", Schema.ref(:Error),
      examples: %{errors: %{details: "Bad Request"}}
    )

    response(404, "Error: Not Found", Schema.ref(:Error),
      examples: %{errors: %{details: "Not Found"}}
    )

    response(422, "Error: Unprocessable Entity", Schema.ref(:Error),
      examples: %{errors: %{email: "has already been taken"}}
    )

    tag("Backoffice")
    security([%{Bearer: []}])

    parameters do
      id(:path, :string, "User's ID", required: true)
    end

    parameters do
      user(
        :body,
        %PhoenixSwagger.Schema{
          type: :object,
          properties: %{
            name: %PhoenixSwagger.Schema{
              type: :string,
              description: "User's name"
            },
            email: %PhoenixSwagger.Schema{
              type: :string,
              description: "User's email"
            },
            password: %PhoenixSwagger.Schema{
              type: :string,
              description: "User's password"
            },
            permission: %PhoenixSwagger.Schema{
              type: :string,
              description: "User's access permission"
            },
            is_active: %PhoenixSwagger.Schema{
              type: :boolean,
              description: "User's status"
            }
          },
          example: %{
            user: %{
              name: "Maria da Silva",
              email: "maria.silva@gmail.com",
              password: "maria1234",
              permission: "DEFAULT"
            }
          }
        },
        "User Object",
        required: true
      )
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Auth.get_user!(id)

    with {:ok, %User{} = user} <- Auth.update_user(user, user_params) do
      render(conn, "show.json", user: user)
    end
  end

  swagger_path :update_current_user do
    put("/user")
    summary("Update current user")

    description(
      ~s(Updates the current User logged in. Permission Needed: DEFAULT | ADMIN\nIf user's permission is not ADMIN, "permission" and "is_active" fields are not updated)
    )

    operation_id("update_current_user")

    response(200, "Ok", Schema.ref(:UserAccount))

    response(400, "Error: Bad Request", Schema.ref(:Error),
      examples: %{errors: %{details: "Bad Request"}}
    )

    response(422, "Error: Unprocessable Entity", Schema.ref(:Error),
      examples: %{errors: %{email: "has already been taken"}}
    )

    tag("User")
    security([%{Bearer: []}])

    parameters do
      user(
        :body,
        %PhoenixSwagger.Schema{
          type: :object,
          properties: %{
            name: %PhoenixSwagger.Schema{
              type: :string,
              description: "User's name"
            },
            email: %PhoenixSwagger.Schema{
              type: :string,
              description: "User's email"
            },
            password: %PhoenixSwagger.Schema{
              type: :string,
              description: "User's password"
            },
            permission: %PhoenixSwagger.Schema{
              type: :string,
              description: "User's access permission"
            },
            is_active: %PhoenixSwagger.Schema{
              type: :boolean,
              description: "User's status"
            }
          },
          example: %{
            user: %{
              name: "Maria da Silva",
              email: "maria.silva@gmail.com",
              password: "maria1234",
              permission: "DEFAULT"
            }
          }
        },
        "User Object",
        required: true
      )
    end
  end

  def update_current_user(conn, %{"user" => user_params}) do
    current_user = current_resource(conn)

    # No ADMIN permission can't update permission and is_active
    user_params =
      if current_user.permission !== "ADMIN" do
        user_params |> Map.delete("permission") |> Map.delete("is_active")
      else
        user_params
      end

    with {:ok, %User{} = user} <- Auth.update_user(current_user, user_params) do
      render(conn, "show.json", user: user)
    end
  end

  swagger_path :delete_user do
    delete("/backoffice/users/{id}")
    summary("Delete an existing User")
    description("Delestes an existing User. Permission Needed: ADMIN")
    operation_id("delete_user")
    response(204, "No Content")

    response(404, "Error: Not Found", Schema.ref(:Error),
      examples: %{errors: %{details: "Not Found"}}
    )

    tag("Backoffice")
    security([%{Bearer: []}])

    parameters do
      id(:path, :string, "User's ID", required: true)
    end
  end

  def delete_user(conn, %{"id" => id}) do
    user = Auth.get_user!(id)

    with {:ok, %User{}} <- Auth.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end

  swagger_path :signup do
    post("/user/signup")
    summary("Sign up User")

    description(
      "Records a new user and log it in the application. Just allow creating user with Default access persmission."
    )

    operation_id("signup")

    response(201, "Created", Schema.ref(:UserAuth))

    response(400, "Error: Bad Request", Schema.ref(:Error),
      examples: %{errors: %{details: "Bad Request"}}
    )

    response(422, "Error: Unprocessable Entity", Schema.ref(:Error),
      examples: %{errors: %{email: "Can't be blank"}}
    )

    tag("User")

    parameters do
      user(
        :body,
        %PhoenixSwagger.Schema{
          type: :object,
          properties: %{
            name: %PhoenixSwagger.Schema{
              type: :string,
              description: "User's name"
            },
            email: %PhoenixSwagger.Schema{
              type: :string,
              description: "User's email"
            },
            password: %PhoenixSwagger.Schema{
              type: :string,
              description: "User's password"
            }
          },
          required: ["name", "email", "password"],
          example: %{
            user: %{
              name: "João da Silva",
              email: "joao.silva@gmail.com",
              password: "joao1234"
            }
          }
        },
        "The user to be created",
        required: true
      )
    end
  end

  def signup(conn, %{"user" => user_params}) do
    # Ensures just Users with permission DEFAULT can be created
    user_params = Map.put(user_params, "permission", "DEFAULT")
    user_params = Map.put(user_params, "is_active", true)

    case Auth.create_user(user_params) do
      # Create OK, generates access token(JWT)
      {:ok, %User{} = user} ->
        # set default permissions
        perms = %{default: [:banking]}

        with {:ok, token, _claims} <- Guardian.encode_and_sign(user, %{perms: perms}) do
          conn
          |> put_status(:created)
          |> put_resp_header("location", Routes.user_path(conn, :show, user))
          |> render("show.json", %{user: user, token: token})
        end

      # Create failed
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  swagger_path :signin do
    post("/user/signin")
    summary("Sign in User")
    description("Signs User in the application.")
    operation_id("signin")

    response(
      200,
      "OK",
      Schema.ref(:UserAuth)
    )

    response(400, "Error: Bad Request", Schema.ref(:Error),
      examples: %{errors: %{details: "Bad Request"}}
    )

    response(401, "Error: Unauthorized", Schema.ref(:Error),
      examples: %{errors: %{detail: "Unauthorized"}}
    )

    tag("User")

    parameters do
      credentials(
        :body,
        %PhoenixSwagger.Schema{
          type: :object,
          properties: %{
            email: %PhoenixSwagger.Schema{
              type: :string,
              description: "User's password"
            },
            password: %PhoenixSwagger.Schema{
              type: :string,
              description: "User's password"
            }
          },
          example: %{
            email: "joao.silva@gmail.com",
            password: "joao1234"
          }
        },
        "User's credentials for signing user in",
        required: true
      )
    end
  end

  def signin(conn, credentials) do
    try do
      %{"email" => email, "password" => password} = credentials

      with {:ok, user, token} <- Guardian.authenticate(email, password) do
        conn
        |> put_status(:ok)
        |> render("user.json", %{user: user, token: token})
      end
    rescue
      _ -> {:error, :bad_request}
    end
  end
end
