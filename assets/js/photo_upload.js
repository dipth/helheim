export var PhotoUpload = {
  run: function(){
    let dropzone = $('#photo-dropzone')
    let photos   = $('#photos')

    if (dropzone.length == 0) { return }

    Dropzone.options.photoDropzone = {
      maxFilesize: 5, // MB
      maxThumbnailFilesize: 10, // MB
      acceptedFiles: 'image/*',
      success: (file, response) => {
        $.globalEval(response)
      }
    }
  }
}
