defmodule ChessVision.ImageRecognition.Model.Training do
  @moduledoc """
  label format: R N B Q K P r n b q k p 1
  Uppercase is white. 1 means the square is empty.
  """

  alias ChessVision.ImageRecognition
  alias ChessVision.ImageRecognition.{Square, Board}

  @label_list ["R", "N", "B", "Q", "K", "P", "r", "n", "b", "q", "k", "p", "1"]
  @label_map %{
    "R" => <<1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
    "N" => <<0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
    "B" => <<0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
    "Q" => <<0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
    "K" => <<0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0>>,
    "P" => <<0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0>>,
    "r" => <<0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0>>,
    "n" => <<0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0>>,
    "b" => <<0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0>>,
    "q" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0>>,
    "k" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0>>,
    "p" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0>>,
    "1" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>
  }

  def prepare_training_data do
    load_boards()
    |> detect_board_squares()
    |> convert_to_labelled_tensors()
    |> batch()
  end

  defp load_boards() do
    Application.get_env(:chess_vision, :training_data_images_dir)
    |> Path.join("*.png")
    |> Path.wildcard()
    |> Enum.map(&Board.new/1)
  end

  defp detect_board_squares(boards) do
    Stream.flat_map(boards, fn board ->
      board.image_path
      |> ImageRecognition.detect_chessboard()
      |> Stream.map(&Square.new/1)
      |> Stream.map(&label_square(&1, board.fen))
    end)
  end

  defp label_square(square, fen) do
    Map.put(square, :training_label, @label_map[fen[square.name]])
  end

  defp convert_to_labelled_tensors(squares) do
    Stream.map(squares, fn square ->
      {Square.convert_to_tensor(square), Nx.from_binary(square.training_label, :u8)}
    end)
  end

  defp batch(squares_with_labels) do
    squares_with_labels
    |> Stream.chunk_every(32)
    |> Stream.map(fn squares_with_labels ->
      {squares, labels} = Enum.unzip(squares_with_labels)
      {Nx.stack(squares), Nx.stack(labels)}
    end)
  end

  def label_to_fen_value(label_index) do
    Enum.at(@label_list, label_index)
  end
end
