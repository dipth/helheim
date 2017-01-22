defmodule Altnation.BlogPost do
  use Altnation.Web, :model

  schema "blog_posts" do
    field :title, :string
    field :body, :string
    belongs_to :user, Altnation.User

    timestamps()
  end

  def newest(query) do
    from u in query,
    order_by: [desc: u.inserted_at]
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :body])
    |> trim_fields(:title)
    |> validate_required([:title, :body])
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
