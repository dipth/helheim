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

import { Leaf } from "./leaf";
import { BootstrapStuff } from "./bootstrap_stuff";
import { ProfileSettings } from "./profile_settings";
import { BlogPostForm } from "./blog_post_form";
import { Live } from "./live";
import { Notifications } from "./notifications";
import { Status } from "./status";
import { SelectWithCustom } from "./select_with_custom";
import { PhotoUpload } from "./photo_upload";
import { AdminTermsForm } from "./admin_terms_form";
import { Embeds } from "./embeds/embeds";
import { NotificationsSwitch } from "./notifications_switch";
import { PhotoSorter } from "./photo_sorter";
import { MentionableInput } from "./mentionable";
import { Mentionable } from "./mentionable";
import { PopoverConfirmable } from "./popover_confirmable";
import { DonationForm } from "./donation_form";
import { CalendarEventForm } from "./calendar_event_form";
import { PreferencesForm } from "./preferences_form";
import { BlockForm } from "./block_form";

import css from "../css/app.css.scss"

export var App = {
  run: function(){
    Live.run();
    Embeds.run();
    Leaf.run();
    BootstrapStuff.run();
    ProfileSettings.run();
    BlogPostForm.run();
    Notifications.run();
    Status.run();
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
    PreferencesForm.run();
    BlockForm.run();
  }
}

window.App = App;

export var AppSpecial = {
  run: function(){
    Leaf.run();
  }
}

window.AppSpecial = AppSpecial;
