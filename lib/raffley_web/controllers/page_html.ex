defmodule RaffleyWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use RaffleyWeb, :html

  # Import core components
  import RaffleyWeb.CoreComponents
  alias RaffleyWeb.Layouts
  
  embed_templates "page_html/*"
end
