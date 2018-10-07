defmodule Helheim.Auth.Guardian do
  use Guardian, otp_app: :helheim

  alias Helheim.Auth

  def subject_for_token(user, _claims) do
    {:ok, to_string(user.id)}
  end

  def resource_from_claims(claims) do
    id   = claims["sub"]
    user = Auth.get_user!(id)
    {:ok, user}
  end
end
