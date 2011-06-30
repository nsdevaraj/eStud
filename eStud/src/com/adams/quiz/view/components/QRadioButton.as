package com.adams.quiz.view.components
{
	import flash.events.MouseEvent;
	
	import org.osflash.signals.natives.NativeSignal;
	
	import spark.components.RadioButton;
	
	public class QRadioButton extends RadioButton
	{
		public var clicked:NativeSignal
		public var correctAnswer:Boolean;
		public function QRadioButton()
		{
			super();
			clicked = new NativeSignal( this, MouseEvent.CLICK, MouseEvent );
		}
	}
}