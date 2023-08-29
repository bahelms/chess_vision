defmodule ChessVision.ImageRecognition.Board do
  defstruct [:image_path, :fen, squares: []]

  alias ChessVision.ImageRecognition.FEN

  def new(image_path) do
    fen =
      image_path
      |> Path.basename()
      |> Path.rootname()
      |> FEN.convert_to_map(delimiter: "-")

    %__MODULE__{
      image_path: image_path,
      fen: fen
    }
  end
end
