defmodule Helheim.SongTag do
  use Helheim, :model

  schema "songs_tags" do
    belongs_to :song, Helheim.Song
    belongs_to :tag, Helheim.Tag
    field :position, :integer
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:position])
    |> validate_required([:position])
  end

  def ordered(query) do
    from st in query, order_by: [asc: st.position]
  end
end
