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
    data = Training.prepare_training_data()

    [{%{shape: {_, size}}, _} | _] = data
    model = Model.new({@grayscale, 64, size})
    # training_count = floor(0.8 * Enum.count(data))
    {training_data, test_data} = Enum.split(data, 1)

    Mix.Shell.IO.info("training...")
    state = Model.train(model, training_data, training_data)

    Mix.Shell.IO.info("\ntesting...")
    Model.test(model, state, test_data)
    Model.save!(model, state)
  end
end
