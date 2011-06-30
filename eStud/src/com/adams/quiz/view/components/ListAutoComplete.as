package com.adams.quiz.view.components
{
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	import spark.components.List;
	
	public class ListAutoComplete extends List
	{
		public function ListAutoComplete() {
			super();
		}
		
		override protected function keyDownHandler( event:KeyboardEvent ):void {
			super.keyDownHandler( event );
			if ( ( !dataProvider ) || ( !layout ) || ( event.isDefaultPrevented() ) )
				return;	
			adjustSelectionAndCaretUponNavigation( event ); 
		}
	}
}