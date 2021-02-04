/*!
 * remark (http://getbootstrapadmin.com/remark)
 * Copyright 2016 amazingsurge
 * Licensed under the Themeforest Standard Licenses
 */
(function(document, window, $) {
  'use strict';

  var Site = window.Site;

  $(document).ready(function($) {
    Site.run();
  });


  $('#inputUpload').on('click', function(e) {
    e.stopPropagation();
  });

  $('#uploadlink').on('click', function(e) {
    e.stopPropagation();
  });

  (function() {
    // bind checklist and progress bar
    $('input[type=checkbox]').on('click', function() {
      var $checklistItems = $('.project-checklist .checkbox-custom');
      var allLength = $checklistItems.length;
      var checkedLength = 0;
      for (var i = 0; i < allLength; i++) {
        if ($($checklistItems[i]).find('input').prop('checked')) {
          checkedLength++;
        }
      };
      var percent = 100 * (checkedLength / allLength);
      $('.project-checklist [data-plugin="progress"]').asProgress('go', percent);
    });

    //bind add checklist btn
    $('.project-checklist .btn-add').on('click', function() {
      var $projectChecklist = $('.project-checklist');
      $projectChecklist.toggleClass('checklist-editable');
    });
  })();
})(document, window, jQuery);
