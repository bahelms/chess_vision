defmodule Mix.Tasks.Train do
  @moduledoc """
  Train an Axon model to classify chess pieces.
  """

  use Mix.Task
  alias ChessVision.ImageRecognition.{Model, Model.Training}

  @requirements ["app.start"]

  @impl Mix.Task
  @shortdoc "Train an Axon model to classify chess pieces."
  def run(_) do
    data = Training.prepare_training_data()
    training_count = floor(0.8 * Enum.count(data))
    validation_count = floor(0.2 * training_count)
    {training_data, test_data} = Enum.split(data, training_count)
    {validation_data, training_data} = Enum.split(training_data, validation_count)

    IO.inspect(training_count, label: "training_count")
    IO.inspect(validation_count, label: "validation_count")
    IO.inspect(length(test_data), label: "test_count")

    Mix.Shell.IO.info("training...")
    model = Model.new({32, 4, 226, 226})
    state = Model.train(model, training_data, validation_data)

    # Mix.Shell.IO.info("\ntesting...")
    Model.test(model, state, test_data)
    Model.save!(model, state)
  end
end
