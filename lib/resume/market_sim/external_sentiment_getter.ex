defmodule ExternalSentimentGetter do
  use Agent

  def start_link(args) do
    Agent.start_link(fn -> args end, name: :external_sentiment_getter)
  end

  def update_sentiment do
    Agent.update(:external_sentiment_getter, fn state ->
      %{url: url} = state
      case HTTPoison.get(url, [], recv_timeout: 5000) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          value = body |> String.trim() |> String.to_integer()
          sentiment = value / 100.0
          IO.inspect("External sentiment fetched: #{sentiment}")
          %{url: url, sentiment: sentiment}

        {:ok, %HTTPoison.Response{status_code: status}} ->
          IO.inspect("HTTP #{status}")
          state

        {:error, %HTTPoison.Error{reason: reason}} ->
          IO.inspect("error #{reason}")
          state
      end
    end)
  end

  def get_sentiment do
    Agent.get(:external_sentiment_getter, fn %{sentiment: sentiment} -> sentiment end)
  end
end


