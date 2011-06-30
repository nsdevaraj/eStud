/*

Copyright (c) 2011 Adams Studio India, All Rights Reserved 

@author   NS Devaraj
@contact  nsdevaraj@gmail.com
@project  eStud

@internal 

*/
package com.adams.quiz.view.mediators
{ 
	import com.adams.quiz.model.vo.*;
	import com.adams.quiz.signal.ControlSignal;
	import com.adams.quiz.util.Utils;
	import com.adams.quiz.view.LearnSkinView;
	import com.adams.swizdao.model.vo.*;
	import com.adams.swizdao.views.mediators.AbstractViewMediator;
	
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	
	import spark.events.TextOperationEvent;
	
	
	public class LearnViewMediator extends AbstractViewMediator
	{ 		 
		
		[Inject]
		public var currentInstance:CurrentInstance; 
		
		[Inject]
		public var controlSignal:ControlSignal;
		private var randomList:ArrayCollection;
		private var currentQuestion:QuestionItem;
		private var currentPosition:int;
		private var oldPosition:int;
		
		private var maxPosition:int;
		private var _homeState:String;
		public function get homeState():String
		{
			return _homeState;
		}
		
		public function set homeState(value:String):void
		{
			_homeState = value;
			if(value==Utils.LEARN_INDEX) addEventListener(Event.ADDED_TO_STAGE,addedtoStage);
		}
		
		protected function addedtoStage(ev:Event):void{
			init();
		}
		
		/**
		 * Constructor.
		 */
		public function LearnViewMediator( viewType:Class=null )
		{
			super( LearnSkinView ); 
		}
		
		/**
		 * Since the AbstractViewMediator sets the view via Autowiring in Swiz,
		 * we need to create a local getter to access the underlying, expected view
		 * class type.
		 */
		public function get view():LearnSkinView 	{
			return _view as LearnSkinView;
		}
		
		[MediateView( "LearnSkinView" )]
		override public function setView( value:Object ):void { 
			super.setView(value);	
		}  
		/**
		 * The <code>init()</code> method is fired off automatically by the 
		 * AbstractViewMediator when the creation complete event fires for the
		 * corresponding ViewMediator's view. This allows us to listen for events
		 * and set data bindings on the view with the confidence that our view
		 * and all of it's child views have been created and live on the stage.
		 */
		override protected function init():void {
			super.init();  
			viewState = Utils.LEARN_INDEX;
			view.quiz.visible=true;
			randomList= ArrayCollection(currentInstance.mapConfig.randomList);
			currentPosition = 0;
			maxPosition = randomList.length;
			view.totalQs.text = maxPosition.toString();
			setQuestion(gotoQuestion(currentPosition));
		}
		
		protected function gotoQuestion(pos:int):QuestionItem {
			if(pos>=0 && pos<maxPosition){
				currentPosition = pos;
				currentQuestion = randomList.getItemAt(currentPosition) as QuestionItem;
				oldPosition = currentPosition;
			}else{
				currentPosition = oldPosition;
			}
			view.navigate.text = (currentPosition+1).toString();
			return currentQuestion;
		} 
		
		protected function setQuestion(currentQuestion:QuestionItem):void {
			view.choice.text = currentQuestion.choice;
			view.question.text = currentQuestion.question;
		}  
		 
		/**
		 * Create listeners for all of the view's children that dispatch events
		 * that we want to handle in this mediator.
		 */
		override protected function setViewListeners():void {
			view.quiz.clicked.add(viewClickHandlers);
			view.home.clicked.add(viewClickHandlers);
			view.back.clicked.add(viewClickHandlers);
			view.next.clicked.add(viewClickHandlers);
			view.navigate.addEventListener(TextOperationEvent.CHANGE,viewClickHandlers,false,0,true);
			super.setViewListeners(); 
		}
		
		protected function viewClickHandlers( ev:Event ): void { 
			switch(ev.currentTarget){
				case view.quiz:
					controlSignal.changeStateSignal.dispatch(Utils.QUIZ_INDEX);
					break;
				case view.home:
					controlSignal.changeStateSignal.dispatch(Utils.HOME_INDEX);
					break;
				case view.back:
					currentPosition--;
					setQuestion(gotoQuestion(currentPosition));
					break;
				case view.next:
					currentPosition++;
					setQuestion(gotoQuestion(currentPosition));
					break;
				case view.navigate:
					currentPosition = parseInt(view.navigate.text)-1;
					setQuestion(gotoQuestion(currentPosition));
					break;
			}
		} 
		/**
		 * Remove any listeners we've created.
		 */
		override protected function cleanup( event:Event ):void {
			super.cleanup( event ); 		
		} 
	}
}