defmodule ChessVision.ImageRecognition.Model.Training do
  @moduledoc """
  label format: R N B Q K P r n b q k p empty
  Uppercase is white.
  """

  @type image :: Nx.Tensor
  @type label :: Nx.Tensor

  @spec prepare_training_data([String.t()]) :: [{image, label}]
  def prepare_training_data(filenames) do
    filenames
    |> pair_with_labels()
    |> read_image_files()
    |> pad_trailing_image_bytes()
    |> convert_to_tensors()
  end

  defp pair_with_labels(filenames) do
    filenames
    |> Enum.map(&{&1, label_map()[&1]})
    |> Enum.reduce({[], []}, fn {image, label}, {images, labels} = acc ->
      acc
      |> put_elem(0, [image | images])
      |> put_elem(1, [label | labels])
    end)
  end

  defp read_image_files({filenames, labels}) do
    images =
      filenames
      |> Enum.map(&"#{images_dir()}/#{&1}")
      |> Enum.map(&File.read!/1)

    {images, labels}
  end

  defp images_dir(), do: "training_data/images"

  # So all images have the same length
  defp pad_trailing_image_bytes({images, labels}) do
    max_size = find_max_byte_size(images)

    images =
      Enum.map(images, fn img ->
        diff = max_size - byte_size(img)
        <<img::binary, 0::size(diff)-unit(8)>>
      end)

    {images, labels}
  end

  defp find_max_byte_size(images) do
    images
    |> Stream.map(&byte_size/1)
    |> Enum.max()
  end

  defp convert_to_tensors({images, labels}) do
    images
    |> Enum.zip(labels)
    |> Enum.map(fn {image, label} ->
      {Nx.from_binary(image, :u8), Nx.from_binary(label, :u8)}
    end)
  end

  # starting position labels
  defp label_map do
    %{
      "a1.jpg" => <<1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      "a2.jpg" => <<0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0>>,
      "a3.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "a4.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "a5.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "a6.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "a7.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0>>,
      "a8.jpg" => <<0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0>>,
      "b1.jpg" => <<0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      "b2.jpg" => <<0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0>>,
      "b3.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "b4.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "b5.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "b6.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "b7.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0>>,
      "b8.jpg" => <<0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0>>,
      "c1.jpg" => <<0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      "c2.jpg" => <<0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0>>,
      "c3.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "c4.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "c5.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "c6.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "c7.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0>>,
      "c8.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0>>,
      "d1.jpg" => <<0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      "d2.jpg" => <<0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0>>,
      "d3.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "d4.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "d5.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "d6.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "d7.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0>>,
      "d8.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0>>,
      "e1.jpg" => <<0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0>>,
      "e2.jpg" => <<0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0>>,
      "e3.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "e4.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "e5.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "e6.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "e7.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0>>,
      "e8.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0>>,
      "f1.jpg" => <<0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      "f2.jpg" => <<0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0>>,
      "f3.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "f4.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "f5.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "f6.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "f7.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0>>,
      "f8.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0>>,
      "g1.jpg" => <<0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      "g2.jpg" => <<0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0>>,
      "g3.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "g4.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "g5.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "g6.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "g7.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0>>,
      "g8.jpg" => <<0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0>>,
      "h1.jpg" => <<1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
      "h2.jpg" => <<0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0>>,
      "h3.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "h4.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "h5.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "h6.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
      "h7.jpg" => <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0>>,
      "h8.jpg" => <<0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0>>
    }
  end
end