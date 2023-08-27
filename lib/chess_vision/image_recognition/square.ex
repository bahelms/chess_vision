defmodule ChessVision.ImageRecognition.Square do
  defstruct [
    :name,
    :rank,
    :file,
    :width,
    :height,
    :pixels,
    :training_label,
    :predicted_label,
    :fen_value
  ]

  def new(filename) do
    path =
      Application.get_env(:chess_vision, :board_detection_output_dir)
      |> Path.join(filename)

    name = Path.basename(filename, Path.extname(filename))
    [file, rank] = String.split(name, "", trim: true)
    {:ok, image} = Pixels.read_file(path)

    %__MODULE__{
      name: name,
      rank: rank,
      file: file,
      width: image.width,
      height: image.height,
      pixels: image.data
    }
  end

  # Pixels returns RGBA data, so 4 channels
  def convert_to_tensor(square) do
    square.pixels
    |> Nx.from_binary(:u8)
    |> Nx.reshape({4, square.height, square.width})
    |> Nx.divide(255)
  end
end
