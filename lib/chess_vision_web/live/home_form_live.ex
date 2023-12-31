defmodule ChessVisionWeb.HomeFormLive do
  use ChessVisionWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(uploaded_image: nil, fen: nil)
     |> allow_upload(:board_image, accept: ~w(image/*), max_entries: 1)}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, assign(socket, :fen, nil)}
  end

  @impl Phoenix.LiveView
  def handle_event("capture", _params, socket) do
    image_path = save_file(socket)
    fen = ChessVision.ImageRecognition.convert_image_to_fen(image_path)
    image_file = Path.basename(image_path)
    {:noreply, assign(socket, uploaded_image: "uploads/#{image_file}", fen: fen)}
  end

  defp save_file(socket) do
    consume_uploaded_entries(socket, :board_image, fn %{path: path}, _entry ->
      dest =
        Application.app_dir(:chess_vision, "priv/static/uploads")
        |> Path.join(Path.basename(path))

      File.cp!(path, dest)
      {:ok, dest}
    end)
    |> List.first()
  end
end
