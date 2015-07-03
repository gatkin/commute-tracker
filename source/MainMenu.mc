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

    //! Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
    }

    //! Update the view
    function onUpdate(dc) {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    function onHide() {
    }

}


