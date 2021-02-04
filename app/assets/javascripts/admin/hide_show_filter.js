$(document).ready(function(){
    var sidebar = $("#sidebar"); 
    if(sidebar.length) {
      $(".action_items").append(
        "<span class='action_item'> \
          <a href='#' id='hide-filter'>Hide Filters</a> \
        </span>"
      )
    }
    var btnFilter = $("#hide-filter");
    $("#hide-filter").click(function(){
      sidebar.toggle(function(){
        btnFilter.text(function(index, text) {
        return text === 'Hide Filters' ? 'Show Filters' : 'Hide Filters'
      })
      });
    })
  })
  