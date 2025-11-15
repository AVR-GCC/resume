defmodule ResumeWeb.AppComponents do
  use Phoenix.Component
  use ResumeWeb, :verified_routes

  def toolbar(assigns) do
    ~H"""
    <div class={["flex flex-row-reverse w-full text-white p-4"]}>
      <.link href={~p"/contact"} class="p-5">Contact</.link>
      <.link href={~p"/market-sim"} class="p-5">Market Simulation</.link>
      <.link href={~p"/projects"} class="p-5">Projects</.link>
      <.link href={~p"/skills"} class="p-5">Skills</.link>
      <.link href={~p"/about"} class="p-5">About</.link>
      <.link href={~p"/"} class="p-5">Home</.link>
    </div>
    """
  end

  slot :inner_block, required: true

  def page(assigns) do
    ~H"""
    <div class="container mx-auto px-6 z-10 animate-fade-in min-h-screen">
      <div class="absolute top-0 left-0 right-0 z-20">
        <.toolbar />
      </div>
      <div class="absolute inset-0 z-0">
        <img
          src={~p"/images/hero-bg.jpg"}
          alt=""
          class="w-full h-full object-cover opacity-20"
        />
        <div class="absolute inset-0 bg-gradient-to-b from-background/50 via-background/80 to-background" />
      </div>
      <div class="pt-20 h-screen relative z-10">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
