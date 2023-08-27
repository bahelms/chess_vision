defmodule ChessVision.ImageRecognition.Model do
  @label_elements_count 13

  def new(shape) do
    Axon.input("input_0", shape: shape)
    |> Axon.flatten()
    # |> Axon.dense(128, activation: :relu)
    |> Axon.relu()
    |> Axon.dense(@label_elements_count, activation: :softmax)
  end

  def train(model, training_data, validation_data) do
    model
    |> Axon.Loop.trainer(:categorical_cross_entropy, Axon.Optimizers.adam(0.01), log: 1)
    |> Axon.Loop.metric(:accuracy, "Accuracy")
    |> Axon.Loop.validate(model, validation_data)
    |> Axon.Loop.run(training_data, %{}, compiler: EXLA, epochs: 10)
  end

  def test(model, state, test_data) do
    model
    |> Axon.Loop.evaluator()
    |> Axon.Loop.metric(:accuracy, "Accuracy")
    |> Axon.Loop.run(test_data, state)
  end

  def predict(model, state, tensor) do
    Axon.predict(model, state, tensor)
    |> Nx.argmax()
    |> Nx.to_number()
  end

  def save!(model, state), do: File.write!(path(), Axon.serialize(model, state))

  def load! do
    path()
    |> File.read!()
    |> Axon.deserialize()
  end

  defp path, do: Path.join(:code.priv_dir(:chess_vision), "model.axon")
end
