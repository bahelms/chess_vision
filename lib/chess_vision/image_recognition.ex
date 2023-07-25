defmodule ChessVision.ImageRecognition do
  use Rustler, otp_app: :chess_vision, crate: "chess_vision"

  def canny_edge_detection(_image_path), do: :erlang.nif_error(:nif_not_loaded)
end