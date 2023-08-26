defmodule ChessVision.ImageRecognition.FENTest do
  use ExUnit.Case, async: true
  alias ChessVision.ImageRecognition.FEN
  alias ChessVision.ImageRecognition.Square

  test "convert_to_map/1" do
    map = FEN.convert_to_map("r1b2rk1/p4pbp/2p1p1p1/q3N3/5B2/2N4P/PP3PP1/R2QK2R")
    assert map["a1"] == "R"
    assert map["b1"] == "1"
    assert map["c1"] == "1"
    assert map["d1"] == "Q"
    assert map["e1"] == "K"
    assert map["f1"] == "1"
    assert map["g1"] == "1"
    assert map["h1"] == "R"
  end

  test "parse_rank/2" do
    map = FEN.parse_rank("R2QK2R", 1, %{})
    assert map["a1"] == "R"
    assert map["b1"] == "1"
    assert map["c1"] == "1"
    assert map["d1"] == "Q"
    assert map["e1"] == "K"
    assert map["f1"] == "1"
    assert map["g1"] == "1"
    assert map["h1"] == "R"
  end

  test "encode_squares_to_fen/1" do
    fen =
      [
        %Square{file: "a", rank: "8", fen_value: "r"},
        %Square{file: "b", rank: "8", fen_value: "1"},
        %Square{file: "c", rank: "8", fen_value: "b"},
        %Square{file: "d", rank: "8", fen_value: "1"},
        %Square{file: "e", rank: "8", fen_value: "1"},
        %Square{file: "f", rank: "8", fen_value: "r"},
        %Square{file: "g", rank: "8", fen_value: "k"},
        %Square{file: "h", rank: "8", fen_value: "1"},
        %Square{file: "a", rank: "7", fen_value: "p"},
        %Square{file: "b", rank: "7", fen_value: "1"},
        %Square{file: "c", rank: "7", fen_value: "1"},
        %Square{file: "d", rank: "7", fen_value: "1"},
        %Square{file: "e", rank: "7", fen_value: "1"},
        %Square{file: "f", rank: "7", fen_value: "p"},
        %Square{file: "g", rank: "7", fen_value: "b"},
        %Square{file: "h", rank: "7", fen_value: "p"}
      ]
      |> FEN.encode_squares_to_fen()

    assert fen == "r1b2rk1/p4pbp"
  end
end
