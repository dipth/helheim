import flatpickr from "flatpickr";
import { Danish } from "flatpickr/dist/l10n/da.js"

const options = {
  enableTime: true,
  dateFormat: "Y-m-d H:i",
  "locale": Danish,
  time_24hr: true,
  inline: true,
  dateFormat: "Y-m-d H:i:00.000000"
}

let startsAt = null;
let endsAt = null;

export var CalendarEventForm = {
  run: function(){
    const startsAtElm = document.getElementById('calendar_event_starts_at');
    const endsAtElm = document.getElementById('calendar_event_ends_at');

    if (!startsAtElm || !endsAtElm) { return; }

    startsAt = flatpickr(startsAtElm, Object.assign(options, {
      onChange: this.onStartsAtChanged
    }));

    endsAt = flatpickr(endsAtElm, Object.assign(options, {
      onChange: this.onEndsAtChanged
    }));
  },

  onStartsAtChanged: function(selectedDates, dateStr, instance) {
    endsAt.set('minDate', dateStr);
  },

  onEndsAtChanged: function(selectedDates, dateStr, instance) {
    // Do nothing
  }
}
