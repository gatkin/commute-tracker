using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class CommuteTrackerMenuDelegate extends Ui.MenuInputDelegate {

    function onMenuItem(item) {
        if (item == :item_1) {
            Sys.println("item 1");
        } else if (item == :item_2) {
            Sys.println("item 2");
        }
    }

}