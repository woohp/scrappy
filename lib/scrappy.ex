defmodule Scrappy do
  @moduledoc """
  Documentation for Scrappy.
  """

  @spec bulk_download(Enumerable.t(), integer()) :: nil
  def bulk_download(download_tasks, parallelism \\ 20) do
    download_tasks
    |> Flow.from_enumerable()
    |> Flow.partition(max_demand: parallelism, stages: parallelism)
    |> Flow.map(&download/1)
  end

  def bulk_save_files(flow) do
    flow
    |> Flow.map(fn {body, out_path} ->
      {:ok, file} = File.open(out_path, [:write])
      :ok = IO.binwrite(file, body)
      :ok = File.close(file)
    end)
  end

  def show_progress(flow, total) do
    flow
    |> Flow.partition(stages: 1)
    |> Flow.reduce(fn -> 0 end, fn (:ok, count) ->
      ProgressBar.render(count + 1, total, suffix: :count)
      count + 1
    end)
  end

  defp download({url, out_path} = datum, tries \\ 1) do
    if tries > 50, do: throw("too many retries: #{url}")
    if tries > 0, do: :timer.sleep(min(tries, 10) * 1000)

    options = [ssl: [{:versions, [:'tlsv1.2']}], follow_redirect: true]

    case HTTPoison.get(url, [{"Accept-Encoding", "gzip"}], options) do
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

            {body, out_path}

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
end
