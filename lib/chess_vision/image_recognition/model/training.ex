defmodule ChessVision.ImageRecognition.Model.Training do
  @moduledoc """
  label format: R N B Q K P r n b q k p empty
  Uppercase is white.
  """

  alias ChessVision.ImageRecognition

  defmodule FEN do
    @file_map %{
      0 => "a",
      1 => "b",
      2 => "c",
      3 => "d",
      4 => "e",
      5 => "f",
      6 => "g",
      7 => "h"
    }

    def convert_to_map(fen) do
      # r1b2rk1/p4pbp/2p1p1p1/q3N3/5B2/2N4P/PP3PP1/R2QK2R
      # label_map = %{
      #   "R" => <<1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      #   "N" => <<0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      #   "B" => <<0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      #   "Q" => <<0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      #   "K" => <<0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0>>,
      #   "P" => <<0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0>>,
      #   "r" => <<0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0>>,
      #   "n" => <<0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0>>,
      #   "b" => <<0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0>>,
      #   "q" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0>>,
      #   "k" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0>>,
      #   "p" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0>>,
      #   "empty" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>
      # }

      {map, _} =
        fen
        |> String.split("/")
        |> Enum.reduce({%{}, 8}, fn rank, {map, rank_num} ->
          map = parse_rank(rank, rank_num, map)
          {map, rank_num - 1}
        end)

      map
    end

    def parse_rank(rank, rank_num, map) do
      {map, _} =
        rank
        |> String.split("", trim: true)
        |> Enum.reduce({map, 0}, fn value, {map, i} ->
          case Integer.parse(value) do
            {int, _} ->
              map =
                Enum.reduce(0..(int - 1), map, fn num, map ->
                  Map.put(map, "#{@file_map[i + num]}#{rank_num}", "empty")
                end)

              {map, i + int}

            _ ->
              {Map.put(map, "#{@file_map[i]}#{rank_num}", value), i + 1}
          end
        end)

      map
    end
  end

  defmodule Board do
    defstruct [:name, :image_path, :fen, squares: []]

    def new(image_path) do
      fen =
        "#{Path.rootname(image_path)}.fen"
        |> File.read!()
        |> String.trim()
        |> FEN.convert_to_map()

      %__MODULE__{
        name: Path.basename(image_path),
        image_path: image_path,
        fen: fen
      }
    end
  end

  defmodule Square do
    defstruct [:name, :bytes, :label]

    def new(filename) do
      path =
        Application.get_env(:chess_vision, :board_detection_output_dir)
        |> Path.join(filename)

      %__MODULE__{
        name: Path.basename(filename, Path.extname(filename)),
        bytes: File.read!(path)
      }
    end
  end

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
    Enum.map(boards, fn board ->
      squares =
        board.image_path
        |> ImageRecognition.detect_chessboard()
        |> Stream.map(&Square.new/1)
        # |> Stream.map(&label_square(&1, board.fen))
        |> pad_trailing_image_bytes()

      Map.put(board, :squares, squares)
    end)
  end

  # So all images have the same length
  # This may be better to do inside detect_chessboard/1 but binaries are fun!
  defp pad_trailing_image_bytes(square_images) do
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

  # defp convert_to_tensors({images, labels}) do
  #   images
  #   |> Enum.zip(labels)
  #   |> Enum.map(fn {image, label} ->
  #     {Nx.from_binary(image, :u8), Nx.from_binary(label, :u8)}
  #   end)
  # end
end
