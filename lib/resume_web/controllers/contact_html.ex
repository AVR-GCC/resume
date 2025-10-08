defmodule ResumeWeb.ContactHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use ResumeWeb, :html
  import ResumeWeb.AppComponents

  embed_templates "contact_html/*"
end
