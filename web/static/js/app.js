// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
// import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import { Leaf } from "web/static/js/leaf";
import { RestfulizerTweak } from "web/static/js/restfulizer";
import { BootstrapStuff } from "web/static/js/bootstrap_stuff";
import { ProfileSettings } from "web/static/js/profile_settings";
import { BlogPostForm } from "web/static/js/blog_post_form";
import { Notifications } from "web/static/js/notifications";
import { SelectWithCustom } from "web/static/js/select_with_custom";
import { PhotoUpload } from "web/static/js/photo_upload";
import { AdminTermsForm } from "web/static/js/admin_terms_form";

export var App = {
  run: function(){
    Leaf.run();
    RestfulizerTweak.run();
    BootstrapStuff.run();
    ProfileSettings.run();
    BlogPostForm.run();
    Notifications.run();
    SelectWithCustom.run();
    PhotoUpload.run();
    AdminTermsForm.run();
  }
}

export var AppSpecial = {
  run: function(){
    Leaf.run();
  }
}
