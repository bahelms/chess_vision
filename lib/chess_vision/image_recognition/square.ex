defmodule ChessVision.ImageRecognition.Square do
  defstruct [:name, :rank, :file, :bytes, :training_label, :predicted_label, :fen_value]

  def new(filename) do
    path =
      Application.get_env(:chess_vision, :board_detection_output_dir)
      |> Path.join(filename)

    name = Path.basename(filename, Path.extname(filename))
    [file, rank] = String.split(name, "", trim: true)

    %__MODULE__{
      name: name,
      rank: rank,
      file: file,
      bytes: File.read!(path)
    }
  end
end
