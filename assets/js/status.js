import {Socket, Presence} from "phoenix"

export var Status = {
  run: function(){
    let env = jQuery('meta[name="env"]').attr('content');
    let guardianToken = jQuery('meta[name="guardian_token"]').attr('content');

    if (env == 'test') {
      return;
    }

    let socket = new Socket("/socket", {params: {guardian_token: guardianToken}})
    socket.connect()

    // Now that you are connected, you can join channels with a topic:
    let channel = socket.channel("status", {guardian_token: guardianToken})
    channel.join()
      // .receive("ok", resp => { console.log("status.js: Joined successfully", resp) })
      // .receive("error", resp => { console.log("status.js: Unable to join", resp) })

    // channel.on("presence_state", state => {
    //   let presences = null //Presence.syncState(presences, state)
    //   console.log("presence_state", state, presences)
    // })

    // channel.on("presence_diff", diff => {
    //   let presences = null //Presence.syncDiff(presences, diff)
    //   console.log("presence_diff", diff, presences)
    // })
  },
}
