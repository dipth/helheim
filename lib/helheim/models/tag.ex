defmodule Helheim.Tag do
  use Helheim, :model

  alias Helheim.Repo
  alias Helheim.Tag

  schema "tags" do
    field :name, :string
    has_many :song_tags, Helheim.SongTag
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name])
    |> trim_fields(:name)
    |> validate_required([:name])
    |> validate_length(:name, max: 40)
    |> unique_constraint(:name, name: :tags_name_index)
  end

  @doc """
  Finds or creates the tag with the given name, matching case-insensitively.
  """
  def get_or_create_by_name!(name) do
    get_by_name(name) ||
      %Tag{}
      |> changeset(%{name: name})
      |> Repo.insert!(on_conflict: :nothing, conflict_target: {:unsafe_fragment, "(lower(name))"})
      |> case do
        %Tag{id: nil} -> get_by_name(name)
        tag -> tag
      end
  end

  def get_by_name(name) do
    Repo.one(from t in Tag, where: fragment("lower(?)", t.name) == ^String.downcase(name))
  end
end
