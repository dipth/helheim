defmodule Helheim.CalendarEventTest do
  use Helheim.DataCase
  alias Helheim.CalendarEvent
  alias Helheim.Repo

  @valid_attrs %{title: "My awesome event", description: "Just for testing", starts_at: "2018-08-01 12:00:00.000000", ends_at: "2018-08-01 15:00:00.000000", location: "My place!"}

  describe "changeset/2" do
    test "is valid with valid attrs" do
      changeset = CalendarEvent.changeset(%CalendarEvent{}, @valid_attrs)
      assert changeset.valid?
    end

    test "requires a title" do
      changeset = CalendarEvent.changeset(%CalendarEvent{}, Map.delete(@valid_attrs, :title))
      refute changeset.valid?
    end

    test "requires a description" do
      changeset = CalendarEvent.changeset(%CalendarEvent{}, Map.delete(@valid_attrs, :description))
      refute changeset.valid?
    end

    test "requires a starting time" do
      changeset = CalendarEvent.changeset(%CalendarEvent{}, Map.delete(@valid_attrs, :starts_at))
      refute changeset.valid?
    end

    test "requires an ending time" do
      changeset = CalendarEvent.changeset(%CalendarEvent{}, Map.delete(@valid_attrs, :ends_at))
      refute changeset.valid?
    end

    test "requires a location" do
      changeset = CalendarEvent.changeset(%CalendarEvent{}, Map.delete(@valid_attrs, :location))
      refute changeset.valid?
    end

    test "trims the title" do
      changeset = CalendarEvent.changeset(%CalendarEvent{}, Map.merge(@valid_attrs, %{title: "   Foo   "}))
      assert changeset.changes.title  == "Foo"
    end

    test "trims the description" do
      changeset = CalendarEvent.changeset(%CalendarEvent{}, Map.merge(@valid_attrs, %{description: "   Foo   "}))
      assert changeset.changes.description  == "Foo"
    end

    test "trims the location" do
      changeset = CalendarEvent.changeset(%CalendarEvent{}, Map.merge(@valid_attrs, %{location: "   Foo   "}))
      assert changeset.changes.location  == "Foo"
    end

    test "trims the url" do
      changeset = CalendarEvent.changeset(%CalendarEvent{}, Map.merge(@valid_attrs, %{url: "   Foo   "}))
      assert changeset.changes.url  == "Foo"
    end

    test "sets a uuid" do
      changeset = CalendarEvent.changeset(%CalendarEvent{}, @valid_attrs)
      assert changeset.changes.uuid
    end
  end

  describe "approved/1" do
    test "only returns approved events" do
      calendar_event1  = insert(:calendar_event, approved_at: DateTime.utc_now)
      _calendar_event2 = insert(:calendar_event, approved_at: nil)
      calendar_events  = CalendarEvent |> CalendarEvent.approved |> Repo.all
      ids              = Enum.map calendar_events, fn(c) -> c.id end
      assert [calendar_event1.id] == ids
    end
  end

  describe "pending/1" do
    test "only returns pending events" do
      calendar_event1  = insert(:calendar_event, approved_at: nil, rejected_at: nil)
      _calendar_event2 = insert(:calendar_event, approved_at: DateTime.utc_now, rejected_at: nil)
      _calendar_event3 = insert(:calendar_event, approved_at: nil, rejected_at: DateTime.utc_now)
      calendar_events  = CalendarEvent |> CalendarEvent.pending |> Repo.all
      ids              = Enum.map calendar_events, fn(c) -> c.id end
      assert [calendar_event1.id] == ids
    end
  end

  describe "upcoming/1" do
    test "only returns events where the ends_at timestamp is in the future" do
      now              = Timex.now
      yesterday        = Timex.shift(now, days: -1)
      calendar_event1  = insert(:calendar_event, starts_at: yesterday, ends_at: Timex.shift(now, minutes: 2))
      _calendar_event2 = insert(:calendar_event, starts_at: yesterday, ends_at: Timex.shift(now, minutes: -2))
      calendar_events  = CalendarEvent |> CalendarEvent.upcoming |> Repo.all
      ids              = Enum.map calendar_events, fn(c) -> c.id end
      assert [calendar_event1.id] == ids
    end
  end

  describe "chronological/1" do
    test "orders a post with an earlier starts_at timestamp before one with a later one" do
      now             = Timex.now
      calendar_event1 = insert(:calendar_event, starts_at: Timex.shift(now, minutes: -1), ends_at: now, inserted_at: now)
      calendar_event2 = insert(:calendar_event, starts_at: Timex.shift(now, minutes: -2), ends_at: now, inserted_at: now)
      calendar_events = CalendarEvent |> CalendarEvent.chronological |> Repo.all
      ids             = Enum.map calendar_events, fn(c) -> c.id end
      assert [calendar_event2.id, calendar_event1.id] == ids
    end

    test "orders a post with an earlier ends_at timestamp before one with a later one" do
      now             = Timex.now
      calendar_event1 = insert(:calendar_event, ends_at: Timex.shift(now, minutes: -1), starts_at: now, inserted_at: now)
      calendar_event2 = insert(:calendar_event, ends_at: Timex.shift(now, minutes: -2), starts_at: now, inserted_at: now)
      calendar_events = CalendarEvent |> CalendarEvent.chronological |> Repo.all
      ids             = Enum.map calendar_events, fn(c) -> c.id end
      assert [calendar_event2.id, calendar_event1.id] == ids
    end

    test "orders a post with an earlier inserted_at timestamp before one with a later one" do
      now             = Timex.now
      calendar_event1 = insert(:calendar_event, inserted_at: Timex.shift(now, minutes: -1), starts_at: now, ends_at: now)
      calendar_event2 = insert(:calendar_event, inserted_at: Timex.shift(now, minutes: -2), starts_at: now, ends_at: now)
      calendar_events = CalendarEvent |> CalendarEvent.chronological |> Repo.all
      ids             = Enum.map calendar_events, fn(c) -> c.id end
      assert [calendar_event2.id, calendar_event1.id] == ids
    end
  end

  describe "pending_count/0" do
    test "returns the number of pending events" do
      insert_list(3, :calendar_event, approved_at: nil, rejected_at: nil)
      insert_list(3, :calendar_event, approved_at: DateTime.utc_now, rejected_at: nil)
      insert_list(3, :calendar_event, approved_at: nil, rejected_at: DateTime.utc_now)
      assert CalendarEvent.pending_count() == 3
    end
  end

  describe "approved?/1" do
    test "returns true for an event that has an approved_at timestamp" do
      calendar_event = build(:calendar_event, approved_at: DateTime.utc_now)
      assert CalendarEvent.approved?(calendar_event)
    end

    test "returns false for an event that does not have an approved_at timestamp" do
      calendar_event = build(:calendar_event, approved_at: nil)
      refute CalendarEvent.approved?(calendar_event)
    end
  end

  describe "rejected?/1" do
    test "returns true for an event that has an rejected_at timestamp" do
      calendar_event = build(:calendar_event, rejected_at: DateTime.utc_now)
      assert CalendarEvent.rejected?(calendar_event)
    end

    test "returns false for an event that does not have an rejected_at timestamp" do
      calendar_event = build(:calendar_event, rejected_at: nil)
      refute CalendarEvent.rejected?(calendar_event)
    end
  end

  describe "pending?/1" do
    test "returns true for an event that has neither an approved_at nor a rejected_at timestamp" do
      calendar_event = build(:calendar_event, approved_at: nil, rejected_at: nil)
      assert CalendarEvent.pending?(calendar_event)
    end

    test "returns false for an event that has an approved_at timestamp" do
      calendar_event = build(:calendar_event, approved_at: DateTime.utc_now)
      refute CalendarEvent.pending?(calendar_event)
    end

    test "returns false for an event that has an rejected_at timestamp" do
      calendar_event = build(:calendar_event, rejected_at: DateTime.utc_now)
      refute CalendarEvent.pending?(calendar_event)
    end
  end

  describe "approve!/1" do
    test "it marks the given pending calendar_event as approved" do
      calendar_event = insert(:calendar_event, approved_at: nil, rejected_at: nil)
      refute CalendarEvent.approved?(calendar_event)
      {:ok, calendar_event} = CalendarEvent.approve!(calendar_event)
      assert CalendarEvent.approved?(calendar_event)
    end
  end

  describe "reject!/1" do
    test "it marks the given pending calendar_event as rejected" do
      calendar_event = insert(:calendar_event, approved_at: nil, rejected_at: nil)
      refute CalendarEvent.rejected?(calendar_event)
      {:ok, calendar_event} = CalendarEvent.reject!(calendar_event)
      assert CalendarEvent.rejected?(calendar_event)
    end
  end
end
