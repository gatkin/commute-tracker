using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class CommuteTrackerApp extends App.AppBase {

    //! onStart() is called on application start up
    function onStart() {
    }

    //! onStop() is called when your application is exiting
    function onStop() {
    }

    //! Return the initial view of your application here
    function getInitialView() {
        return [ new CommuteTrackerView(), new CommuteTrackerDelegate() ];
    }

}

class CommuteTrackerDelegate extends Ui.BehaviorDelegate {

    function onMenu() {
        Ui.pushView(new Rez.Menus.MainMenu(), new CommuteTrackerMenuDelegate(), Ui.SLIDE_UP);
        return true;
    }

}