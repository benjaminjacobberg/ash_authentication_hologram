defmodule AshAuthentication.Hologram.Hooks do
  @moduledoc """
  Authentication hooks for Hologram pages.

  Similar to the LiveView on_mount hooks in `ash_authentication_phoenix`,
  but adapted for Hologram's component/server model.

  ## Available hooks

  - `:live_user_required` - Requires authentication, loads user into component state
  - `:live_user_optional` - Optional authentication, user may be nil
  - `:live_no_user` - For pages that should not have an authenticated user (e.g., sign-in)
  """

  import Hologram.Server, only: [get_session: 2, get_session: 3]
  import Hologram.Component, only: [put_state: 3]

  @spec on_mount(atom(), map(), Hologram.Component.t(), Hologram.Server.t()) ::
          {:cont, Hologram.Component.t(), Hologram.Server.t()}
  def on_mount(:live_user_required, _params, component, server) do
    case get_session(server, AshAuthentication.Hologram.session_key()) do
      nil ->
        raise "Authentication required: no user found in session"

      user ->
        {:cont, put_state(component, AshAuthentication.Hologram.state_key(), user), server}
    end
  end

  def on_mount(:live_user_optional, _params, component, server) do
    user = get_session(server, AshAuthentication.Hologram.session_key(), nil)
    {:cont, put_state(component, AshAuthentication.Hologram.state_key(), user), server}
  end

  def on_mount(:live_no_user, _params, component, server) do
    {:cont, put_state(component, AshAuthentication.Hologram.state_key(), nil), server}
  end
end
