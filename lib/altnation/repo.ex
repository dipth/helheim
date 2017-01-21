defmodule Altnation.Repo do
  use Ecto.Repo, otp_app: :altnation
  use Kerosene, per_page: 25
end
