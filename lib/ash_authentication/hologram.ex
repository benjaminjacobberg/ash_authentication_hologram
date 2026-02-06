defmodule AshAuthentication.Hologram do
  @moduledoc """
  Authentication system for Hologram pages, powered by AshAuthentication.

  Provides on_mount hooks, a page macro, and an HTTP plug to bridge
  AshAuthentication session data into the Hologram component/server model.

  ## Configuration

      config :ash_authentication_hologram,
        otp_app: :my_app

  ## Quick Start

  1. Add `{:ash_authentication_hologram, "~> 0.1"}` to your deps
  2. Configure `:otp_app` in your config
  3. Use `AshAuthentication.Hologram.Page` in your pages instead of `Hologram.Page`
  4. Add `on_mount {AshAuthentication.Hologram.Hooks, :live_user_required}` to protected pages
  5. Add `plug AshAuthentication.Hologram.Plug` to your endpoint pipeline after `:fetch_session`
  """

  @doc "Returns the configured OTP app name. Raises if not configured."
  @spec otp_app() :: atom()
  def otp_app do
    Application.fetch_env!(:ash_authentication_hologram, :otp_app)
  end

  @doc "Returns the configured session key. Default: `\"hologram_user\"`."
  @spec session_key() :: String.t()
  def session_key do
    Application.get_env(:ash_authentication_hologram, :session_key, "hologram_user")
  end

  @doc "Returns the configured component state key. Default: `:current_user`."
  @spec state_key() :: atom()
  def state_key do
    Application.get_env(:ash_authentication_hologram, :state_key, :current_user)
  end

  @doc "Returns the configured sign-in redirect path. Default: `\"/sign-in\"`."
  @spec sign_in_path() :: String.t()
  def sign_in_path do
    Application.get_env(:ash_authentication_hologram, :sign_in_path, "/sign-in")
  end

  @doc """
  Serializes a user for storage in the Hologram server session.

  Uses the configured `:serialize_user` callback, or falls back to
  extracting `%{id, email}` from the user.
  """
  @spec serialize_user(any()) :: map()
  def serialize_user(user) do
    case Application.get_env(:ash_authentication_hologram, :serialize_user) do
      nil -> %{id: user.id, email: to_string(user.email)}
      {mod, fun} -> apply(mod, fun, [user])
      fun when is_function(fun, 1) -> fun.(user)
    end
  end
end
