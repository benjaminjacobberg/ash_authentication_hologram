defmodule AshAuthentication.Hologram.HooksTest do
  use ExUnit.Case, async: true

  alias AshAuthentication.Hologram.Hooks

  setup do
    original_session_key =
      Application.get_env(:ash_authentication_hologram, :session_key)

    original_state_key =
      Application.get_env(:ash_authentication_hologram, :state_key)

    on_exit(fn ->
      if original_session_key do
        Application.put_env(:ash_authentication_hologram, :session_key, original_session_key)
      else
        Application.delete_env(:ash_authentication_hologram, :session_key)
      end

      if original_state_key do
        Application.put_env(:ash_authentication_hologram, :state_key, original_state_key)
      else
        Application.delete_env(:ash_authentication_hologram, :state_key)
      end
    end)

    user = %{id: 1, email: "test@example.com"}

    %{user: user}
  end

  defp build_server(session) do
    %Hologram.Server{session: session}
  end

  defp build_component(state \\ %{}) do
    %Hologram.Component{state: state}
  end

  describe "on_mount(:live_user_required, ...)" do
    test "sets user in component state when user exists in session", %{user: user} do
      server = build_server(%{"hologram_user" => user})
      component = build_component()

      {:cont, updated_component, _server} =
        Hooks.on_mount(:live_user_required, %{}, component, server)

      assert updated_component.state[:current_user] == user
    end

    test "raises when no user in session" do
      server = build_server(%{})
      component = build_component()

      assert_raise RuntimeError, ~r/Authentication required/, fn ->
        Hooks.on_mount(:live_user_required, %{}, component, server)
      end
    end

    test "raises when session key exists but value is nil" do
      server = build_server(%{"hologram_user" => nil})
      component = build_component()

      assert_raise RuntimeError, ~r/Authentication required/, fn ->
        Hooks.on_mount(:live_user_required, %{}, component, server)
      end
    end
  end

  describe "on_mount(:live_user_optional, ...)" do
    test "sets user in component state when user exists in session", %{user: user} do
      server = build_server(%{"hologram_user" => user})
      component = build_component()

      {:cont, updated_component, _server} =
        Hooks.on_mount(:live_user_optional, %{}, component, server)

      assert updated_component.state[:current_user] == user
    end

    test "sets nil in component state when no user in session" do
      server = build_server(%{})
      component = build_component()

      {:cont, updated_component, _server} =
        Hooks.on_mount(:live_user_optional, %{}, component, server)

      assert updated_component.state[:current_user] == nil
    end
  end

  describe "on_mount(:live_no_user, ...)" do
    test "always sets nil in component state", %{user: user} do
      server = build_server(%{"hologram_user" => user})
      component = build_component()

      {:cont, updated_component, _server} =
        Hooks.on_mount(:live_no_user, %{}, component, server)

      assert updated_component.state[:current_user] == nil
    end

    test "sets nil when no user in session" do
      server = build_server(%{})
      component = build_component()

      {:cont, updated_component, _server} =
        Hooks.on_mount(:live_no_user, %{}, component, server)

      assert updated_component.state[:current_user] == nil
    end
  end

  describe "on_mount with custom keys" do
    test "uses configured session_key", %{user: user} do
      Application.put_env(:ash_authentication_hologram, :session_key, "custom_session")
      server = build_server(%{"custom_session" => user})
      component = build_component()

      {:cont, updated_component, _server} =
        Hooks.on_mount(:live_user_required, %{}, component, server)

      assert updated_component.state[:current_user] == user
    end

    test "uses configured state_key", %{user: user} do
      Application.put_env(:ash_authentication_hologram, :state_key, :user)
      server = build_server(%{"hologram_user" => user})
      component = build_component()

      {:cont, updated_component, _server} =
        Hooks.on_mount(:live_user_required, %{}, component, server)

      assert updated_component.state[:user] == user
    end
  end
end
