defmodule BankingApiWeb.ErrorView do
  use BankingApiWeb, :view
  require Logger

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  # def render("400.json", _assigns) do
  #   %{errors: %{detail: "Bad Request"}}
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end

  def template_unauthorized(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end

  def template_unprocessable_entity(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end

  def template_bad_request(template, _assings) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
