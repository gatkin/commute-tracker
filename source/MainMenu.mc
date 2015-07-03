using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using CommuteHistory as CommuteHistory;


class MainMenuDelegate extends Ui.MenuInputDelegate {

    function onMenuItem(item) {
        if (item == :start) {
    		var view = getCommuteActivityView();
    		Ui.pushView(view, view.getInputDelegate(), Ui.SLIDE_LEFT);
        } else if (item == :history) {
            var controller = new CommuteHistory.CommuteHistoryController();
			Ui.pushView(controller.getView(), controller, Ui.SLIDE_LEFT);
        }
    }
}

class MainView extends Ui.View {

    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

}


