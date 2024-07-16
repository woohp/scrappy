defmodule ScrappyTest do
  use ExUnit.Case
  doctest Scrappy

  test "download and save files" do
    download_tasks = [
      {"google.com", "google.com"},
      {"yahoo.com", "yahoo.com"}
    ]

    download_tasks
    |> Scrappy.bulk_download()
    |> Scrappy.bulk_save_files()
    |> Scrappy.show_progress(2)
    |> Flow.run()

    assert File.exists?("google.com")
    assert File.exists?("yahoo.com")
    File.rm!("google.com")
    File.rm!("yahoo.com")
  end
end
