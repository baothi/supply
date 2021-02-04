$(document).ready(function() {
    $("#period-select").change(function() {
        if ($(this).val() !== "period-select-custom") {
            window.location = $(this).val();
            return true;
        }
        $("#date-range-selection").css("visibility", "visible");
    });
});
