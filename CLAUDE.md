# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AshAuthenticationHologram is an Elixir library that integrates [AshAuthentication](https://hex.pm/packages/ash_authentication) with [Hologram](https://hex.pm/packages/hologram), an Elixir-based frontend framework. It bridges AshAuthentication's session management into Hologram's component/server model.

## Common Commands

```bash
mix test                           # Run all tests
mix test test/path/to_test.exs:15  # Run single test at line 15
mix deps.get                       # Install dependencies
mix compile                        # Compile the project
mix format                         # Format code
mix credo                          # Run Credo linter
mix dialyzer                       # Run Dialyzer type checker
```

## Architecture

The library consists of four main modules in `lib/ash_authentication/hologram/`:

- **`Hologram`** - Configuration module with helper functions for `otp_app`, `session_key`, `state_key`, `sign_in_path`, and `serialize_user`. No behavior, just config accessors.

- **`Hologram.Page`** - Macro wrapper around `Hologram.Page` that adds `on_mount/1` macro for registering authentication hooks. Uses `@before_compile` callback to inject authentication logic into the page's `init/3` function.

- **`Hologram.Hooks`** - Implements the on_mount hooks:
  - `:live_user_required` - Requires auth, loads user into component state
  - `:live_user_optional` - Optional auth, user may be nil
  - `:live_no_user` - Ensures no authenticated user (for sign-in pages)

- **`Hologram.Plug`** - HTTP Plug that runs after `:fetch_session` in the endpoint pipeline. Retrieves the current user from AshAuthentication's session, serializes it into Hologram's session, and redirects unauthenticated users from protected routes. Uses `:persistent_term` to cache protected paths discovered via module introspection.

## Configuration

Required configuration in `config/config.exs`:

```elixir
config :ash_authentication_hologram,
  otp_app: :my_app
```

Optional settings:
- `:session_key` - Session key for storing user (default: `"hologram_user"`)
- `:state_key` - Component state key (default: `:current_user`)
- `:sign_in_path` - Redirect path for unauthenticated users (default: `"/sign-in"`)
- `:serialize_user` - Custom serialization function (default: extracts `%{id, email}`)

## Usage Pattern

1. Add `{:ash_authentication_hologram, github: "benjaminjacobberg/ash_authentication_hologram"}` to deps
2. Configure `:otp_app` in config
3. Use `AshAuthentication.Hologram.Page` instead of `Hologram.Page`
4. Add `on_mount {AshAuthentication.Hologram.Hooks, :live_user_required}` to protected pages
5. Add `plug AshAuthentication.Hologram.Plug` to endpoint after `:fetch_session`

## Commit Message Format

Commit messages follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

- **`fix:`** — patches a bug (PATCH semantic version)
- **`feat:`** — introduces a new feature (MINOR semantic version)
- **`BREAKING CHANGE:`** — breaking API change (MAJOR semantic version)

Other types: `build:`, `chore:`, `ci:`, `docs:`, `style:`, `refactor:`, `perf:`, `test:`

### Breaking Changes

- Prefix notation: `feat(parser)!:` (the `!` signals breaking change)
- Footer notation: `BREAKING CHANGE: description`

### Examples

```
feat: allow provided config object to extend other configs

fix: prevent racing of requests

docs: correct spelling of CHANGELOG

feat(lang): add Polish language
```
