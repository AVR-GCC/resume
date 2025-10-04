defmodule ResumeWeb.AboutController do
  use ResumeWeb, :controller

  def about(conn, _params) do
    render(conn, :about)
  end
end
