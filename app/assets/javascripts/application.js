// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require global/vendor/babel-external-helpers/babel-external-helpers
//= require jquery
//= require jquery_ujs
// require ckeditor-jquery
//= require global/vendor/tether/tether.js
//= require global/vendor/bootstrap/bootstrap.js
//= require global/vendor/animsition/animsition.js
//= require global/vendor/mousewheel/jquery.mousewheel.js
//= require global/vendor/asscrollbar/jquery-asScrollbar.js
//= require global/vendor/asscrollable/jquery-asScrollable.js
//= require global/vendor/ashoverscroll/jquery-asHoverScroll.js
//= require select2

//= require global/vendor/switchery/switchery.min.js
//= require global/vendor/intro-js/intro.js
//= require global/vendor/screenfull/screenfull.js
//= require global/vendor/slidepanel/jquery-slidePanel.js
//= require global/vendor/jquery-ui/jquery-ui-custom-without-tooltip.js
//= require global/vendor/chartist/chartist.min.js
//= require global/vendor/aspieprogress/jquery-asPieProgress.js
//= require global/vendor/asprogress/jquery-asProgress.js
//= require global/vendor/chartist-plugin-tooltip/chartist-plugin-tooltip.min.js
//= require global/vendor/jquery-placeholder/jquery.placeholder.js
//= require global/vendor/breakpoints/breakpoints.js
//= require global/vendor/chart-js/Chart.js
//= require global/vendor/blueimp-tmpl/tmpl.js
//= require global/vendor/blueimp-canvas-to-blob/canvas-to-blob.js
//= require global/vendor/blueimp-load-image/load-image.all.min.js
//= require global/vendor/blueimp-file-upload/jquery.fileupload.js
//= require global/vendor/blueimp-file-upload/jquery.fileupload-process.js
//= require global/vendor/blueimp-file-upload/jquery.fileupload-image.js
//= require global/vendor/blueimp-file-upload/jquery.fileupload-audio.js
//= require global/vendor/blueimp-file-upload/jquery.fileupload-video.js
//= require global/vendor/blueimp-file-upload/jquery.fileupload-validate.js
//= require global/vendor/blueimp-file-upload/jquery.fileupload-ui.js
//= require global/vendor/dropify/dropify.min.js
//= require global/vendor/summernote/summernote.min.js
//= require global/vendor/toastr/toastr.min.js
// require global/vendor/slick-carousel/slick.js
//= require global/vendor/owl-carousel/owl.carousel.js



// Core
//= require global/js/State.js
//= require global/js/Component.js
//= require global/js/Plugin.js
//= require global/js/Base.js
//= require global/js/Config.js
//= require core/Section/Menubar.js
//= require core/Section/GridMenu.js
//= require core/Section/Sidebar.js
//= require core/Section/PageAside.js
//= require core/Plugin/menu.js
//= require global/js/config/colors.js
//= require core/config/tour.js
//= require core/Site.js.erb

// Inner Site
//= require global/js/Plugin/asscrollable.js
//= require global/js/Plugin/asselectable.js
//= require global/js/Plugin/selectable.js
//= require global/js/Plugin/slidepanel.js
//= require global/js/Plugin/switchery.js
//= require global/js/Plugin/asprogress.js
//= require global/js/Plugin/responsive-tabs.js
//= require global/js/Plugin/closeable-tabs.js
//= require global/js/Plugin/tabs.js
//= require global/js/Plugin/aspieprogress.js
//= require global/js/Plugin/dropify.js
//= require global/js/Plugin/owl-carousel.js
// require global/js/Plugin/toastr.min.js
// require example/ecommerce.js // Removed for now
//= require example/project.js
// require example/carousel.js
//= require algolia/v3/algoliasearch.min

// Custom
//= require orders.js
//= require supplier/orders.js
//= require payments.js
//= require retailer/team.js
//= require retailer/product.js
//= require supplier/products.js
//= require algolia.js
//= require ckeditor/index.js
//= require jsoneditor-minimalist
// require stripe.js
// require turbolinks

// Action Cable


$(document).on('ready page:load', function(){
  $('.carousel').carousel({interval: 5000});

  $('.carousel-control').click(function(e){
    e.preventDefault();
    $('.carousel').carousel( $(this).data());
  });

  $('.carousel-inner').each(function(){
    if($(this).children('div').length === 1) {
      $(this).siblings('.carousel-control, .carousel-indicators').hide();
    }
  })

});
