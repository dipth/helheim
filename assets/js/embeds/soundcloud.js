let regEx = /\[soundcloud\](.+?)\[\/soundcloud\]/gi

let replacer = function(match, trackId) {
  return `
    <iframe width="100%" height="166" scrolling="no" frameborder="no" src="https://w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/${trackId}&amp;color=ef4c25&amp;auto_play=false&amp;hide_related=false&amp;show_comments=true&amp;show_user=true&amp;show_reposts=false"></iframe>
  `;
}

export var SoundCloudEmbed = {
  run: function(el){
    el.html(el.html().replace(regEx, replacer));
  },
}
