defmodule ChessVision.ImageRecognition.FEN do
  @file_map %{
    0 => "a",
    1 => "b",
    2 => "c",
    3 => "d",
    4 => "e",
    5 => "f",
    6 => "g",
    7 => "h"
  }

  def convert_to_map(fen) do
    {map, _} =
      fen
      |> String.split("/")
      |> Enum.reduce({%{}, 8}, fn rank, {map, rank_num} ->
        {parse_rank(rank, rank_num, map), rank_num - 1}
      end)

    map
  end

  def parse_rank(rank, rank_num, map) do
    {map, _} =
      rank
      |> String.split("", trim: true)
      |> Enum.reduce({map, 0}, fn value, {map, i} ->
        case Integer.parse(value) do
          {int, _} ->
            map =
              Enum.reduce(0..(int - 1), map, fn num, map ->
                Map.put(map, "#{@file_map[i + num]}#{rank_num}", "1")
              end)

            {map, i + int}

          _ ->
            {Map.put(map, "#{@file_map[i]}#{rank_num}", value), i + 1}
        end
      end)

    map
  end

  def encode_squares_to_fen(squares) do
    squares
    |> Enum.group_by(& &1.rank)
    |> Enum.reduce(%{}, fn {rank, squares}, acc ->
      Map.put(acc, rank, encode_fen_for_rank(squares))
    end)
    |> Map.to_list()
    |> List.keysort(0, :desc)
    |> Enum.map(fn {_, rank_fen} -> rank_fen end)
    |> Enum.join("/")
  end

  defp encode_fen_for_rank(squares) do
    squares
    |> Enum.sort_by(& &1.file)
    |> Enum.map(& &1.fen_value)
    |> List.foldr({[], 0}, fn value, {values, sum} ->
      case Integer.parse(value) do
        {1, ""} ->
          {values, sum + 1}

        :error ->
          if sum != 0 do
            {[value | [Integer.to_string(sum) | values]], 0}
          else
            {[value | values], 0}
          end
      end
    end)
    |> elem(0)
    |> Enum.join()
  end
end
