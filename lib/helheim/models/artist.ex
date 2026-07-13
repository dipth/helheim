defmodule Helheim.Artist do
  use Helheim, :model

  alias Helheim.Artist
  alias Helheim.Repo

  schema "artists" do
    field :name,             :string
    field :mbid,             :string
    field :country_code,     :string
    field :country_name,     :string
    field :image_url_small,  :string
    field :image_url_medium, :string
    field :image_url_large,  :string
    field :image_source,     :string
    field :enriched_at,      :utc_datetime_usec
    has_many :songs, Helheim.Song
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :mbid, :country_code, :country_name, :image_url_small, :image_url_medium, :image_url_large, :image_source, :enriched_at])
    |> validate_required([:name])
    |> unique_constraint(:name, name: :artists_name_index)
  end

  @doc """
  Finds or creates the artist with the given name, matching
  case-insensitively - the same identity rule songs use for artist_name.
  """
  def get_or_create_by_name!(name) do
    get_by_name(name) ||
      %Artist{}
      |> changeset(%{name: name})
      |> Repo.insert!(on_conflict: :nothing, conflict_target: {:unsafe_fragment, "(lower(name))"})
      |> case do
        %Artist{id: nil} -> get_by_name(name)
        artist -> artist
      end
  end

  def get_by_name(name) do
    Repo.one(from a in Artist, where: fragment("lower(?)", a.name) == ^String.downcase(name))
  end

  def by_names(query, names) do
    downcased = Enum.map(names, &String.downcase/1)
    from a in query, where: fragment("lower(?)", a.name) in ^downcased
  end
end
