defmodule Helheim.Admin.TermController do
  use Helheim.Web, :controller
  alias Helheim.Term

  def index(conn, _params) do
    terms = Term |> Term.newest |> Repo.all
    render(conn, "index.html", terms: terms)
  end

  def new(conn, _params) do
    changeset = Term.changeset(%Term{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"term" => term_params}) do
    changeset = Term.changeset(%Term{}, term_params)
    case Repo.insert(changeset) do
      {:ok, _term} ->
        conn
        |> put_flash(:success, gettext("Terms created successfully."))
        |> redirect(to: admin_term_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    term = Repo.get!(Term, id)
    render(conn, "show.html", term: term)
  end

  def edit(conn, %{"id" => id}) do
    term      = Repo.get!(Term, id)
    changeset = Term.changeset(term)
    render(conn, "edit.html", changeset: changeset, term: term)
  end

  def update(conn, %{"id" => id, "term" => term_params}) do
    term      = Repo.get!(Term, id)
    changeset = Term.changeset(term, term_params)
    case Repo.update(changeset) do
      {:ok, _term} ->
        conn
        |> put_flash(:success, gettext("Terms updated successfully."))
        |> redirect(to: admin_term_path(conn, :index))
      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset, term: term)
    end
  end

  def delete(conn, %{"id" => id}) do
    term = Repo.get!(Term, id)
    Repo.delete!(term)
    conn
    |> put_flash(:success, gettext("Terms deleted successfully."))
    |> redirect(to: admin_term_path(conn, :index))
  end
end
