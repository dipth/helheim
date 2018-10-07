let regEx = /\[youtube\](.+?)\[\/youtube\]/gi

let replacer = function(match, videoId) {
  return `
    <div class="embed-responsive embed-responsive-16by9">
      <iframe class="embed-responsive-item" width="560" height="315" src="https://www.youtube-nocookie.com/embed/${videoId}?rel=0" frameborder="0" allowfullscreen></iframe>
    </div>
  `;
}

export var YoutubeEmbed = {
  run: function(el){
    el.html(el.html().replace(regEx, replacer));
  },
}
