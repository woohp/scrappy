defmodule Scrappy do
  @moduledoc """
  Documentation for Scrappy.
  """

  @spec bulk_download(Enumerable.t(), integer()) :: nil
  def bulk_download(download_tasks, parallelism \\ 20) do
    num_download_tasks = length(download_tasks)

    download_tasks
    |> Flow.from_enumerable()
    |> Flow.partition(max_demand: parallelism, stages: parallelism)
    |> Flow.map(&download/1)
    |> Flow.partition(stages: 1)
    |> Flow.reduce(fn -> 0 end, &Scrappy.show_progress(&1, &2, num_download_tasks))
    |> Flow.run()
  end

  defp download({url, out_path} = datum, tries \\ 1) do
    if tries > 50, do: throw("too many retries: #{url}")
    if tries > 0, do: :timer.sleep(min(tries, 10) * 1000)

    case HTTPoison.get(url, [{"Accept-Encoding", "gzip"}]) do
      {:ok, response} ->
        case response.status_code do
          429 ->
            download(datum, tries + 1)

          200 ->
            # gunzip if necessary
            gzipped =
              Enum.any?(response.headers, fn kv ->
                case kv do
                  {"Content-Encoding", "gzip"} -> true
                  {"Content-Encoding", "x-gzip"} -> true
                  _ -> false
                end
              end)

            body =
              if gzipped do
                :zlib.gunzip(response.body)
              else
                response.body
              end

            {:ok, file} = File.open(out_path, [:write])
            :ok = IO.binwrite(file, body)
            :ok = File.close(file)

          # response.headers
          # |> List.keyfind("X-RateLimit-Remaining", 0)
          # |> elem(1)
          # |> Integer.parse()
          # |> elem(0)
          _ ->
            throw("bad response: #{response.status_code}")
        end

      {:error, %{reason: :timeout}} ->
        download(datum, tries + 1)
    end
  end

  def show_progress(:ok, count, total_count) do
    ProgressBar.render(count + 1, total_count, suffix: :count)
    count + 1
  end
end
