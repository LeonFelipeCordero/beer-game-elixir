defmodule BeerGameWeb.LandingPageTest do
  use BeerGameWeb.ConnCase

  test "GET / renders the game entry form and modern root layout", %{conn: conn} do
    html = conn |> get(~p"/") |> html_response(200)
    assert html =~ ~s(phx-submit="join_board")
    assert html =~ "Join Board"
    assert html =~ ~s(href="/board/new")
    assert html =~ ~s(name="csrf-token")
  end
end
