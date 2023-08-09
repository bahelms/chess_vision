defmodule ChessVision.ImageRecognition.ModelTest do
  use ExUnit.Case, async: true
  alias ChessVision.ImageRecognition.Model

  test "prepare_image_data/1" do
    res = Model.prepare_image_data(["a1.jpg", "a2.jpg", "a3.jpg"])
    IO.inspect(res)
  end
end
