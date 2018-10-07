defmodule Helheim.NotificationSounds do
  @sounds %{
    "guitar_1" => %{
      label: "Guitar 1",
      file: "/sounds/notification_guitar_1.mp3"
    },
    "guitar_2" => %{
      label: "Guitar 2",
      file: "/sounds/notification_guitar_2.mp3"
    },
    "owl_1" => %{
      label: "Owl 1",
      file: "/sounds/notification_owl_1.mp3"
    },
    "owl_2" => %{
      label: "Owl 2",
      file: "/sounds/notification_owl_2.mp3"
    },
    "chime_1" => %{
      label: "Chime 1",
      file: "/sounds/notification_chime_1.mp3"
    },
    "chime_2" => %{
      label: "Chime 2",
      file: "/sounds/notification_chime_2.mp3"
    },
    "waterdrop_1" => %{
      label: "Waterdrop",
      file: "/sounds/notification_waterdrop_1.mp3"
    },
    "click_1" => %{
      label: "Click",
      file: "/sounds/notification_click_1.mp3"
    }
  }

  @default_sound_key "guitar_1"

  def sounds, do: @sounds

  def sound_keys, do: Map.keys(@sounds)

  def default_sound, do: @sounds[@default_sound_key]

  def file(nil), do: default_sound().file
  def file(key), do: @sounds[key].file

  def label(nil), do: default_sound().label
  def label(key), do: @sounds[key].label
end
