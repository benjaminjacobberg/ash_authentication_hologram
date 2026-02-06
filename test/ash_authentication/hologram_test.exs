defmodule AshAuthentication.HologramTest do
  use ExUnit.Case, async: true

  alias AshAuthentication.Hologram

  setup do
    original_env = Application.get_all_env(:ash_authentication_hologram)

    on_exit(fn ->
      # Clear all keys first
      for {key, _val} <- Application.get_all_env(:ash_authentication_hologram) do
        Application.delete_env(:ash_authentication_hologram, key)
      end

      # Restore originals
      for {key, val} <- original_env do
        Application.put_env(:ash_authentication_hologram, key, val)
      end
    end)

    :ok
  end

  describe "session_key/0" do
    test "returns default value" do
      Application.delete_env(:ash_authentication_hologram, :session_key)
      assert Hologram.session_key() == "hologram_user"
    end

    test "returns configured value" do
      Application.put_env(:ash_authentication_hologram, :session_key, "my_user")
      assert Hologram.session_key() == "my_user"
    end
  end

  describe "state_key/0" do
    test "returns default value" do
      Application.delete_env(:ash_authentication_hologram, :state_key)
      assert Hologram.state_key() == :current_user
    end

    test "returns configured value" do
      Application.put_env(:ash_authentication_hologram, :state_key, :user)
      assert Hologram.state_key() == :user
    end
  end

  describe "sign_in_path/0" do
    test "returns default value" do
      Application.delete_env(:ash_authentication_hologram, :sign_in_path)
      assert Hologram.sign_in_path() == "/sign-in"
    end

    test "returns configured value" do
      Application.put_env(:ash_authentication_hologram, :sign_in_path, "/login")
      assert Hologram.sign_in_path() == "/login"
    end
  end

  describe "serialize_user/1" do
    test "default serialization extracts id and email" do
      Application.delete_env(:ash_authentication_hologram, :serialize_user)
      user = %{id: 42, email: "alice@example.com", password_hash: "secret"}

      result = Hologram.serialize_user(user)

      assert result == %{id: 42, email: "alice@example.com"}
      refute Map.has_key?(result, :password_hash)
    end

    test "default serialization converts email to string" do
      Application.delete_env(:ash_authentication_hologram, :serialize_user)
      user = %{id: 1, email: :"atom@example.com"}

      result = Hologram.serialize_user(user)

      assert result.email == "atom@example.com"
      assert is_binary(result.email)
    end

    test "uses {mod, fun} callback when configured" do
      defmodule TestSerializer do
        def serialize(user), do: %{uid: user.id}
      end

      Application.put_env(
        :ash_authentication_hologram,
        :serialize_user,
        {TestSerializer, :serialize}
      )

      user = %{id: 99, email: "test@example.com"}
      assert Hologram.serialize_user(user) == %{uid: 99}
    end

    test "uses anonymous function callback when configured" do
      Application.put_env(
        :ash_authentication_hologram,
        :serialize_user,
        fn user -> %{name: user.name} end
      )

      user = %{id: 1, name: "Alice", email: "alice@example.com"}
      assert Hologram.serialize_user(user) == %{name: "Alice"}
    end
  end

  describe "otp_app/0" do
    test "raises when not configured" do
      Application.delete_env(:ash_authentication_hologram, :otp_app)

      assert_raise ArgumentError, fn ->
        Hologram.otp_app()
      end
    end

    test "returns configured value" do
      Application.put_env(:ash_authentication_hologram, :otp_app, :my_app)
      assert Hologram.otp_app() == :my_app
    end
  end
end
