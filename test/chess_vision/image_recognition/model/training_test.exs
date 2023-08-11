defmodule ChessVision.ImageRecognition.Model.TrainingTest do
  use ExUnit.Case, async: true
  alias ChessVision.ImageRecognition.Model.Training

  test "prepare_image_data/1" do
    res = Training.prepare_training_data(["a1.jpg", "a2.jpg", "a3.jpg"])
    IO.inspect(res)
  end
end
