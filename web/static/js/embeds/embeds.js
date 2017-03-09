import { YoutubeEmbed } from "./youtube";
import { VimeoEmbed } from "./vimeo";
import { GiphyEmbed } from "./giphy";
import { ImgurEmbed } from "./imgur";

export var Embeds = {
  run: function(){
    $('.embeds').each(function(index){
      let el  = $(this);
      YoutubeEmbed.run(el);
      VimeoEmbed.run(el);
      GiphyEmbed.run(el);
      ImgurEmbed.run(el);
    })
  },
}
