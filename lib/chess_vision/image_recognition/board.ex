defmodule ChessVision.ImageRecognition.Board do
  defstruct [:name, :image_path, :fen, squares: []]

  alias ChessVision.ImageRecognition.FEN

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
