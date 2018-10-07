defmodule Helheim.Term do
  use Helheim, :model

  schema "terms" do
    field :body,      :string
    field :published, :boolean
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:body, :published])
    |> trim_fields(:body)
    |> validate_required(:body)
  end

  def newest(query) do
    from t in query,
      order_by: [desc: t.inserted_at]
  end

  def published(query) do
    from t in query,
      where: t.published == true
  end
end
