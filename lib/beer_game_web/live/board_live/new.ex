defmodule BeerGameWeb.BoardLive.New do
  use BeerGameWeb, :live_view

  alias BeerGame.Boards
  alias BeerGame.Game.Board

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "New Board")
     |> assign(:form, to_form(Boards.change_board(%Board{}), as: nil))}
  end

  @impl true
  def handle_event("create_board", %{"name" => name}, socket) do
    case Boards.create_board(%{name: name}) do
      {:ok, board} ->
        {:noreply,
         socket
         |> put_flash(:info, "Board created successfully")
         |> push_navigate(to: ~p"/board/#{board}/player")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: nil))}
    end
  end
end
