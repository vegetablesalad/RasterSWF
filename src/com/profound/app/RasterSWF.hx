package com.profound.app;

/*

	Code by Valts
	vdarznieks@gmail.com
	#haxe - vegetablesalad

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import haxe.io.Bytes;
import sys.io.FileInput;
import sys.io.FileOutput;
import com.profound.app.encoder.PNGEncoder;
import nme.display.Bitmap;
import nme.display.BitmapData;
import neash.display.DisplayObject;
import format.SWF;
import format.display.MovieClip;
import nme.display.Sprite;
import nme.Lib;
import sys.FileSystem;
import sys.io.File;
import nme.utils.ByteArray;

class RasterSWF extends Sprite {

	var outputDirectory:String;

	public function new () {
        super ();

		// Get all arguments [0] - path to *.swf , [1] - output dir
		var _args:Array<String> = Sys.args();
		var _libPath:String = (_args[0]!=null)?_args[0]:"library.swf";
		outputDirectory = (_args[1]!=null)?_args[1]:"rasterizedLibrary";

		// Create output dir
		createDir(outputDirectory);

		//Read swf and iterate all clips
		var _library = new SWF (readSwfBytes(_libPath));
		var _xmlDoc:Xml = Xml.createElement('lib');
		for ( key in _library.symbols.keys() ) {
			_xmlDoc.addChild(parseClip(_library.createMovieClip(key),key));
		}

		//Write xml data to file
		var _file = File.write(outputDirectory + "/library.xml", false);
		_file.writeString(Std.string(_xmlDoc));
		_file.close();

		Lib.close();
	}

	//Recursive function for parsing and rasterizing all clips
	private function parseClip(_clip:MovieClip /*clip*/,_forceName:String="" /*used only for first level*/,_prefix:String=""):Xml{

		var _clipName:String = (_forceName != "")?_forceName:_clip.name;

		//Set xml data for MovieClips
		var _xmlData:Xml = Xml.createElement('MovieClip');
		_xmlData.set("type",formatType(Std.string(Type.typeof(_clip))));
		_xmlData.set("name",_clipName);
		//Set all common data
		_xmlData = setXmlData(_xmlData,_clip);

		//Iterate all children, repeat function if MovieClip or finalize if Graphic
		for (i in 0 ... _clip.numChildren){
			var _child = _clip.getChildAt(i);
			if(isMovieClip(Std.string(Type.typeof(_child)))){
				_xmlData.addChild(parseClip(cast(_child,MovieClip),"",_clipName));
			}else{
				//Get current DisplayObject
				var _dO = cast(_child,DisplayObject);
				_dO.cacheAsBitmap = true;

				//Draw DisplayObject to BitmapData
				var _bD:BitmapData = new BitmapData( Std.int( _dO.width ) , Std.int( _dO.height ) , true ,0x00000000);
				_bD.draw(_dO);

				//Set xml data for DisplayObject
				var _xmlDisplayObject:Xml = Xml.createElement('DisplayObject');
				_xmlDisplayObject.set("type", "DisplayObject");
				//Set all common data
				_xmlDisplayObject = setXmlData(_xmlDisplayObject,_dO);

				//Generate file name for new bitmap
				var _fileName:String = ((_prefix=="")?"":_prefix+"_") + _clipName + "_" + Std.string(i);

				//Set filename to xml and write the file
				_xmlDisplayObject.set("bitmap", _fileName+".png");
				writeBitmapToFile(_bD,outputDirectory+"/"+_fileName);
				_xmlData.addChild(_xmlDisplayObject);
			}
		}
		return(_xmlData);
	}

	private function readSwfBytes(_path:String):ByteArray{
		var _swf:FileInput = File.read(_path, true);
		var _b:Bytes =_swf.readAll();
		_swf.close();
		var _bArray:nme.utils.ByteArray = new nme.utils.ByteArray();
		for(i in 0..._b.length){
			_bArray.writeByte(_b.get(i));
		}
		return _bArray;
	}

	private function writeBitmapToFile(_bitmapData:BitmapData,_file:String):Void{
		var _bArray:ByteArray =  PNGEncoder.encode(_bitmapData);
		var _fName = _file+".png";
		var _fOut:FileOutput = File.write(_fName, true);
		_fOut.writeBytes(_bArray,0,_bArray.length);
		_fOut.close();
	}

	private function setXmlData(_val:Xml,_clip:Dynamic):Xml{
		_val.set("x", Std.string(Math.round(_clip.x)));
		_val.set("y", Std.string(Math.round(_clip.y)));
		_val.set("width", Std.string(Math.round(_clip.width)));
		_val.set("height", Std.string(Math.round(_clip.height)));
		_val.set("alpha", Std.string(roundTo2(_clip.alpha)));
		return _val;
	}

	private function isMovieClip(_val:String):Bool{
		if(_val.indexOf("MovieClip") >= 0)
			return true;
		return false;
	}

	private function formatType(_val:String):String{
		if(_val.indexOf("MovieClip") >= 0)
			return "MovieClip";
		return _val;
	}

	private function roundTo2(_val:Dynamic):Dynamic{
		return Math.round(_val*100)/100;
	}

	private function createDir(_val:String):Bool{
		if( !sys.FileSystem.exists(_val) ){
			sys.FileSystem.createDirectory(_val);
			if( sys.FileSystem.exists(_val) && sys.FileSystem.isDirectory(_val)){
				return true;
			}else{
				trace("Could not create directory.");
				return false;
			}
		}else{
			trace("Directory already exists, rewritig files.. ");
			return false;
		}
	}
}
