function setPasswordEyeToggle() {
  $("#password_eye").hover(function(){
    var pwd = $("#user_password");

    if(pwd.prop("type") === "password") {
      pwd.prop("type", "text");
      $(this).css('color', '#62a8ea');
    } else {
      pwd.prop("type", "password");
      $(this).css('color', '#777777');
    }
  });
}

$(document).ready(function() {
  setPasswordEyeToggle();
});
