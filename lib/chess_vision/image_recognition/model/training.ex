defmodule ChessVision.ImageRecognition.Model.Training do
  @moduledoc """
  label format: R N B Q K P r n b q k p empty
  Uppercase is white.
  """

  alias ChessVision.ImageRecognition

  defmodule BoardImage do
    defstruct [:name, :image_path, :fen, squares: []]

    def new(image_path) do
      fen =
        "#{Path.rootname(image_path)}.fen"
        |> File.read!()
        |> String.trim()

      %__MODULE__{
        name: Path.basename(image_path),
        image_path: image_path,
        fen: fen
      }
    end
  end

  defmodule SquareImage do
    defstruct [:name, :bytes]

    def new(name) do
      path =
        Application.get_env(:chess_vision, :board_detection_output_dir)
        |> Path.join(name)

      %__MODULE__{name: name, bytes: File.read!(path)}
    end
  end

  def prepare_training_data do
    load_images()
    |> Enum.map(fn board_image ->
      squares =
        board_image.image_path
        |> ImageRecognition.detect_chessboard()
        |> Enum.map(&SquareImage.new/1)
        |> pad_trailing_image_bytes()

      Map.put(board_image, :squares, squares)
    end)

    # |> convert_to_tensors()
  end

  defp load_images() do
    Application.get_env(:chess_vision, :training_data_images_dir)
    |> Path.join("*.png")
    |> Path.wildcard()
    |> Enum.map(&BoardImage.new/1)
  end

  # So all images have the same length
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
