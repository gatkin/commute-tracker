using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using CommuteActivity as CommuteActivity;

var commuteActivityView = null;


class CommuteTrackerApp extends App.AppBase {

    //! onStart() is called on application start up
    function onStart() {
    }

    //! onStop() is called when your application is exiting
    function onStop() {
    }

    //! Return the initial view of your application here
    function getInitialView() {
        return [ new MainView(), new CommuteTrackerDelegate() ];
    }
}



class CommuteTrackerDelegate extends Ui.BehaviorDelegate {

    function onMenu() {
        Ui.pushView(new Rez.Menus.MainMenu(), new MainMenuDelegate(), Ui.SLIDE_UP);
        return true;
    }
}


function getCommuteActivityView() {
	if( commuteActivityView == null ) {
		commuteActivityView= new CommuteActivity.CommuteActivityView();
	}
	return commuteActivityView;
}


