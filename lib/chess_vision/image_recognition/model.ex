defmodule ChessVision.ImageRecognition.Model do
  @moduledoc """
  label format: R N B Q K P r n b q k p none
  """

  def prepare_image_data(files) do
    files
    |> read_image_files()
    |> Enum.map(&Nx.from_binary(&1, :u8))
  end

  defp read_image_files(files) do
    files
    |> Enum.map(&"#{images_dir()}/#{&1}")
    |> Enum.map(&File.read!/1)
  end

  defp images_dir(), do: "training_data"
end
