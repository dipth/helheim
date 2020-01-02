defmodule Helheim.DonationService do
  import Ecto.Query
  alias Ecto.Multi
  alias Helheim.Repo
  alias Helheim.User
  alias Helheim.Donation

  def create!(changeset) do
    Multi.new |> Multi.insert(:donation, changeset)
              |> update_user(changeset)
              |> Multi.run(:charge, &charge/2)
              |> Multi.run(:write_charge, &write_charge/2)
              |> Repo.transaction
  end

  defp update_user(multi, changeset) do
    user_id = Ecto.Changeset.get_field(changeset, :user_id)
    amount  = Ecto.Changeset.get_field(changeset, :amount)
    multi |> Multi.update_all(:user_last_donation_at,
                              (User |> where(id: ^user_id)),
                              set: [last_donation_at: DateTime.utc_now],
                              inc: [total_donated: amount],
                              inc: [max_total_file_size: Donation.calculate_extra_space(amount)])
  end

  defp charge(_repo, %{donation: %{token: token, amount: amount, user_id: user_id}}) do
    Stripe.Charge.create(amount, [
      source: token,
      currency: "dkk",
      description: "Helheim donation from user: #{user_id}"
    ])
  end

  defp write_charge(_repo, %{donation: donation, charge: charge}) do
    donation
    |> Ecto.Changeset.change(charge: charge)
    |> Repo.update
  end
end
