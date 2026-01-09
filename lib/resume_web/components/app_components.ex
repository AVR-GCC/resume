defmodule ResumeWeb.AppComponents do
  use Phoenix.Component
  use ResumeWeb, :verified_routes

  attr :current_path, :string, default: "/"

  def toolbar(assigns) do
    style =
      "transition-property: color, background-color, border-color, text-decoration-color, fill, stroke; transition-timing-function: cubic-bezier(.4, 0, .2, 1); transition-duration: .15s;"

    base_class = "p-2 sm:p-5"
    default_class = "text-gray-400 hover:text-[#20d8f8]"
    selected_class = "text-[#057898]"

    assigns =
      assigns
      |> assign(:base_class, base_class)
      |> assign(:default_class, default_class)
      |> assign(:selected_class, selected_class)
      |> assign(:style, style)

    ~H"""
    <div class="flex justify-center sm:justify-start flex-row-reverse w-full text-gray-400 p-4">
      <.link
        href={~p"/contact"}
        style={@style}
        class={[
          @base_class,
          if(@current_path == "/contact", do: @selected_class, else: @default_class)
        ]}
      >
        Contact
      </.link>
      <.link
        href={~p"/projects"}
        style={@style}
        class={[
          @base_class,
          if(@current_path == "/projects", do: @selected_class, else: @default_class)
        ]}
      >
        Projects
      </.link>
      <.link
        href={~p"/skills"}
        style={@style}
        class={[
          @base_class,
          if(@current_path == "/skills", do: @selected_class, else: @default_class)
        ]}
      >
        Skills
      </.link>
      <.link
        href={~p"/about"}
        style={@style}
        class={[@base_class, if(@current_path == "/about", do: @selected_class, else: @default_class)]}
      >
        About
      </.link>
      <.link
        href={~p"/"}
        style={@style}
        class={[@base_class, if(@current_path == "/", do: @selected_class, else: @default_class)]}
      >
        Home
      </.link>
    </div>
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :current_path, :string, default: "/"
  slot :inner_block, required: true

  def page(assigns) do
    ~H"""
    <div class="container mx-auto px-6 z-10 animate-fade-in min-h-screen flex flex-col cursor-default">
      <div class="relative z-20">
        <.toolbar current_path={@current_path} />
      </div>
      <div class="fixed inset-0 z-0">
        <img
          src={~p"/images/hero-bg.jpg"}
          alt=""
          class="w-full h-full object-cover opacity-40"
        />
        <div class="absolute inset-0 bg-black/50" />
        <%!-- <div class="absolute inset-0 bg-gradient-to-b from-background/20 via-background/50 to-background" /> --%>
      </div>
      <div class="flex-1 relative z-10">
        {render_slot(@inner_block)}
      </div>
      <ResumeWeb.Layouts.flash_group flash={@flash} />
    </div>
    """
  end
end
