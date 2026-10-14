defmodule BeerGameWeb.GameUI do
  use Phoenix.Component

  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(assigns) do
    ~H"""
    <svg
      class={@class}
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.8"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
    >
      <%= case @name do %>
        <% "box" -> %>
          <path d="m12 3 9 5-9 5-9-5 9-5Zm-9 5v9l9 5 9-5V8M12 13v9M7.5 5.5l9 5" />
        <% "arrow" -> %>
          <path d="M4 12h16m-6-6 6 6-6 6" />
        <% "factory" -> %>
          <path d="M3 21V10l6 4V8l6 4V3h4l2 18H3ZM7 17h1m4 0h1m4 0h1" />
        <% "wholesaler" -> %>
          <path d="M3 21V8l9-5 9 5v13M3 9h18M7 21V13h10v8M7 17h10" />
        <% "retailer" -> %>
          <path d="M3 10h18l-2-6H5l-2 6Zm1 0v11h16V10M8 21v-7h5v7M3 10c0 3 4 3 4 0 0 3 5 3 5 0 0 3 5 3 5 0 0 3 4 3 4 0" />
        <% "incoming" -> %>
          <path d="M12 3v12m-5-5 5 5 5-5M4 14v7h16v-7" />
        <% "outgoing" -> %>
          <path d="M12 15V3m-5 5 5-5 5 5M4 14v7h16v-7" />
      <% end %>
    </svg>
    """
  end

  attr :role, :string, default: nil

  def supply_chain(assigns) do
    ~H"""
    <ol class="supply-chain" aria-label="Beer supply chain">
      <li
        :for={role <- ~w(factory wholesaler retailer)}
        class={["chain-stop", @role == role && "is-selected"]}
        aria-current={@role == role && "step"}
      >
        <.icon name={role} />
        <span>{String.capitalize(role)}</span>
        <span :if={@role == role} class="chain-you">You</span>
      </li>
    </ol>
    """
  end

  attr :current, :integer, required: true
  attr :create, :boolean, default: false

  def setup_steps(assigns) do
    ~H"""
    <ol class="setup-steps" aria-label="Game setup">
      <li
        :for={
          {label, step} <-
            Enum.with_index(
              [if(@create, do: "Create board", else: "Join board"), "Choose role", "Play"],
              1
            )
        }
        class={@current == step && "is-current"}
        aria-current={@current == step && "step"}
      >
        <span class="step-number">{step}</span><span>{label}</span>
      </li>
    </ol>
    """
  end

  attr :state, :string, required: true

  def status(assigns) do
    ~H"""
    <span class={"status status-#{String.downcase(@state)}"}>{@state}</span>
    """
  end
end
