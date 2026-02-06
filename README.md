# AshAuthenticationHologram

> **Note:** This is an unofficial project and is not affiliated with the official Ash project or Hologram.

> **Warning:** This project is in very early development and is not production ready. Use with caution.

## Installation

Add `ash_authentication_hologram` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ash_authentication_hologram, github: "benjaminjacobberg/ash_authentication_hologram"}
  ]
end
```

## Securing Pages

To secure a page so only authenticated users can access it:

1. **Use the authentication Page macro** - Replace `Hologram.Page` with `AshAuthentication.Hologram.Page`:

```elixir
defmodule MyApp.DashboardPage do
  use AshAuthentication.Hologram.Page

  # Your page code...
end
```

2. **Add the authentication hook** - Add `on_mount` with the `:live_user_required` hook in your page module:

```elixir
defmodule MyApp.DashboardPage do
  use AshAuthentication.Hologram.Page

  on_mount {AshAuthentication.Hologram.Hooks, :live_user_required}

  # Your page code...
end
```

This will:
- Redirect unauthenticated users to the sign-in page (default: `/sign-in`)
- Load the authenticated user into the component state under the key `:current_user`

3. **Configure the endpoint plug** - Add `AshAuthentication.Hologram.Plug` to your endpoint after `:fetch_session`:

```elixir
plug AshAuthentication.Hologram.Plug
```

### Available Hooks

| Hook | Description |
|------|-------------|
| `:live_user_required` | Requires authentication; redirects to sign-in if not authenticated |
| `:live_user_optional` | Authentication is optional; user may be nil |
| `:live_no_user` | Ensures no authenticated user (useful for sign-in/sign-up pages) |

### Configuration

Add to your `config/config.exs`:

```elixir
config :ash_authentication_hologram,
  otp_app: :my_app,
  sign_in_path: "/sign-in"        # optional, default: "/sign-in"
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc).

