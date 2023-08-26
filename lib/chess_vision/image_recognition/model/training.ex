defmodule ChessVision.ImageRecognition.Model.Training do
  @moduledoc """
  label format: R N B Q K P r n b q k p 1
  Uppercase is white. 1 means the square is empty.
  """

  alias ChessVision.ImageRecognition
  alias ChessVision.ImageRecognition.{Square, Board}

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

    # |> convert_to_tensors()
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

      # |> pad_trailing_image_bytes()
    end)
  end

  defp label_square(square, fen) do
    Map.put(square, :training_label, @label_map[fen[square.name]])
  end

  # So all images have the same length
  # This may be better to do with OpenCV inside detect_chessboard/1 but binaries are fun!
  def pad_trailing_image_bytes(square_images) do
    max_size = find_max_byte_size(square_images)

    Enum.map(square_images, fn image ->
      diff = max_size - byte_size(image.bytes)
      Map.put(image, :bytes, <<image.bytes::binary, 0::size(diff)-unit(8)>>)
    end)
  end

  defp find_max_byte_size(images) do
    images
    |> Stream.map(&byte_size(&1.bytes))
    |> Enum.max()
  end

  defp convert_to_tensors(boards) do
    Enum.map(boards, fn board ->
      {bytes, labels} =
        Enum.map(board.squares, fn square ->
          {square.bytes, square.training_label}
        end)
        |> Enum.reduce({<<>>, <<>>}, fn {bytes, label}, {all_bytes, all_labels} ->
          {all_bytes <> bytes, all_labels <> label}
        end)

      squares_tensor = Nx.from_binary(bytes, :u8) |> Nx.reshape({64, :auto}) |> Nx.divide(255)
      labels_tensor = Nx.from_binary(labels, :u8) |> Nx.reshape({64, :auto})
      {squares_tensor, labels_tensor}
    end)
  end

  def label_to_fen_value(label_index) do
    Map.keys(@label_map)
    |> Enum.at(label_index)
  end
end
