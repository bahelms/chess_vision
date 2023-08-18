defmodule ChessVision.ImageRecognition.Model.TrainingTest do
  use ExUnit.Case, async: true
  alias ChessVision.ImageRecognition.Model.Training.FEN

  test "convert_to_map/1" do
    map = FEN.convert_to_map("r1b2rk1/p4pbp/2p1p1p1/q3N3/5B2/2N4P/PP3PP1/R2QK2R")
    # IO.inspect(map)
    assert map["a1"] == "R"
    assert map["b1"] == "empty"
    assert map["c1"] == "empty"
    assert map["d1"] == "Q"
    assert map["e1"] == "K"
    assert map["f1"] == "empty"
    assert map["g1"] == "empty"
    assert map["h1"] == "R"
  end

  test "parse_rank/2" do
    map = FEN.parse_rank("R2QK2R", 1, %{})
    assert map["a1"] == "R"
    assert map["b1"] == "empty"
    assert map["c1"] == "empty"
    assert map["d1"] == "Q"
    assert map["e1"] == "K"
    assert map["f1"] == "empty"
    assert map["g1"] == "empty"
    assert map["h1"] == "R"
  end
end
