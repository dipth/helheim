defmodule HelheimWeb.DonationController do
  use HelheimWeb, :controller
  alias Helheim.Donation
  alias Helheim.DonationService

  def new(conn, _params) do
    user = current_resource(conn)
    changeset = user
                |> Ecto.build_assoc(:donations)
                |> Donation.changeset(%{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"donation" => donation_params}) do
    user      = current_resource(conn)
    changeset = user |> Ecto.build_assoc(:donations)
                     |> Donation.changeset(donation_params)
    result    = DonationService.create!(changeset)

    case result do
      {:ok, %{donation: _donation}} ->
        conn |> redirect(to: donation_path(conn, :thank_you))
      {:error, _failed_operation, _failed_value, _changes_so_far} ->
        conn |> put_flash(:error, gettext("Something went wrong..."))
             |> render("new.html", changeset: changeset)
    end
  end

  def thank_you(conn, _params) do
    render(conn, "thank_you.html")
  end
end
