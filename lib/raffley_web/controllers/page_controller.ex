defmodule RaffleyWeb.PageController do
  use RaffleyWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  # Renders the survey page directly with a hardcoded URL for testing
  def survey(conn, _params) do
    # Replace this with your actual Google Form embed URL
    google_form_url =
      "https://docs.google.com/forms/d/e/1FAIpQLScIC1VtnxLTWNGeAgUPFy8J_sS_JXhwbQiA4cbwg_rnN8XHTg/viewform?embedded=true"
    render(conn, :survey, google_form_url: google_form_url)
  end
end
