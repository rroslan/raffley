defmodule RaffleyWeb.CardComponents do
  @moduledoc """
  Provides dedicated card components for different use cases.
  """
  use Phoenix.Component

  @doc """
  Renders a statistic card showing a key metric.

  ## Examples

      <.stat_card number="1,234" label="Users"/>
      <.stat_card number="87%" label="Completion" trend="up"/>
  """
  attr :number, :string, required: true
  attr :label, :string, required: true  
  attr :trend, :string, default: nil, values: [nil | ~w(up down)]

  def stat_card(assigns) do
    ~H"""
    <div class="stat">
      <div class="stat-value">{@number}</div>
      <div class="stat-title">{@label}</div>
      <div :if={@trend} class="stat-desc">
        <.icon name={if @trend == "up", do: "hero-arrow-trending-up", else: "hero-arrow-trending-down"}/>
      </div>
    </div>
    """
  end

  @doc """
  Renders a profile card with avatar and details.

  ## Examples

      <.profile_card name="John Doe">
        <:avatar><img src="avatar.png"/></:avatar>  
      </.profile_card>
  """
  attr :name, :string, required: true
  attr :bio, :string
  
  slot :avatar, required: true

  def profile_card(assigns) do
    ~H"""
    <div class="card bg-base-100">
      <div class="card-body items-center">
        <div class="avatar">
          <%= render_slot(@avatar) %>
        </div>
        <h3 class="card-title">{@name}</h3>
        <p :if={@bio}><%= @bio %></p>
      </div>
    </div>
    """
  end

  @doc """
  Renders a feature highlight card.

  ## Examples

      <.feature_card title="Fast" icon="hero-bolt">
        Built for speed
      </.feature_card>
  """
  attr :title, :string, required: true
  attr :icon, :string, required: true

  slot :inner_block, required: true

  def feature_card(assigns) do
    ~H"""
    <div class="card bg-base-100">
      <div class="card-body">
        <.icon name={@icon} class="w-8 h-8"/>
        <h3 class="card-title">{@title}</h3>
        <p><%= render_slot(@inner_block) %></p>
      </div>
    </div>
    """
  end

  @doc """
  Renders a customer testimonial card.

  ## Examples  

      <.testimonial_card name="Jane Smith">
        "Great product!"
      </.testimonial_card>
  """
  attr :name, :string, required: true

  slot :inner_block, required: true

  def testimonial_card(assigns) do
    ~H"""
    <div class="card bg-base-100">
      <div class="card-body">
        <blockquote>
          "<%= render_slot(@inner_block) %>"
          <footer>- <%= @name %></footer>
        </blockquote>
      </div>
    </div>
    """
  end

  defp icon(assigns) do
    ~H"""
    <span class={["hero-icon", @name, @class]}/>
    """
  end
end

