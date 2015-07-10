using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using CommuteHistory as CommuteHistory;
using CommuteActivity as CommuteActivity;


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


class MainMenuDelegate extends Ui.MenuInputDelegate {
	
    function onMenuItem(item) {
        if (item == :start) {
    		var activityContoller = CommuteActivity.getCommuteActivityController();
    		Ui.pushView(activityContoller.getActivityView(), activityContoller.getActivityDelegate(), Ui.SLIDE_LEFT);
        } else if (item == :history) {
            var historyController = new CommuteHistory.CommuteHistoryController();
			Ui.pushView(historyController.getView(), historyController, Ui.SLIDE_LEFT);
        }
    }
}

class MainView extends Ui.View {

	hidden var hasShownMenu = false;
    
    function onShow() {
    	if( !hasShownMenu ) {
			Ui.pushView(new Rez.Menus.MainMenu(), new MainMenuDelegate(), Ui.SLIDE_UP);
			hasShownMenu = true;
		} else {
			Ui.popView(Ui.SLIDE_IMMEDIATE);
		} 
    }
    
}

class CommuteTrackerDelegate extends Ui.BehaviorDelegate {

    function onKey(keyEvent) {
		var key = keyEvent.getKey();
		if( key == Ui.KEY_ENTER || key == Ui.KEY_ESC ) {
			Ui.popView(Ui.SLIDE_RIGHT);
		} 
	}
}





