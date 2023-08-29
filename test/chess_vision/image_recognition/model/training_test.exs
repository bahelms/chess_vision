defmodule ChessVision.ImageRecognition.Model.TrainingTest do
  use ExUnit.Case, async: true
  alias ChessVision.ImageRecognition.Model.Training

  test "label_to_fen_value/1" do
    assert Training.label_to_fen_value(2) == "B"
    assert Training.label_to_fen_value(4) == "K"
    assert Training.label_to_fen_value(12) == "1"
  end
end
