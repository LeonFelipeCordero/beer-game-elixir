defmodule BeerGameWeb.ErrorTest do
  use ExUnit.Case, async: true

  test "renders HTML errors without legacy Phoenix.View" do
    assert BeerGameWeb.ErrorHTML.render("404.html", %{}) == "Not Found"
    assert BeerGameWeb.ErrorHTML.render("500.html", %{}) == "Internal Server Error"
  end

  test "renders JSON errors" do
    assert BeerGameWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}

    assert BeerGameWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
