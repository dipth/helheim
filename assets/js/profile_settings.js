import { ContentEditable } from "./content_editable";

export var ProfileSettings = {
  run: function(){
    ContentEditable.run(
      document.getElementById('profile_text_editor'),
      document.getElementById('user_profile_text')
    )
  },
}
