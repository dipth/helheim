defmodule Helheim.Repo do
  use Ecto.Repo, otp_app: :helheim
  use Kerosene, per_page: 25
end
