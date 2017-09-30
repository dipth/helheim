defmodule Helheim.DonationServiceTest do
  use Helheim.ModelCase
  import Mock
  alias Helheim.Donation
  alias Helheim.DonationService
  alias Helheim.User

  describe "create/1 with a valid changeset" do
    setup [:create_user, :build_valid_changeset]

    setup_with_mocks([
      {Stripe.Charges, [], [create: fn(_amount, _options) -> {:ok, %{"balance_transaction" => "txn_test"}} end]},
      {Donation, [:passthrough], [calculate_extra_space: fn(_amount) -> 123 end]}
      ], _context) do
        :ok
    end

    test "inserts a donation in the database with the correct values", %{user: user, changeset: changeset} do
      DonationService.create!(changeset)
      donation = Repo.one!(Donation)
      assert donation.user_id == user.id
      assert donation.amount  == changeset.changes[:amount]
      assert donation.token   == changeset.changes[:token]
      assert donation.charge  == %{"balance_transaction" => "txn_test"}
    end

    test "updates the last_donation_at timestamp of the user", %{user: user, changeset: changeset} do
      DonationService.create!(changeset)
      user = Repo.get(User, user.id)
      {:ok, time_diff, _, _} = Calendar.DateTime.diff(user.last_donation_at, DateTime.utc_now)
      assert time_diff < 10
    end

    test "increments the total_donated value of the user", %{user: user, changeset: changeset} do
      assert user.total_donated == 1000
      DonationService.create!(changeset)
      user = Repo.get(User, user.id)
      assert user.total_donated == changeset.changes[:amount] + 1000
    end

    test "increments the max_total_file_size value of the user", %{user: user, changeset: changeset} do
      assert user.max_total_file_size == (25 * 1024 * 1024)
      DonationService.create!(changeset)
      user = Repo.get(User, user.id)
      assert user.max_total_file_size == (25 * 1024 * 1024) + 123
    end

    test "captures the money via Stripe", %{user: user, changeset: changeset} do
      DonationService.create!(changeset)
      assert called Stripe.Charges.create(changeset.changes[:amount], [
        source: changeset.changes[:token],
        currency: "dkk",
        description: "Helheim donation from user: #{user.id}"
      ])
    end
  end

  describe "create/1 with a valid changeset using default amount" do
    setup [:create_user, :build_valid_changeset_with_default_amount]

    setup_with_mocks([
      {Stripe.Charges, [], [create: fn(_amount, _options) -> {:ok, %{"balance_transaction" => "txn_test"}} end]},
      {Donation, [:passthrough], [calculate_extra_space: fn(_amount) -> 123 end]}
      ], _context) do
        :ok
    end

    test "inserts a donation in the database with the correct values", %{user: user, changeset: changeset} do
      DonationService.create!(changeset)
      donation = Repo.one!(Donation)
      assert donation.user_id == user.id
      assert donation.amount
      assert donation.token   == changeset.changes[:token]
      assert donation.charge  == %{"balance_transaction" => "txn_test"}
    end
  end

  describe "create/1 with a valid changeset but a failing capture" do
    setup [:create_user, :build_valid_changeset]

    setup_with_mocks([
      {Stripe.Charges, [], [create: fn(_amount, _options) -> {:error, %{}} end]},
      {Donation, [:passthrough], [calculate_extra_space: fn(_amount) -> 123 end]}
      ], _context) do
        :ok
    end

    test "does not insert a donation in the database", %{changeset: changeset} do
      DonationService.create!(changeset)
      refute Repo.one(Donation)
    end

    test "does not update the last_donation_at timestamp of the user", %{user: user, changeset: changeset} do
      original_value = user.last_donation_at
      DonationService.create!(changeset)
      user = Repo.get(User, user.id)
      assert user.last_donation_at == original_value
    end

    test "does not increment the total_donated value of the user", %{user: user, changeset: changeset} do
      original_value = user.total_donated
      DonationService.create!(changeset)
      user = Repo.get(User, user.id)
      assert user.total_donated == original_value
    end

    test "does not increment the max_total_file_size value of the user", %{user: user, changeset: changeset} do
      original_value =  user.max_total_file_size
      DonationService.create!(changeset)
      user = Repo.get(User, user.id)
      assert user.max_total_file_size == original_value
    end
  end

  describe "create/1 with an invalid changeset" do
    setup [:create_user, :build_invalid_changeset]

    setup_with_mocks([
      {Stripe.Charges, [], [create: fn(_amount, _options) -> raise "Stripe called!" end]},
      {Donation, [:passthrough], [calculate_extra_space: fn(_amount) -> 123 end]}
      ], _context) do
        :ok
    end

    test "does not insert a donation in the database", %{changeset: changeset} do
      DonationService.create!(changeset)
      refute Repo.one(Donation)
    end

    test "does not update the last_donation_at timestamp of the user", %{user: user, changeset: changeset} do
      original_value = user.last_donation_at
      DonationService.create!(changeset)
      user = Repo.get(User, user.id)
      assert user.last_donation_at == original_value
    end

    test "does not increment the total_donated value of the user", %{user: user, changeset: changeset} do
      original_value = user.total_donated
      DonationService.create!(changeset)
      user = Repo.get(User, user.id)
      assert user.total_donated == original_value
    end

    test "does not increment the max_total_file_size value of the user", %{user: user, changeset: changeset} do
      original_value =  user.max_total_file_size
      DonationService.create!(changeset)
      user = Repo.get(User, user.id)
      assert user.max_total_file_size == original_value
    end
  end

  defp build_valid_changeset(%{user: user}) do
    changeset = user
                |> Ecto.build_assoc(:donations)
                |> Donation.changeset(%{amount: Donation.min_amount, token: "test"})
    [changeset: changeset]
  end

  defp build_valid_changeset_with_default_amount(%{user: user}) do
    changeset = user
                |> Ecto.build_assoc(:donations)
                |> Donation.changeset(%{token: "test"})
    [changeset: changeset]
  end

  defp build_invalid_changeset(%{user: user}) do
    changeset = user
                |> Ecto.build_assoc(:donations)
                |> Donation.changeset(%{amount: Donation.min_amount - 1, token: "test"})
    [changeset: changeset]
  end
end
