defmodule AshAuthentication.Hologram.Plug do
  @moduledoc """
  Plug that bridges AshAuthentication session data to Hologram pages.

  Loads the current user via `AshAuthentication.Plug.Helpers.retrieve_from_session/2`,
  serializes it into the Hologram server session, and redirects unauthenticated users
  away from protected routes.

  Protected routes are automatically discovered by introspecting loaded modules
  for Hologram pages that declare `__requires_auth__/0 == true`.

  ## Setup

  Add to your endpoint pipeline after `:fetch_session`:

      plug :fetch_session
      plug AshAuthentication.Hologram.Plug
      plug Hologram.Router
  """

  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  alias AshAuthentication.Plug.Helpers, as: AuthHelpers

  @spec init(keyword()) :: keyword()
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, _opts) do
    conn = AuthHelpers.retrieve_from_session(conn, AshAuthentication.Hologram.otp_app())

    case conn.assigns[:current_user] do
      nil ->
        if requires_auth?(conn.request_path) do
          conn
          |> put_session(:return_to, safe_return_path(conn.request_path))
          |> redirect(to: AshAuthentication.Hologram.sign_in_path())
          |> halt()
        else
          conn
        end

      user ->
        serialized = AshAuthentication.Hologram.serialize_user(user)
        put_session(conn, AshAuthentication.Hologram.session_key(), serialized)
    end
  end

  defp requires_auth?(path) do
    path in protected_paths()
  end

  defp safe_return_path(path) do
    if String.starts_with?(path, "/") and not String.starts_with?(path, "//") do
      path
    else
      "/"
    end
  end

  defp protected_paths do
    case :persistent_term.get({__MODULE__, :protected_paths}, :not_cached) do
      :not_cached ->
        paths = discover_protected_paths()
        :persistent_term.put({__MODULE__, :protected_paths}, paths)
        paths

      paths ->
        paths
    end
  end

  @doc """
  Clears the cached protected paths. Call this if pages are recompiled.
  """
  @spec clear_cache() :: :ok
  def clear_cache do
    :persistent_term.erase({__MODULE__, :protected_paths})
  end

  defp discover_protected_paths do
    :code.all_loaded()
    |> Enum.filter(fn {mod, _file} -> hologram_page_with_auth?(mod) end)
    |> Enum.map(fn {mod, _file} -> mod.__route__() end)
    |> MapSet.new()
  end

  defp hologram_page_with_auth?(module) do
    function_exported?(module, :__is_hologram_page__, 0) and
      function_exported?(module, :__requires_auth__, 0) and
      function_exported?(module, :__route__, 0) and
      module.__requires_auth__()
  end
end
