defmodule Helheim.Comment do
  use Helheim.Web, :model

  schema "comments" do
    field      :body,         :string
    field      :approved_at,  Calecto.DateTimeUTC
    field      :deleted_at,   Calecto.DateTimeUTC
    belongs_to :author,       Helheim.User
    belongs_to :profile,      Helheim.User
    belongs_to :blog_post,    Helheim.BlogPost
    belongs_to :photo_album,  Helheim.PhotoAlbum
    belongs_to :photo,        Helheim.Photo

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
  end
end
