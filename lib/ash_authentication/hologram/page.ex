defmodule AshAuthentication.Hologram.Page do
  @moduledoc """
  Custom wrapper around `Hologram.Page` that adds `on_mount` macro for authentication hooks.

  ## Usage

      defmodule MyApp.Pages.DashboardPage do
        use AshAuthentication.Hologram.Page

        route "/app"
        layout MyApp.Layouts.HologramLayout
        on_mount {AshAuthentication.Hologram.Hooks, :live_user_required}

        def template do
          ~HOLO\"""
          <div>Welcome, {@current_user.email}!</div>
          \"""
        end
      end

  ## Available hooks

  See `AshAuthentication.Hologram.Hooks` for available authentication hooks.
  """

  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(_opts) do
    quote do
      use Hologram.Page

      import AshAuthentication.Hologram.Page, only: [on_mount: 1]

      Module.register_attribute(__MODULE__, :__on_mount_hooks__, accumulate: true)

      @before_compile AshAuthentication.Hologram.Page
    end
  end

  @doc """
  Registers an on_mount hook to be called during page initialization.

  ## Examples

      on_mount {AshAuthentication.Hologram.Hooks, :live_user_required}
      on_mount {AshAuthentication.Hologram.Hooks, :live_user_optional}
  """
  @spec on_mount(hook :: {module(), atom()}) :: Macro.t()
  defmacro on_mount({module, action}) do
    quote do
      Module.put_attribute(__MODULE__, :__on_mount_hooks__, {unquote(module), unquote(action)})
    end
  end

  @spec __before_compile__(Macro.Env.t()) :: Macro.t()
  defmacro __before_compile__(env) do
    hooks = Module.get_attribute(env.module, :__on_mount_hooks__) || []

    requires_auth? =
      Enum.any?(hooks, fn {_mod, action} ->
        action == :live_user_required
      end)

    auth_metadata =
      quote do
        @doc false
        def __requires_auth__, do: unquote(requires_auth?)
      end

    init_override =
      if hooks == [] do
        nil
      else
        quote do
          defoverridable init: 3

          def init(params, component, server) do
            {component, server} =
              Enum.reduce(
                unquote(Macro.escape(Enum.reverse(hooks))),
                {component, server},
                fn {module, action}, {comp, srv} ->
                  {:cont, comp, srv} = module.on_mount(action, params, comp, srv)
                  {comp, srv}
                end
              )

            super(params, component, server)
            |> AshAuthentication.Hologram.Page.normalize_init_result(component, server)
          end
        end
      end

    [auth_metadata, init_override]
  end

  @doc false
  @spec normalize_init_result(any(), Hologram.Component.t(), Hologram.Server.t()) ::
          {Hologram.Component.t(), Hologram.Server.t()}
  def normalize_init_result({comp, srv}, _component, _server), do: {comp, srv}
  def normalize_init_result(%Hologram.Component{} = comp, _component, server), do: {comp, server}
  def normalize_init_result(%Hologram.Server{} = srv, component, _server), do: {component, srv}
end
