export var PhotoUpload = {
  run: function(){
    let dropzone = $('#photo-dropzone')
    let photos   = $('#photos')

    if (dropzone.length == 0) { return }

    Dropzone.options.photoDropzone = {
      maxFilesize: 5, // MB
      maxThumbnailFilesize: 5, // MB
      acceptedFiles: 'image/*',
      parallelUploads: 1,
      success: (file, response) => {
        $.globalEval(response)
      }
    }
  }
}
