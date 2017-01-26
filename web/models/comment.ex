defmodule Altnation.Comment do
  use Altnation.Web, :model

  schema "comments" do
    field      :body,         :string
    field      :approved_at,  Calecto.DateTimeUTC
    field      :deleted_at,   Calecto.DateTimeUTC
    belongs_to :author,       Altnation.User
    belongs_to :profile,      Altnation.User
    belongs_to :blog_post,    Altnation.BlogPost

    timestamps()
  end

  def newest(query) do
    from c in query,
    order_by: [desc: c.inserted_at]
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:body])
    |> trim_fields(:body)
    |> validate_required([:body])
    |> scrub_body()
  end

  defp scrub_body(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{body: body}} ->
        put_change(changeset, :body, body |> HtmlSanitizeEx.Scrubber.scrub(Altnation.Scrubber))
      _ ->
        changeset
    end
  end
end
