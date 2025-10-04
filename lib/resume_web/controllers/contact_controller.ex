defmodule ResumeWeb.ContactController do
  use ResumeWeb, :controller

  def contact(conn, _params) do
    render(conn, :contact)
  end
end
