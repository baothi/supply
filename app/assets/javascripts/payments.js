$(document).ready(function() {
  $(".remove-card-icon").on('click',function() {
    id = $(this).data("identifier");
    old_url = $(".confirm-remove-card").attr("href");
    new_url = old_url + '?id=' + id;
    $(".confirm-remove-card").attr("href", new_url)
  })
})