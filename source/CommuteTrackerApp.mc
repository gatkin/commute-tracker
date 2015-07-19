using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Graphics as Gfx;
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
        return [ new MainView(), new MainViewDelegate() ];
    }
}


class MainView extends Ui.View {
	
	function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
    }
	
    function onUpdate(dc) {
		// Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }
}

class MainViewDelegate extends Ui.BehaviorDelegate {

    function onKey(keyEvent) {
		var key = keyEvent.getKey();
		if(  Ui.KEY_ESC == key ) {
			// Let them leave the App
			Ui.popView( Ui.SLIDE_RIGHT );
		} else {
			// If they press any other key, take them to the main menu of the app
			Ui.pushView( new Rez.Menus.MainMenu(), new MainMenuDelegate(), Ui.SLIDE_UP );
		}
		return true;
	}
}

class MainMenuDelegate extends Ui.MenuInputDelegate {
	
    function onMenuItem(item) {
    	// To save memory, we need to remove the views that are on the view stack,
		// Especially the main view which has the image on it. Since we can't do a 
		// Ui.switchToView with a menu, we need to pop both the menu view and the main
		// view from the view stack
		Ui.popView( Ui.SLIDE_LEFT );
        if ( :start == item ) {
    		var activityController = CommuteActivity.getController();
    		activityController.startCommuteActivity();
        } else if ( :history == item ) {
            var historyController = CommuteHistory.getController();
			historyController.showHistoryChart( Time.now() );
        }
    }
}
