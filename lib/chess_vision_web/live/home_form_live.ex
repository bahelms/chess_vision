defmodule ChessVisionWeb.HomeFormLive do
  use ChessVisionWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(uploaded_image: nil)
     |> allow_upload(:board_image, accept: ~w(image/*), max_entries: 1)}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("capture", _params, socket) do
    image_path = save_file(socket)
    ChessVision.ImageRecognition.canny_edge_detection(image_path)
    {:noreply, assign(socket, uploaded_image: image_path)}
  end

  defp save_file(socket) do
    consume_uploaded_entries(socket, :board_image, fn %{path: path}, _entry ->
      dest =
        Path.join([:code.priv_dir(:chess_vision), "static", "uploads", Path.basename(path)])

      File.cp!(path, dest)
      {:ok, "/uploads/#{Path.basename(dest)}"}
    end)
    |> List.first()
  end
end
