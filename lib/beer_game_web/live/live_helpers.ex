defmodule BeerGameWeb.LiveHelpers do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :return_to, :string, default: nil
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div id="modal" class="phx-modal fade-in" phx-remove={hide_modal()}>
      <div
        id="modal-content"
        class="phx-modal-content fade-in-scale"
        phx-click-away={JS.dispatch("click", to: "#close")}
        phx-window-keydown={JS.dispatch("click", to: "#close")}
        phx-key="escape"
      >
        <.link
          :if={@return_to}
          patch={@return_to}
          id="close"
          class="phx-modal-close"
          phx-click={hide_modal()}
        >✖</.link>
        <a :if={!@return_to} id="close" href="#" class="phx-modal-close" phx-click={hide_modal()}>✖</a>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp hide_modal(js \\ %JS{}) do
    js
    |> JS.hide(to: "#modal", transition: "fade-out")
    |> JS.hide(to: "#modal-content", transition: "fade-out-scale")
  end
end
