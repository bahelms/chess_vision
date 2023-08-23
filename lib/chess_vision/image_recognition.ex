defmodule ChessVision.ImageRecognition do
  use Rustler, otp_app: :chess_vision, crate: "chess_vision"
  alias ChessVision.ImageRecognition.{Model, Model.Training, FEN}

  def convert_image_to_fen(image_file) do
    image_file
    |> detect_chessboard()
    |> classify_squares()
  end

  def detect_chessboard(_image_file), do: :erlang.nif_error(:nif_not_loaded)

  defp classify_squares(filenames) do
    {model, model_state} = Model.load!()

    filenames
    |> Enum.map(&Training.Square.new/1)
    |> Training.pad_trailing_image_bytes()
    |> Stream.map(fn square ->
      {square,
       square.bytes
       |> Nx.from_binary(:u8)
       |> Nx.reshape({1, byte_size(square.bytes)})}
    end)
    |> Stream.map(fn {square, square_tensor} ->
      label = Model.predict(model, model_state, square_tensor)

      IO.inspect(label, label: "label")

      square
      |> Map.put(:predicted_label, label)
      |> Map.put(:fen_value, Training.label_to_fen_value(label))
    end)
    |> FEN.encode_squares_to_fen()
    |> IO.inspect(label: "FEN")
  end
end
