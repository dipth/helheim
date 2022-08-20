import { ContentEditable } from "./content_editable";

export var AdminTermsForm = {
  run: function(){
    ContentEditable.run(
      document.getElementById('term_body_editor'),
      document.getElementById('term_body')
    )
  },
}
