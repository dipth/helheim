defmodule Helheim.Donation do
  use Helheim, :model

  alias Helheim.User

  @min_amount 10 * 100 # cents
  def min_amount, do: @min_amount

  @max_amount 100 * 100 # cents
  def max_amount, do: @max_amount

  @step 10 * 100 # cents
  def step, do: @step

  @default 50 * 100 # cents
  def default, do: @default

  @extra_space_per_step 100 * 1024 * 1024 # MB
  def extra_space_per_step, do: @extra_space_per_step

  @recent_days -30 # days
  def recent_days, do: @recent_days

  schema "donations" do
    belongs_to :user,        Helheim.User
    field      :token,       :string
    field      :amount,      :integer, default: @default
    field      :charge,      :map
    field      :fee,         :integer
    field      :balance_txn, :map

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:amount, :token])
    |> validate_required([:token])
    |> validate_number(:amount, less_than_or_equal_to: @max_amount, greater_than_or_equal_to: @min_amount)
  end

  def recently_donated?(nil), do: false
  def recently_donated?(%User{last_donation_at: nil}), do: false
  def recently_donated?(%User{last_donation_at: last_donation_at}) do
    Timex.after?(last_donation_at, Timex.shift(Timex.now, days: -30))
  end

  def calculate_extra_space(amount) do
    round(amount / step() * extra_space_per_step())
  end
end
