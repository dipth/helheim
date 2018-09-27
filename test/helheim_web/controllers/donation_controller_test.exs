defmodule HelheimWeb.DonationControllerTest do
  use HelheimWeb.ConnCase
  import Mock
  alias Helheim.Donation
  alias Helheim.DonationService

  @valid_attrs %{amount: Donation.min_amount, token: "test"}
  @invalid_attrs %{amount: Donation.min_amount, token: ""}

  ##############################################################################
  # new/2
  describe "new/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response", %{conn: conn} do
      conn  = get conn, "/donations/new"
      assert html_response(conn, 200) =~ gettext("How much would you like to donate?")
    end
  end

  describe "new/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn  = get conn, "/donations/new"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # create/2
  describe "create/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it redirects to the thank_you page when successfull", %{conn: conn},
      DonationService, [], [create!: fn(_changeset) -> {:ok, %{donation: %{}}} end] do

      conn = post conn, "/donations", donation: @valid_attrs
      assert called DonationService.create!(%{changes: %{amount: @valid_attrs[:amount], token: @valid_attrs[:token]}})
      assert redirected_to(conn)       =~ donation_path(conn, :thank_you)
    end

    test_with_mock "it re-renders the donation form with an error flash message when unsuccessfull", %{conn: conn},
      DonationService, [], [create!: fn(_changeset) -> {:error, :donation, %{}, []} end] do

      conn = post conn, "/donations", donation: @invalid_attrs
      assert called DonationService.create!(%{changes: %{amount: @invalid_attrs[:amount]}})
      assert html_response(conn, 200) =~ gettext("How much would you like to donate?")
      assert get_flash(conn, :error) == gettext("Something went wrong...")
    end
  end

  describe "create/2 when not signed in" do
    test_with_mock "it does not invoke the DonationService", %{conn: conn},
      DonationService, [], [create!: fn(_changeset) -> raise("DonationService was called!") end] do

      post conn, "/donations", forum_reply: @valid_attrs
    end

    test "it redirects to the login page", %{conn: conn} do
      conn = post conn, "/donations", forum_reply: @valid_attrs
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # thank_you/2
  describe "thank_you/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/donations/thank_you"
      assert html_response(conn, 200) =~ gettext("Thank you for your support!")
    end
  end

  describe "show/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn  = get conn, "/donations/thank_you"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end
end
