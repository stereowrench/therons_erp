defmodule TheronsErpWeb.Router do
  use TheronsErpWeb, :router

  use AshAuthentication.Phoenix.Router

  import AshAuthentication.Plug.Helpers

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TheronsErpWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
    plug :set_actor, :user
  end

  scope "/", TheronsErpWeb do
    pipe_through :browser

    ash_authentication_live_session :authenticated_routes do
      # in each liveview, add one of the following at the top of the module:
      #
      # If an authenticated user must be present:
      # on_mount {TheronsErpWeb.LiveUserAuth, :live_user_required}
      #
      # If an authenticated user *may* be present:
      # on_mount {TheronsErpWeb.LiveUserAuth, :live_user_optional}
      #
      # If an authenticated user must *not* be present:
      # on_mount {TheronsErpWeb.LiveUserAuth, :live_no_user}
    end
  end

  scope "/", TheronsErpWeb do
    pipe_through :browser

    get "/", PageController, :home

    auth_routes AuthController, TheronsErp.Accounts.User, path: "/auth"
    sign_out_route AuthController

    ash_authentication_live_session :authentication_optional,
      on_mount: [
        {TheronsErpWeb.LiveUserAuth, :live_user_optional},
        TheronsErpWeb.Breadcrumbs,
        TheronsErpWeb.Nav
      ] do
      live "/product_categories", ProductCategoryLive.Index, :index
      live "/product_categories/new", ProductCategoryLive.Index, :new
      live "/product_categories/:id/edit", ProductCategoryLive.Index, :edit

      live "/product_categories/:id", ProductCategoryLive.Show, :show
      live "/product_categories/:id/show/edit", ProductCategoryLive.Show, :edit

      live "/products", ProductLive.Index, :index
      live "/products/new", ProductLive.Index, :new

      live "/products/:id", ProductLive.Show, :show

      live "/sales_orders", SalesOrderLive.Index, :index
      live "/sales_orders/:id/edit", SalesOrderLive.Index, :edit

      live "/sales_orders/:id", SalesOrderLive.Show, :show
      live "/sales_orders/:id/show/edit", SalesOrderLive.Show, :edit

      live "/people", EntityLive.Index, :index
      live "/people/new", EntityLive.Index, :new
      live "/people/:id/edit", EntityLive.Index, :edit

      live "/people/:id", EntityLive.Show, :show
      live "/people/:id/new_address", EntityLive.Show, :new_address
      live "/people/:id/show/edit", EntityLive.Show, :edit
    end

    # Remove these if you'd like to use your own authentication views
    sign_in_route register_path: "/register",
                  reset_path: "/reset",
                  auth_routes_prefix: "/auth",
                  on_mount: [{TheronsErpWeb.LiveUserAuth, :live_no_user}],
                  overrides: [
                    TheronsErpWeb.AuthOverrides,
                    AshAuthentication.Phoenix.Overrides.Default
                  ]

    # Remove this if you do not want to use the reset password feature
    reset_route auth_routes_prefix: "/auth",
                overrides: [
                  TheronsErpWeb.AuthOverrides,
                  AshAuthentication.Phoenix.Overrides.Default
                ]
  end

  # Other scopes may use custom stacks.
  # scope "/api", TheronsErpWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:therons_erp, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TheronsErpWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
