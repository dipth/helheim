import { YoutubeEmbed } from "./youtube";
import { VimeoEmbed } from "./vimeo";
import { GiphyEmbed } from "./giphy";
import { ImgurEmbed } from "./imgur";
import { SoundCloudEmbed } from "./soundcloud";

import EmbedJS from 'embed-js';
import url from 'embed-plugin-url';
import noembed from 'embed-plugin-noembed';

export var Embeds = {
  run: function(){
    window.process = {}

    $('.embeds').each(function(index){
      let el = $(this);
      let x = new EmbedJS({
        input: el[0],
        plugins: [
          url(),
          noembed({})
        ],
        replaceUrl: true
      });

      x.render();

      // Legacy
      // YoutubeEmbed.run(el);
      // VimeoEmbed.run(el);
      // GiphyEmbed.run(el);
      // ImgurEmbed.run(el);
      // SoundCloudEmbed.run(el);
    })
  },
}
