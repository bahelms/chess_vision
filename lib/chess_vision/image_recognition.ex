defmodule ChessVision.ImageRecognition do
  use Rustler, otp_app: :chess_vision, crate: "chess_vision"

  def convert_image_to_fen(image_path) do
    image_path
    |> detect_chessboard()
  end

  def detect_chessboard(_image_path), do: :erlang.nif_error(:nif_not_loaded)
end
