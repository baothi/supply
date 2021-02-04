$(document).ready(function() {

  // $('.product_description').froalaEditor();
  function variantImagePreview(){
    $(".open-image-preview").on("click", function(e){
      var imgSrc = $(this).data('src');

      $(".variant-image-preview").attr('src', imgSrc);
    })
  }

  variantImagePreview();
})