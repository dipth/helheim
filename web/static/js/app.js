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

import 'intl/locale-data/jsonp/da.js';

import moment from 'moment';
import tz from 'moment-timezone';
import 'moment/locale/da';

import { Leaf } from "web/static/js/leaf";
import { BootstrapStuff } from "web/static/js/bootstrap_stuff";
import { ProfileSettings } from "web/static/js/profile_settings";
import { BlogPostForm } from "web/static/js/blog_post_form";
import { Notifications } from "web/static/js/notifications";
import { SelectWithCustom } from "web/static/js/select_with_custom";
import { PhotoUpload } from "web/static/js/photo_upload";
import { AdminTermsForm } from "web/static/js/admin_terms_form";
import { Embeds } from "web/static/js/embeds/embeds";
import { NotificationsSwitch } from "web/static/js/notifications_switch";
import { PhotoSorter } from "web/static/js/photo_sorter";
import { MentionableInput } from "web/static/js/mentionable";
import { Mentionable } from "web/static/js/mentionable";
import { PopoverConfirmable } from "web/static/js/popover_confirmable";
import { DonationForm } from "web/static/js/donation_form";
import { CalendarEventForm } from "web/static/js/calendar_event_form";

export var App = {
  run: function(){
    Embeds.run();
    Leaf.run();
    BootstrapStuff.run();
    ProfileSettings.run();
    BlogPostForm.run();
    Notifications.run();
    SelectWithCustom.run();
    PhotoUpload.run();
    AdminTermsForm.run();
    NotificationsSwitch.run();
    PhotoSorter.run();
    MentionableInput.run();
    Mentionable.run();
    PopoverConfirmable.run();
    DonationForm.run();
    CalendarEventForm.run();
  }
}

export var AppSpecial = {
  run: function(){
    Leaf.run();
  }
}
