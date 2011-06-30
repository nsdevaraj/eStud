/*

Copyright (c) 2011 Adams Studio India, All Rights Reserved 

@author   NS Devaraj
@contact  nsdevaraj@gmail.com
@project  eStud

@internal 

*/
package com.adams.quiz.view.mediators
{ 
	import com.adams.quiz.model.AbstractDAO;
	import com.adams.quiz.model.vo.*;
	import com.adams.quiz.signal.ControlSignal;
	import com.adams.quiz.util.RandomSequence;
	import com.adams.quiz.util.Utils;
	import com.adams.quiz.view.QuizSkinView;
	import com.adams.quiz.view.components.QRadioButton;
	import com.adams.swizdao.model.vo.*;
	import com.adams.swizdao.views.mediators.AbstractViewMediator;
	
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	
	import spark.events.TextOperationEvent;
	
	
	public class QuizViewMediator extends AbstractViewMediator
	{ 		 
		
		[Inject]
		public var currentInstance:CurrentInstance; 
		
		[Inject]
		public var controlSignal:ControlSignal;
		
		private var randomList:ArrayCollection = new ArrayCollection();
		private var currentQuestion:QuestionItem;
		private var currentPosition:int;
		private var oldPosition:int;
		
		private var maxPosition:int;
		private var _homeState:String;
		
		[Inject("chapterDAO")]
		public var chapterDAO:AbstractDAO;
		public function get homeState():String
		{
			return _homeState;
		}
		
		public function set homeState(value:String):void
		{
			_homeState = value;
			if(value==Utils.QUIZ_INDEX) addEventListener(Event.ADDED_TO_STAGE,addedtoStage);
		}
		
		protected function addedtoStage(ev:Event):void{
			init();
		}
		
		/**
		 * Constructor.
		 */
		public function QuizViewMediator( viewType:Class=null )
		{
			super( QuizSkinView ); 
		}
		
		/**
		 * Since the AbstractViewMediator sets the view via Autowiring in Swiz,
		 * we need to create a local getter to access the underlying, expected view
		 * class type.
		 */
		public function get view():QuizSkinView 	{
			return _view as QuizSkinView;
		}
		
		[MediateView( "QuizSkinView" )]
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
			viewState = Utils.QUIZ_INDEX;
			var rs:RandomSequence=new RandomSequence(0,currentInstance.mapConfig.randomList.length-1);
			var _array:Array=rs.getSequence();
			randomList = new ArrayCollection();
			for(var i:int=0;i<_array.length;i++){
				randomList.addItem(currentInstance.mapConfig.randomList.getItemAt(_array[i]));				
			}
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
		
		protected function getRandomListOfQuestions(collection:IList):ArrayCollection{
			var rs:RandomSequence=new RandomSequence(0,collection.length-1);
			var _array:Array=rs.getSequence();
			var choices:ArrayCollection = new ArrayCollection();
			for(var i:int=0; i<collection.length-1; i++){
				var newChoice:String = QuestionItem(collection.getItemAt(_array[i])).choice
				if(choices.source.indexOf(newChoice)==-1)	choices.addItem(newChoice);
			} 
			return choices;
		}
		
		protected function setAllWrongChoices():void {
			var getChapter:Chapter= new Chapter();
			getChapter.chapterId = currentQuestion.chapter;
			var currentChapter:Chapter = chapterDAO.collection.findExistingItem(getChapter) as Chapter;
			var choices:ArrayCollection = getRandomListOfQuestions(currentChapter.questionsList);
			for(var i:int=0;i<4;i++){
				var qRadio:QRadioButton = view[Utils.CHOICE+int(i+1)];
				qRadio.correctAnswer=false;
				qRadio.label = choices.getItemAt(i) as String;
				qRadio.selected = false;
			}
		}
		
		protected function setQuestion(currentQuestion:QuestionItem):void {
			setAllWrongChoices();
			var randomRadio:QRadioButton = view[Utils.CHOICE+Math.round(Math.random()*(4-1)+(1))]
			randomRadio.label = currentQuestion.choice;
			randomRadio.correctAnswer = true;
			view.question.text =currentQuestion.question.split(currentQuestion.choice).join('___')
		}  
		
		/**
		 * Create listeners for all of the view's children that dispatch events
		 * that we want to handle in this mediator.
		 */
		override protected function setViewListeners():void {
			view.home.clicked.add(viewClickHandlers);
			view.back.clicked.add(viewClickHandlers);
			view.next.clicked.add(viewClickHandlers);
			view.choice1.clicked.add(onSelection);
			view.choice2.clicked.add(onSelection);
			view.choice3.clicked.add(onSelection);
			view.choice4.clicked.add(onSelection);
			view.navigate.addEventListener(TextOperationEvent.CHANGE,viewClickHandlers,false,0,true);
			super.setViewListeners(); 
		}
		
		
		protected function onSelection( ev:Event ): void { 
			var currentRadio:QRadioButton = ev.currentTarget as QRadioButton
			if(currentRadio.correctAnswer){
				trace('correct')
			} else{
				trace('wrong')
			}
		}
		
		protected function viewClickHandlers( ev:Event ): void { 
			switch(ev.currentTarget){ 
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