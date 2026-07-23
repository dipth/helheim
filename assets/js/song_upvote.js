// Asynchronously toggles song upvotes via the badge buttons rendered by
// HelheimWeb.SongView.upvote_toggle/3, without a full page load. The
// server responds with the resulting state and all-time count, and every
// badge for the same song on the page is snapped to it - the toggle
// always shows the total, so the server's count can simply overwrite
// whatever is displayed (windowed chart counts live in separate,
// non-interactive badges).
//
// A session that expired while the page was open would otherwise fail
// invisibly (the fetch follows the auth redirect and gets the sign-in
// page), so redirected responses navigate there instead; other failures
// briefly flash the button red.
export var SongUpvote = {
  run: function(){
    const buttons = document.querySelectorAll('.song-upvote-button');

    for (let i = 0; i < buttons.length; i++) {
      buttons[i].addEventListener('click', (event) => {
        event.preventDefault();
        this.toggle(event.currentTarget);
      });
    }
  },

  toggle: function(button){
    if (button.dataset.busy) { return; }
    button.dataset.busy = 'true';
    const upvoted = button.dataset.upvoted === 'true';

    fetch(button.dataset.upvoteUrl, {
      method: upvoted ? 'DELETE' : 'POST',
      headers: {
        'x-csrf-token': this.csrfToken(),
        'accept': 'application/json'
      },
      credentials: 'same-origin'
    })
      .then((response) => {
        if (response.redirected) {
          window.location.href = response.url;
          return null;
        }
        if (!response.ok) { throw new Error('upvote failed: ' + response.status); }
        return response.json();
      })
      .then((data) => { if (data) { this.sync(button.dataset.songId, data); } })
      .catch(() => { this.flashError(button); })
      .finally(() => { delete button.dataset.busy; });
  },

  sync: function(songId, data){
    const buttons = document.querySelectorAll('.song-upvote-button[data-song-id="' + songId + '"]');

    for (let i = 0; i < buttons.length; i++) {
      const button = buttons[i];

      button.dataset.upvoted = String(data.upvoted);
      button.classList.toggle('badge-primary', data.upvoted);
      button.classList.toggle('badge-default', !data.upvoted);

      const title = data.upvoted ? button.dataset.titleRemove : button.dataset.titleUpvote;
      button.title = title;
      button.setAttribute('aria-label', title);
      button.setAttribute('aria-pressed', String(data.upvoted));

      const count = button.querySelector('.song-upvote-count');
      if (count) { count.textContent = data.upvotes_count; }
    }
  },

  flashError: function(button){
    button.classList.add('badge-danger');
    setTimeout(() => { button.classList.remove('badge-danger'); }, 1500);
  },

  csrfToken: function(){
    return document.body.dataset.csrf || '';
  }
}
