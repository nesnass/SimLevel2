import avmplus.getQualifiedClassName;

import flash.desktop.NativeProcess;
import flash.desktop.NativeProcessStartupInfo;
import flash.display.StageDisplayState;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.MouseEvent;
import flash.events.NativeProcessExitEvent;
import flash.events.ProgressEvent;
import flash.events.TimerEvent;
import flash.filesystem.File;
import flash.ui.Mouse;
import flash.utils.Dictionary;
import flash.utils.Timer;
import flash.utils.clearInterval;
import flash.utils.setInterval;

import mx.events.FlexEvent;
import mx.logging.ILogger;
import mx.logging.Log;
import mx.logging.LogEventLevel;
import mx.managers.CursorManager;

import org.osmf.events.TimeEvent;

import spark.components.RichEditableText;

[Embed(systemFont="Arial", fontName = "arialFont", mimeType = "application/x-font", fontWeight="normal", fontStyle="normal", advancedAntiAliasing="true", embedAsCFF="false")]
private var arialFont : Class;

private const PIXEL_INCREMENT:uint = 7;
private var INITIAL_REFERENCE_VALUE:uint = 500;
private var TARGET_HOUSE_TEMP:uint = 18;
private var TARGET_SOURCE_TEMP:uint = 10;

private var timeCounter:uint = 0;
[Bindable] private var tempTable:Dictionary = new Dictionary();

[Bindable] private var maxReadVal:Number = 500;
[Bindable] private var minReadVal:Number = 500;

private var running:Boolean = false;
private var countingUp:Boolean = true;
private var husLevel:uint = 0;
private var changeTimer:Timer;
private var progressTimer:Timer;
private var changeInterval:uint = 5000;
private var afterBoilDownInterval:uint;

protected function initApp(event:FlexEvent):void {
	this.stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
	swfHP.Temp.tOut.tempOutText.text = "0";
	swfHP.Temp.tHus.tempHusText.text = "0";
	swfHP.mv_default.visible = true;
	swfHP.mv_red.visible = false;
	swfHP.mv_blue.visible = false;
	changeTimer = new Timer(5000,1);
	changeTimer.addEventListener(TimerEvent.TIMER, changeMovieOnTimer);
	progressTimer = new Timer(1000,0);
	progressTimer.addEventListener(TimerEvent.TIMER, progressHeatPumpOnTimer);
}

// When Start or Stop is clicked, set up the state to begin heating up or cooling down
private function clickStartStop(event:MouseEvent):void {
	if(!running) {
		running=true;
		countingUp = true;
		swfHP.Temp.tOut.tempOutText.text = "10";
		swfHP.Temp.tOut.y = 75 - TARGET_SOURCE_TEMP*PIXEL_INCREMENT;
		videoPlayer.source="assets/vids/boiling_up_v001.mov";
		videoPlayer2.source = "assets/vids/boiling_loop_v001.mov"
		videoPlayer.play();
		startStopButton.label = "Stop";
		swfHP.mv_default.visible = false;
		swfHP.mv_red.visible = true;
		swfHP.mv_blue.visible = false;
		progressTimer.reset();
		progressTimer.start();
		changeTimer.start();
	}
	else {
		swfHP.Temp.tOut.tempOutText.text = "0";
		swfHP.Temp.tOut.y = 75;
		countingUp = false;
		startStopButton.enabled = false;
		videoPlayer.source="assets/vids/boiling_down_v001.mov";
		videoPlayer.visible=true;
		videoPlayer.play();
		videoPlayer2.stop();
		videoPlayer2.visible=false;
		afterBoilDownInterval = setInterval(afterBoilDown, 2000);
	}
}

// After allowing enough time for the boil down movie to play, reset the states ready to start over again
private function afterBoilDown():void {
	clearInterval(afterBoilDownInterval);
	startStopButton.enabled = true;
	swfHP.mv_default.visible = true;
	swfHP.mv_red.visible = false;
	swfHP.mv_blue.visible = false;
	startStopButton.label = "Start";
	startStopButton.enabled = true;
	running = false;
}

protected function changeMovieOnTimer(event:TimerEvent):void {
	changeMovie();
}
protected function progressHeatPumpOnTimer(event:TimerEvent):void {
	progressHeatPump();
}

// Update the animation to show the new temperature inside, and move the tag
protected function progressHeatPump():void {
	if(timeCounter < TARGET_HOUSE_TEMP && countingUp) {
		timeCounter+=1;
		swfHP.Temp.tHus.y = 75 - timeCounter*PIXEL_INCREMENT;
		swfHP.Temp.tHus.tempHusText.text = String(timeCounter);
	}
	else if(timeCounter > 0 && !countingUp) {
		timeCounter-=1;
		swfHP.Temp.tHus.y = 75 - timeCounter*PIXEL_INCREMENT;
		swfHP.Temp.tHus.tempHusText.text = String(timeCounter);
	}
}

// At present, switches from the boil up movie to the loop movie
protected function changeMovie():void {
	changeTimer.reset();
	if(videoPlayer.visible) {
		videoPlayer2.visible=true;
		videoPlayer2.play();
		videoPlayer.stop();
		videoPlayer.visible=false;
	}
	else {
		videoPlayer.visible=true;
		videoPlayer.play();
		videoPlayer2.stop();
		videoPlayer2.visible=false;
	}
}