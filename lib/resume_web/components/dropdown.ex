defmodule ResumeWeb.Components.Dropdown do
  import ResumeWeb.CoreComponents
  use Phoenix.LiveComponent

  attr :class, :string, default: ""
  attr :button_class, :string, default: ""
  attr :value, :string, required: true
  attr :values, :list, required: true

  def render(assigns) do
    ~H"""
    <div phx-click-away="close" phx-target={@myself}>
      <.button
        phx-click="toggle"
        phx-target={@myself}
        class={@button_class}
      >
        {@value || "Select"}
      </.button>
      <div :if={@open} class="absolute z-1">
        <.list class={@class}>
          <:item
            :for={value <- @values}
            title=""
          >
            <div
              phx-click="select"
              phx-target={@myself}
              phx-value-item={value}
            >
              {value}
            </div>
          </:item>
        </.list>
      </div>
    </div>
    """
  end

  def mount(socket) do
    {:ok, assign(socket, open: false, value: nil)}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    {:ok, socket}
  end

  def handle_event("close", _, socket) do
    {:noreply, assign(socket, open: false)}
  end

  def handle_event("toggle", _, socket) do
    {:noreply, assign(socket, open: !socket.assigns.open)}
  end

  def handle_event("select", %{"item" => item}, socket) do
    send(self(), {:strategy_selected, item})
    {:noreply, assign(socket, open: false, value: item)}
  end
end
