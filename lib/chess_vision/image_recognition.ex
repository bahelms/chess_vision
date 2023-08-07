defmodule ChessVision.ImageRecognition do
  use Rustler, otp_app: :chess_vision, crate: "chess_vision"

  def convert_image_to_fen(image_file) do
    image_file
    |> detect_chessboard()
  end

  def detect_chessboard(_image_file), do: :erlang.nif_error(:nif_not_loaded)
end
