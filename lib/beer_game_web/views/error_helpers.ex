defmodule BeerGameWeb.ErrorHelpers do
  @moduledoc "Conveniences for translating changeset errors."

  def translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(BeerGameWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(BeerGameWeb.Gettext, "errors", msg, opts)
    end
  end
end
