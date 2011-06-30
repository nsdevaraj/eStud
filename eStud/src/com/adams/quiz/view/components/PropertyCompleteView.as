package com.adams.quiz.view.components
{
	
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ListCollectionView;
	import mx.collections.Sort;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.FlexEvent;
	import mx.events.FlexMouseEvent;
	import mx.events.SandboxMouseEvent;
	
	import org.osflash.signals.Signal;
	
	import spark.components.Group;
	import spark.components.List;
	import spark.components.PopUpAnchor;
	import spark.components.TextInput;
	import spark.components.supportClasses.SkinnableComponent;
	import spark.events.TextOperationEvent;
	
	[Event (name="enter", type="mx.events.FlexEvent")]
	[Event (name="change", type="spark.events.TextOperationEvent")]
	public class PropertyCompleteView extends SkinnableComponent
	{
		
		private var collection:ListCollectionView = new ArrayCollection();
		
		private var _selectedSignal:Signal;
		public function get selectedSignal():Signal {
			if( !_selectedSignal ) {
				_selectedSignal = new Signal();
			}
			return _selectedSignal;
		}
		
		public var maxRows:Number = 6;
		public var minChars:Number = 1;
		public var prefixOnly:Boolean = false;
		public var requireSelection:Boolean = false;
		public var returnField:String;
		public var sortFunction:Function = defaultSortFunction;
		public var forceOpen:Boolean;
		public var maxChars:Number = 30;
		public var restrict:String = null;
		
		[SkinPart(required="true",type="spark.components.Group")]
		public var dropDown:Group;
		[SkinPart(required="true",type="spark.components.PopUpAnchor")]
		public var popUp:PopUpAnchor;
		[SkinPart(required="true",type="spark.components.List")]
		public var list:List;
		[SkinPart(required="true",type="spark.components.TextInput")]
		public var inputTxt:TextInput;
		
		public function PropertyCompleteView()
		{
			super();
			mouseEnabled = true;
			addEventListener( MouseEvent.MOUSE_OUT, onMouseOut );
			collection.addEventListener( CollectionEvent.COLLECTION_CHANGE, collectionChange );
		}
		
		override protected function partAdded( partName:String, instance:Object ):void {
			super.partAdded( partName, instance );
			
			if( instance == inputTxt ) {
				inputTxt.addEventListener( FocusEvent.FOCUS_OUT, _focusOutHandler );
				inputTxt.addEventListener( FocusEvent.FOCUS_IN, _focusInHandler );
				inputTxt.addEventListener( TextOperationEvent.CHANGE, onChange );
				inputTxt.addEventListener( "keyDown", onKeyDown );
				inputTxt.addEventListener( FlexEvent.ENTER, onEnter );
				inputTxt.text = _text;
				inputTxt.maxChars = maxChars;
				inputTxt.restrict = restrict;
			}
			if( instance == list ) {
				list.dataProvider = collection;
				list.labelField = labelField;
				list.labelFunction = labelFunction;
				list.addEventListener( FlexEvent.CREATION_COMPLETE, addClickListener );
				list.focusEnabled = false;
				list.requireSelection = requireSelection;
			}
			if( instance == dropDown ) {
				dropDown.addEventListener( FlexMouseEvent.MOUSE_DOWN_OUTSIDE, mouseOutsideHandler );	
				dropDown.addEventListener( FlexMouseEvent.MOUSE_WHEEL_OUTSIDE, mouseOutsideHandler );				
				dropDown.addEventListener( SandboxMouseEvent.MOUSE_DOWN_SOMEWHERE, mouseOutsideHandler );
				dropDown.addEventListener( SandboxMouseEvent.MOUSE_WHEEL_SOMEWHERE, mouseOutsideHandler );
			}
		}
		
		private var _dataProvider:Object;
		[Bindable]
		public function get dataProvider():Object { 
			return collection; 
		}
		public function set dataProvider( value:Object ):void {
			if( value is Array ) {
				collection = new ArrayCollection( value as Array );
			}	
			else if( value is ListCollectionView ) {
				collection = value as ListCollectionView;
				collection.addEventListener( CollectionEvent.COLLECTION_CHANGE, collectionChange );
			}
			
			if ( list ) {
				list.dataProvider = collection;
			}
			
			filterData();
		}
		
		
		private function collectionChange(event:CollectionEvent):void{
			if( event.kind == CollectionEventKind.RESET || event.kind == CollectionEventKind.ADD ) {
				filterData();
			}	
		}
		
		private var _text:String = "";
		public function get text():String{
			return _text;
		}
		public function set text( t:String ):void{
			_text = t;
			if( inputTxt ) {
				inputTxt.text = t;
			}
		}
		
		private var _labelField:String;
		public function get labelField():String { 
			return _labelField; 
		}
		public function set labelField( value:String ):void {
			_labelField = value; 
			if( list ) {
				list.labelField = value; 
			}
		}
		
		private var _labelFunction:Function;
		public function get labelFunction():Function {
			return _labelFunction; 
		}
		public function set labelFunction( value:Function ):void	{
			_labelFunction = value; 
			if( list ) {
				list.labelFunction = value; 
			}
		}
		
		private var _selectedItem:Object;
		public function get selectedItem():Object	{ 
			return _selectedItem; 
		}
		public function set selectedItem( value:Object ):void {
			_selectedItem = value;
			if( collection.length != 0 ) {
				text = returnFunction( value );
			}	
		}
		
		private var _selectedIndex : int = -1;
		public function get selectedIndex():int { 
			return _selectedIndex; 
		}
		
		private function onChange( event:TextOperationEvent ):void {
			_text = inputTxt.text;
			
			filterData();
			
			if( text.length >= minChars ) {
				filterData();
			}
			
			dispatchEvent( event ); 
		}
		
		public function filterData():void {
			if( !this.focusManager || this.focusManager.getFocus() != inputTxt ) 
				return;
			
			if( !popUp )
				return;
			
			collection.filterFunction = filterFunction;
			
			var customSort:Sort = new Sort();
			customSort.compareFunction = sortFunction;
			collection.sort = customSort;	
			collection.refresh();
			
			if( ( text == "" || collection.length == 0 ) && !forceOpen ) {
				popUp.displayPopUp = false;
			}
			else {
				popUp.displayPopUp = true;
				if( requireSelection ) {
					list.selectedIndex = 0;
				}	
				else {
					list.selectedIndex = -1;
				}
				
				list.dataGroup.verticalScrollPosition = 0;
				list.dataGroup.horizontalScrollPosition = 0;
				list.height = Math.min( maxRows, collection.length ) * 22 + 2 ;
				list.validateNow();
				popUp.width = inputTxt.width;
			}
		}
		
		public function filterFunction( item:Object ):Boolean {
			var label:String = itemToLabel( item ).toLowerCase();
			
			if( prefixOnly ) {
				if( label.search( text.toLowerCase() ) == 0 ) { 
					return true;
				}	
				else { 
					return false;
				}	
			}
			else {
				if( label.search( text.toLowerCase() ) != -1 ) {
					return true;
				}
			}
			return false;
		}
		
		public function itemToLabel( item:Object ):String {
			if( !item ) 
				return "";
			
			if( labelFunction != null ) {
				return labelFunction( item );
			}	
			else if ( labelField && item[ labelField ] ) {
				return item[ labelField ];
			}	
			else {
				return item.toString();
			}	
		}
		
		private function returnFunction( item:Object ):String {
			if( !item ) {
				return "";
			}
			
			if( returnField ) {
				return item[ returnField ];
			}	
			else {
				return itemToLabel( item );
			}	
		}
		
		public function defaultSortFunction( item1:Object, item2:Object, fields:Array = null ):int {
			var label1:String = itemToLabel( item1 );
			var label2:String = itemToLabel( item2 );
			if( label1 < label2 ) { 
				return -1;
			}	
			else if( label1 == label2 ) { 
				return 0;
			}	
			else {
				return 1;
			}	
		}
		
		private function onKeyDown( event: KeyboardEvent ):void {
			if( popUp.displayPopUp ) {
				switch( event.keyCode ) {
					case Keyboard.UP:
					case Keyboard.DOWN:
					case Keyboard.END:
					case Keyboard.HOME:
					case Keyboard.PAGE_UP:
					case Keyboard.PAGE_DOWN:
						inputTxt.selectRange( text.length, text.length );
						list.dispatchEvent( event );
						break;
					case Keyboard.ENTER:
						acceptCompletion();
						break;
					case Keyboard.TAB:
						if( requireSelection ) {
							acceptCompletion();
						}	
						else {
							popUp.displayPopUp = false;
						}		
						break;
					case Keyboard.ESCAPE:
						popUp.displayPopUp = false;
						break;
					default:
						break;
				}
			}
		}
		
		private function onEnter(event:FlexEvent):void{
			if( popUp.displayPopUp && list.selectedIndex > -1 ) 
				return;
			dispatchEvent( event );
		}
		
		private function onMouseOut( event:MouseEvent ):void {
			Mouse.cursor = MouseCursor.AUTO;
		}
		
		public function acceptCompletion():void {
			if( list.selectedIndex >= 0 && collection.length > 0 ) {
				_selectedIndex = list.selectedIndex;
				_selectedItem = collection.getItemAt( _selectedIndex );
				text = returnFunction( _selectedItem );
				inputTxt.selectRange( inputTxt.text.length, inputTxt.text.length );
			}
			else {
				_selectedIndex = list.selectedIndex = -1;
				_selectedItem = null;
			}
			popUp.displayPopUp = false;
			selectedSignal.dispatch( selectedItem );
		}	
		
		private function _focusInHandler( event:FocusEvent ):void {
			if( forceOpen ) {
				filterData();
			}
		}
		
		private function _focusOutHandler( event:FocusEvent ):void {
			close( event );
			if( collection.length == 0 ) {
				_selectedIndex = -1;
				selectedItem = null;
			}
		}
		
		private function mouseOutsideHandler( event:Event ):void {
			if( event is FlexMouseEvent ) {
				var e:FlexMouseEvent = event as FlexMouseEvent;
				if( inputTxt.hitTestPoint( e.stageX, e.stageY ) ) 
					return;
			}
			close( event );
		}
		
		private function close( event:Event=null ):void {
			if( popUp ) {
				popUp.displayPopUp = false;
			}
		}
		
		private function addClickListener( event:FlexEvent ):void {
			list.dataGroup.addEventListener( MouseEvent.CLICK, listItemClick );
		}
		
		private function listItemClick( event:MouseEvent ):void {
			acceptCompletion();
			event.stopPropagation();
		}
		
		override public function set enabled( value:Boolean ):void {
			super.enabled = value;
			if( inputTxt ) {
				inputTxt.enabled = value;
			}
			if( !value ) {
				close();
			}
		}
	}
}