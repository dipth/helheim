defmodule Helheim.NotificationSoundsTest do
  use Helheim.DataCase
  alias Helheim.NotificationSounds

  test "sounds/0 returns a map of all sounds" do
    assert is_map(NotificationSounds.sounds())
  end

  test "sound_keys/0 returns a list of all possible sound keys" do
    assert is_list(NotificationSounds.sound_keys())
  end

  test "default_sound/0 returns the details of the default sound" do
    assert is_map(NotificationSounds.default_sound())
  end

  test "file/1 returns the filepath of the default sound when called with `nil`" do
    assert NotificationSounds.file(nil) == "/sounds/notification_guitar_1.mp3"
  end

  test "file/1 returns the filepath of the sound with the given key" do
    assert NotificationSounds.file("chime_1") == "/sounds/notification_chime_1.mp3"
  end

  test "label/1 returns the label of the default sound when called with `nil`" do
    assert NotificationSounds.label(nil) == "Guitar 1"
  end

  test "label/1 returns the label of the sound with the given key" do
    assert NotificationSounds.label("chime_1") == "Chime 1"
  end
end
