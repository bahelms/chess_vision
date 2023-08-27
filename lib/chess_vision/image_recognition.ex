defmodule ChessVision.ImageRecognition do
  use Rustler, otp_app: :chess_vision, crate: "chess_vision"
  alias ChessVision.ImageRecognition.{Model, Model.Training, FEN, Square}

  def convert_image_to_fen(image_file) do
    image_file
    |> detect_chessboard()
    |> classify_squares()
  end

  def detect_chessboard(_image_file), do: :erlang.nif_error(:nif_not_loaded)

  defp classify_squares(filenames) do
    {model, state} = Model.load!()

    filenames
    |> Stream.map(&Square.new/1)
    |> Stream.map(&convert_to_tensor/1)
    |> Stream.map(&predict_and_parse_label(&1, model, state))
    |> FEN.encode_squares_to_fen()
  end

  # stack to create a shape of [1][4][226][226]
  defp convert_to_tensor(square) do
    {square,
     square
     |> Square.convert_to_tensor()
     |> Nx.stack()}
  end

  defp predict_and_parse_label({square, tensor}, model, state) do
    label = Model.predict(model, state, tensor)

    square
    |> Map.put(:predicted_label, label)
    |> Map.put(:fen_value, Training.label_to_fen_value(label))
  end
end
