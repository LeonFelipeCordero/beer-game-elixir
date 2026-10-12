defmodule BeerGameWeb do
  @moduledoc """
  Shared definitions for the web interface.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json]
      use Gettext, backend: BeerGameWeb.Gettext
      import Plug.Conn
      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView, layout: {BeerGameWeb.Layouts, :live}
      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent
      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component
      unquote(html_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router, helpers: false
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      use Gettext, backend: BeerGameWeb.Gettext
    end
  end

  defp html_helpers do
    quote do
      use Gettext, backend: BeerGameWeb.Gettext
      import Phoenix.HTML
      import Phoenix.Controller, only: [get_csrf_token: 0]
      import BeerGameWeb.LiveHelpers
      import BeerGameWeb.ErrorHelpers
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: BeerGameWeb.Endpoint,
        router: BeerGameWeb.Router,
        statics: BeerGameWeb.static_paths()
    end
  end

  defmacro __using__(which) when is_atom(which), do: apply(__MODULE__, which, [])
end
