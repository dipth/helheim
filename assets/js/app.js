import favico from "../vendor/js/favico"
window.Favico = favico

import dragula from "../vendor/js/dragula"
window.dragula = dragula

import moment from 'moment';
import tz from 'moment-timezone';
// import 'moment/locale/da';

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"

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
import { IgnoreForm } from "./ignore_form";

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
    IgnoreForm.run();
  }
}

window.App = App;

export var AppSpecial = {
  run: function(){
    Leaf.run();
  }
}

window.AppSpecial = AppSpecial;
