defmodule Helheim.Repo do
  use Ecto.Repo, otp_app: :helheim
  use Scrivener, page_size: 25
end
