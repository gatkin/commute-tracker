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
        return [ new MainView(), new CommuteTrackerDelegate() ];
    }
}


class MainMenuDelegate extends Ui.MenuInputDelegate {
	
    function onMenuItem(item) {
        if (item == :start) {
    		var activityContoller = CommuteActivity.getCommuteActivityController();
    		Ui.pushView( activityContoller.getActivityView(), activityContoller.getActivityDelegate(), Ui.SLIDE_LEFT );
        } else if (item == :history) {
            var historyController = CommuteHistory.getController();
			historyController.showHistoryChart( Time.now() );
        }
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

class CommuteTrackerDelegate extends Ui.BehaviorDelegate {

    function onKey(keyEvent) {
		var key = keyEvent.getKey();
		if(  Ui.KEY_ESC == key ) {
			Ui.popView( Ui.SLIDE_RIGHT );
		} else {
			Ui.pushView( new Rez.Menus.MainMenu(), new MainMenuDelegate(), Ui.SLIDE_UP );
		}
	}
}





