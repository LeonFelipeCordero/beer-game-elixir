defmodule BeerGameWeb.LandingLive.Index do
  use BeerGameWeb, :live_view

  alias BeerGame.Boards

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "BeerGame", form: to_form(%{"name" => ""}))}
  end

  @impl true
  def handle_event("join_board", %{"name" => name}, socket) do
    case Boards.get_by_name(name) do
      nil -> {:noreply, put_flash(socket, :error, "Board not found")}
      board -> {:noreply, push_navigate(socket, to: ~p"/board/#{board}/player")}
    end
  end
end
