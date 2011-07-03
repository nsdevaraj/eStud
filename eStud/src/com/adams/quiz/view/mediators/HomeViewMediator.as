/*

Copyright (c) 2011 Adams Studio India, All Rights Reserved 

@author   NS Devaraj
@contact  nsdevaraj@gmail.com
@project  QuizMaster

@internal 

*/
package com.adams.quiz.view.mediators
{ 
	import com.adams.quiz.model.AbstractDAO;
	import com.adams.quiz.model.vo.*;
	import com.adams.quiz.signal.ControlSignal;
	import com.adams.quiz.util.RandomSequence;
	import com.adams.quiz.util.Utils;
	import com.adams.quiz.view.HomeSkinView;
	import com.adams.swizdao.model.vo.*;
	import com.adams.swizdao.util.Action;
	import com.adams.swizdao.views.mediators.AbstractViewMediator;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	
	import spark.events.IndexChangeEvent;
	
	
	public class HomeViewMediator extends AbstractViewMediator
	{ 		 
		
		[Inject]
		public var currentInstance:CurrentInstance; 
		
		[Inject]
		public var controlSignal:ControlSignal;
		
		[Inject("menuDAO")]
		public var menuDAO:AbstractDAO;
		
		[Inject("questionitemDAO")]
		public var questionitemDAO:AbstractDAO;
		
		private var _homeState:String;
		public function get homeState():String
		{
			return _homeState;
		}
		
		public function set homeState(value:String):void
		{
			_homeState = value;
			if(value==Utils.HOME_INDEX) addEventListener(Event.ADDED_TO_STAGE,addedtoStage);
		}
		
		protected function addedtoStage(ev:Event):void{
			init();
		}
		
		/**
		 * Constructor.
		 */
		public function HomeViewMediator( viewType:Class=null )
		{
			super( HomeSkinView ); 
		}
		
		/**
		 * Since the AbstractViewMediator sets the view via Autowiring in Swiz,
		 * we need to create a local getter to access the underlying, expected view
		 * class type.
		 */
		public function get view():HomeSkinView 	{
			return _view as HomeSkinView;
		}
		
		[MediateView( "HomeSkinView" )]
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
			viewState = Utils.HOME_INDEX;
			controlSignal.headerStateSignal.dispatch(this,Utils.HEADER_LOGO_INDEX);
			if(!menuDAO.collection.items)controlSignal.loadMenuSignal.dispatch(this);
		} 
		
		public function backToHome(event:MouseEvent):void {
			view.currentState = Utils.MENU_INDEX;
			controlSignal.headerStateSignal.dispatch(this,Utils.HEADER_LOGO_INDEX);
		}
		
		public function selectMenuHandler(event:IndexChangeEvent=null):void {
			if(event!=null)currentInstance.mapConfig.currentMenu = Menu(view.menuList.selectedItem)
			view.currentState = Utils.CHAPTER_INDEX;
			controlSignal.headerStateSignal.dispatch(this,Utils.HEADER_CHAPTER_INDEX);
			view.chapterList.addEventListener(IndexChangeEvent.CHANGE,selectChapterHandler,false,0,true);
			view.chapterList.dataProvider = currentInstance.mapConfig.currentMenu.chapters;
		} 
		
		protected function selectChapterHandler(event:IndexChangeEvent):void {
			var currentChapter:Chapter = Chapter(view.chapterList.selectedItem);
			currentInstance.mapConfig.currentChapter = currentChapter;
			
			var getQues:QuestionItem = new QuestionItem();
			getQues.chapter = currentChapter.chapterId;
			var currentQuestion:QuestionItem = questionitemDAO.collection.findExistingPropItem(getQues,Utils.CHAPTER_INDEX.toLowerCase()) as QuestionItem;
			if(!currentQuestion){
				Utils.chapterId = currentChapter.chapterId;
				Utils.menuId = currentChapter.menu.menuId;
				controlSignal.loadXMLSignal.dispatch(this);
			}else{
				getRandomListOfQuestions(currentChapter.questionsList);
			}
		}
		
		override protected function serviceResultHandler( obj:Object,signal:SignalVO ):void {  
			if(signal.action == Action.HTTP_REQUEST && signal.destination == Utils.MENUKEY){
				view.menuList.dataProvider = menuDAO.collection.items as ArrayCollection;
			}
			if(signal.action == Action.HTTP_REQUEST && signal.destination == Utils.QUESTIONITEMKEY){
				signal.currentProcessedCollection = new ArrayCollection();
				for each(var qitem:QuestionItem in questionitemDAO.collection.items){
					if(qitem.chapter == Utils.chapterId) signal.currentProcessedCollection.addItem(qitem);
				}
				getRandomListOfQuestions(signal.currentProcessedCollection);
			}
		} 
		
		protected function getRandomListOfQuestions(collection:IList):void{
			currentInstance.mapConfig.randomList = new ArrayCollection();
 			var rs:RandomSequence=new RandomSequence(0,collection.length-1);
			var _array:Array=rs.getSequence();
			var maxLength:int;
			Utils.QLENGTH > collection.length ?maxLength=collection.length :maxLength=Utils.QLENGTH;
			for(var i:int=0; i<maxLength; i++){
				ArrayCollection(currentInstance.mapConfig.randomList).addItem(collection.getItemAt(_array[i]));
			} 
			view.currentState = Utils.MENU_INDEX;
			view.menuList.selectedItem = null;
			controlSignal.headerStateSignal.dispatch(this,Utils.HEADER_LEARN_INDEX);
			controlSignal.changeStateSignal.dispatch(Utils.SEARCH_INDEX);
		}
		/**
		 * Create listeners for all of the view's children that dispatch events
		 * that we want to handle in this mediator.
		 */
		override protected function setViewListeners():void {
			view.menuList.addEventListener(IndexChangeEvent.CHANGE,selectMenuHandler,false,0,true);
			super.setViewListeners(); 
		}
		/**
		 * Remove any listeners we've created.
		 */
		override protected function cleanup( event:Event ):void {
			super.cleanup( event ); 		
		} 
	}
}