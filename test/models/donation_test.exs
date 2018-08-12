defmodule Helheim.DonationTest do
  use Helheim.ModelCase
  alias Helheim.Donation
  alias Helheim.User

  @valid_attrs %{amount: Donation.min_amount, token: "foobar"}

  describe "changeset/2" do
    test "it is valid with valid attrs" do
      changeset = Donation.changeset(%Donation{}, @valid_attrs)
      assert changeset.valid?
    end

    test "it requires the amount to be greater than or equal to the minimum amount" do
      changeset = Donation.changeset(%Donation{}, Map.merge(@valid_attrs, %{amount: Donation.min_amount - 1}))
      refute changeset.valid?
    end

    test "it requires the amount to be less than or equal to the maximum amount" do
      changeset = Donation.changeset(%Donation{}, Map.merge(@valid_attrs, %{amount: Donation.max_amount + 1}))
      refute changeset.valid?
    end

    test "it requires a token" do
      changeset = Donation.changeset(%Donation{}, Map.delete(@valid_attrs, :token))
      refute changeset.valid?
    end
  end

  describe "recently_donated?/1" do
    test "returns false when the specified user is nil" do
      refute Donation.recently_donated?(nil)
    end

    test "returns false when the specified user has never donated" do
      refute Donation.recently_donated?(%User{last_donation_at: nil})
    end

    test "returns false when the specified user did not donate within the last 30 days" do
      timestamp = Timex.shift(Timex.now, days: Donation.recent_days)
      refute Donation.recently_donated?(%User{last_donation_at: timestamp})
    end

    test "returns true when the specified user donated withing the last 30 days" do
      timestamp = Timex.shift(Timex.now, days: Donation.recent_days + 1)
      assert Donation.recently_donated?(%User{last_donation_at: timestamp})
    end
  end

  describe "calculate_extra_space/1" do
    test "returns rounded product of the extra space per step and the number of steps in the amount" do
      assert Donation.calculate_extra_space(1234) == 129394278
    end
  end
end
