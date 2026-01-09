defmodule ResumeWeb.AppComponents do
  use Phoenix.Component
  use ResumeWeb, :verified_routes

  def toolbar(assigns) do
    style =
      "transition-property: color, background-color, border-color, text-decoration-color, fill, stroke; transition-timing-function: cubic-bezier(.4, 0, .2, 1); transition-duration: .15s;"

    class = "p-2 sm:p-5 text-gray-400 hover:text-[#20d8f8]"

    assigns =
      assigns
      |> assign(:class, class)
      |> assign(:style, style)

    ~H"""
    <div class="flex justify-center sm:justify-start flex-row-reverse w-full text-gray-400 p-4">
      <.link href={~p"/contact"} style={@style} class={@class}>Contact</.link>
      <.link href={~p"/projects"} style={@style} class={@class}>Projects</.link>
      <.link href={~p"/skills"} style={@style} class={@class}>Skills</.link>
      <.link href={~p"/about"} style={@style} class={@class}>About</.link>
      <.link href={~p"/"} style={@style} class={@class}>Home</.link>
    </div>
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"
  slot :inner_block, required: true

  def page(assigns) do
    ~H"""
    <div class="container mx-auto px-6 z-10 animate-fade-in min-h-screen">
      <div class="absolute top-0 left-0 right-0 z-20">
        <.toolbar />
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
      <div class="pt-20 h-full relative z-10">
        {render_slot(@inner_block)}
      </div>
      <ResumeWeb.Layouts.flash_group flash={@flash} />
    </div>
    """
  end
end
