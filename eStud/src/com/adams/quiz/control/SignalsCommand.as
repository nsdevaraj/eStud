/*

Copyright (c) 2011 Adams Studio India, All Rights Reserved 

@author   NS Devaraj
@contact  nsdevaraj@gmail.com
@project  QuizMaster

@internal 

*/
package com.adams.quiz.control
{
	import com.adams.quiz.model.AbstractDAO;
	import com.adams.quiz.model.vo.*;
	import com.adams.quiz.signal.ControlSignal;
	import com.adams.quiz.util.Utils;
	import com.adams.quiz.view.mediators.MainViewMediator;
	import com.adams.swizdao.model.vo.CurrentInstance;
	import com.adams.swizdao.model.vo.SignalVO;
	import com.adams.swizdao.response.SignalSequence;
	import com.adams.swizdao.util.Action;
	import com.adams.swizdao.views.mediators.IViewMediator;
	
	public class SignalsCommand
	{
		
		[Inject]
		public var controlSignal:ControlSignal;
		
		[Inject]
		public var mainViewMediator:MainViewMediator;
		
		[Inject]
		public var currentInstance:CurrentInstance; 
		
		[Inject]
		public var signalSequence:SignalSequence;
		
		[Inject("questionitemDAO")]
		public var questionitemDAO:AbstractDAO;
		
		[Inject("menuDAO")]
		public var menuDAO:AbstractDAO;
		
		// todo: add listener
		/**
		 * Whenever an LoadMenuSignal is dispatched.
		 * MediateSignal initates this loadmenuAction to perform control Actions
		 * The invoke functions to perform control functions
		 */
		[ControlSignal(type='loadMenuSignal')]
		public function loadmenuAction(obj:IViewMediator):void {
			var signal:SignalVO = new SignalVO(obj,menuDAO,Action.HTTP_REQUEST);
			signal.emailBody = currentInstance.config.serverLocation+Utils.LAUNCHXML+Utils.XML;
			signal.receivers = ['menu','quiz'];
			signalSequence.addSignal(signal);
		}
		
		/**
		 * Whenever an LoadXMLSignal is dispatched.
		 * MediateSignal initates this loadxmlAction to perform control Actions
		 * The invoke functions to perform control functions
		 */
		[ControlSignal(type='loadXMLSignal')]
		public function loadxmlAction(obj:IViewMediator):void {
			var signal:SignalVO = new SignalVO(obj,questionitemDAO,Action.HTTP_REQUEST);
			var currentChapter:Chapter = currentInstance.mapConfig.currentChapter as Chapter;
			var currentMenu:Menu = currentChapter.menu;
			signal.emailBody = currentInstance.config.serverLocation+currentMenu.menuXML+Utils.fileSplitter + currentChapter.chapterXML+Utils.XML;
			trace(signal.emailBody )
			signal.receivers = ['item','topics'];
			signalSequence.addSignal(signal);
		}
		
		/**
		 * Whenever an ChangeStateSignal is dispatched.
		 * MediateSignal initates this changestateAction to perform control Actions
		 * The invoke functions to perform control functions
		 */
		[ControlSignal(type='changeStateSignal')]
		public function changestateAction(state:String):void {
			mainViewMediator.view.currentState = state;
		}
	}
}