defmodule Mix.Tasks.Train do
  @moduledoc """
  Train an Axon model to classify chess pieces.
  """

  use Mix.Task
  alias ChessVision.ImageRecognition.{Model, Model.Training}

  @requirements ["app.start"]
  @grayscale 1

  @impl Mix.Task
  @shortdoc "Train an Axon model to classify chess pieces."
  def run(_) do
    [{%{shape: {size}}, _} | _] = data = load_data()
    model = Model.new({@grayscale, size, size})
    training_count = floor(0.8 * Enum.count(data))
    {training_data, test_data} = Enum.split(data, training_count)

    Mix.Shell.IO.info("training...")
    state = Model.train(model, training_data)

    Mix.Shell.IO.info("testing...")
    Model.test(model, state, test_data)
    Model.save!(model, state)
  end

  def load_data() do
    "training_data/images/*.jpg"
    |> Path.wildcard()
    |> Enum.map(&Path.basename/1)
    |> Training.prepare_training_data()
  end
end
