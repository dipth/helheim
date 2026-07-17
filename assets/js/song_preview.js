// Plays 30 second song previews via buttons rendered by
// HelheimWeb.SongView.preview_button/3. Only one preview plays at a time:
// starting one stops whatever else was playing, and clicking the button
// of the playing preview stops it again.
export var SongPreview = {
  audio: null,
  button: null,

  run: function(){
    const buttons = document.querySelectorAll('.song-preview-button');

    for (let i = 0; i < buttons.length; i++) {
      buttons[i].addEventListener('click', (event) => {
        event.preventDefault();
        this.toggle(event.currentTarget);
      });
    }
  },

  toggle: function(button){
    const wasPlaying = (this.button === button);
    this.stop();
    if (!wasPlaying) { this.play(button); }
  },

  play: function(button){
    // Only try to play if the browser supports it
    try {
      const audio = new Audio(button.dataset.previewUrl);
      this.audio = audio;
      this.button = button;
      this.setIcon('fa-circle-o-notch fa-spin');
      audio.addEventListener('playing', () => { if (this.audio === audio) { this.setIcon('fa-stop'); } });
      audio.addEventListener('ended', () => { if (this.audio === audio) { this.stop(); } });
      audio.addEventListener('error', () => { if (this.audio === audio) { this.stop(); } });
      audio.play().catch(() => { if (this.audio === audio) { this.stop(); } });
    } catch(e) {
      this.stop();
    }
  },

  stop: function(){
    if (this.audio) {
      this.audio.pause();
      this.audio = null;
    }
    this.setIcon('fa-play');
    this.button = null;
  },

  setIcon: function(icon){
    if (!this.button) { return; }
    const iconElm = this.button.querySelector('i');
    if (iconElm) { iconElm.className = 'fa fa-fw ' + icon; }
  }
}
