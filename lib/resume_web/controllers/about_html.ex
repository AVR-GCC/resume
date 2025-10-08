defmodule ResumeWeb.AboutHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use ResumeWeb, :html

  embed_templates "about_html/*"
end
