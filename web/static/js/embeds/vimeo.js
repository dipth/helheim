let regEx = /\[vimeo\](.+?)\[\/vimeo\]/gi

let replacer = function(match, videoId) {
  return `
    <div class="embed-responsive embed-responsive-16by9">
      <iframe class="embed-responsive-item" src="https://player.vimeo.com/video/${videoId}?color=ffffff&title=0&byline=0&portrait=0" width="640" height="268" frameborder="0" allowfullscreen></iframe>
    </div>
  `;
}

export var VimeoEmbed = {
  run: function(el){
    el.html(el.html().replace(regEx, replacer));
  },
}
